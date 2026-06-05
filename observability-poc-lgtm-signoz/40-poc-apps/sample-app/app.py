import json
import logging
import os
import random
import sqlite3
import threading
import time
from datetime import datetime, timezone

from flask import Flask, Response, jsonify, request
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import requests

from opentelemetry import trace
from opentelemetry.trace import SpanKind, Status, StatusCode


app = Flask(__name__)
SERVICE_NAME = os.getenv("OTEL_SERVICE_NAME", "sample-api")
PAYMENT_GATEWAY_URL = os.getenv("PAYMENT_GATEWAY_URL", "https://httpbin.org/status/200")
PAYMENT_TIMEOUT_SECONDS = float(os.getenv("PAYMENT_TIMEOUT_SECONDS", "2"))

REQ_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["service", "method", "route", "status"],
)

REQ_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency",
    ["service", "method", "route", "status"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10),
)

CHECKOUT_COUNT = Counter(
    "checkout_requests_total",
    "Checkout requests by outcome",
    ["service", "outcome", "scenario"],
)

CHECKOUT_LATENCY = Histogram(
    "checkout_duration_seconds",
    "Checkout end-to-end latency",
    ["service", "outcome", "scenario"],
    buckets=(0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10),
)

PAYMENT_COUNT = Counter(
    "payment_attempts_total",
    "Payment gateway attempts by outcome",
    ["service", "outcome"],
)

INVENTORY_READS = Counter(
    "inventory_reads_total",
    "Inventory DB reads",
    ["service", "item"],
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(SERVICE_NAME)
tracer = trace.get_tracer(__name__)
db_lock = threading.Lock()
db = sqlite3.connect(":memory:", check_same_thread=False)


def init_db():
    with db_lock:
        db.execute(
            """
            CREATE TABLE IF NOT EXISTS inventory (
              item_id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              stock INTEGER NOT NULL,
              unit_price REAL NOT NULL
            )
            """
        )
        db.executemany(
            """
            INSERT OR REPLACE INTO inventory(item_id, name, stock, unit_price)
            VALUES (?, ?, ?, ?)
            """,
            [
                ("obs-book", "Observability Field Guide", 42, 39.5),
                ("latency-mug", "Latency Budget Mug", 24, 12.0),
                ("trace-hoodie", "Distributed Trace Hoodie", 8, 59.0),
            ],
        )
        db.commit()


def current_trace_ids():
    span = trace.get_current_span()
    ctx = span.get_span_context()
    if not ctx or not ctx.is_valid:
        return "-", "-"
    return format(ctx.trace_id, "032x"), format(ctx.span_id, "016x")


def log_json(level, message, **fields):
    trace_id, span_id = current_trace_ids()
    payload = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "level": level,
        "service": SERVICE_NAME,
        "message": message,
        "trace_id": trace_id,
        "span_id": span_id,
        "env": os.getenv("DEPLOYMENT_ENV", "poc"),
        "team": os.getenv("TEAM", "devops"),
        "owner": os.getenv("OWNER", "devops-platform"),
    }
    payload.update(fields)
    getattr(logger, level.lower(), logger.info)(json.dumps(payload))


def choose_scenario(raw_scenario):
    if raw_scenario and raw_scenario != "random":
        return raw_scenario
    roll = random.random()
    if roll < 0.08:
        return "payment_error"
    if roll < 0.14:
        return "inventory_error"
    if roll < 0.20:
        return "exception"
    if roll < 0.42:
        return "slow"
    return "success"


def get_inventory(item_id, scenario):
    with tracer.start_as_current_span("inventory.lookup", kind=SpanKind.CLIENT) as span:
        span.set_attribute("db.system", "sqlite")
        span.set_attribute("db.name", "poc_checkout")
        span.set_attribute("db.operation", "SELECT")
        span.set_attribute(
            "db.statement",
            "SELECT item_id, name, stock, unit_price FROM inventory WHERE item_id = ?",
        )
        span.set_attribute("app.item_id", item_id)
        if scenario == "inventory_error":
            item_id = "missing-item"
            span.set_attribute("app.forced_inventory_miss", True)

        with db_lock:
            row = db.execute(
                "SELECT item_id, name, stock, unit_price FROM inventory WHERE item_id = ?",
                (item_id,),
            ).fetchone()

        INVENTORY_READS.labels(SERVICE_NAME, item_id).inc()
        if row is None:
            span.set_status(Status(StatusCode.ERROR, "item not found"))
            log_json("WARNING", "inventory lookup miss", item_id=item_id)
            return None

        inventory = {
            "item_id": row[0],
            "name": row[1],
            "stock": row[2],
            "unit_price": row[3],
        }
        span.set_attribute("app.stock", inventory["stock"])
        log_json("INFO", "inventory lookup completed", item_id=item_id, stock=inventory["stock"])
        return inventory


def validate_cart(item_id, quantity, scenario):
    with tracer.start_as_current_span("cart.validate") as span:
        span.set_attribute("app.item_id", item_id)
        span.set_attribute("app.quantity", quantity)
        if quantity <= 0:
            span.set_status(Status(StatusCode.ERROR, "invalid quantity"))
            raise ValueError("quantity must be positive")
        if scenario == "slow":
            delay = random.uniform(0.25, 0.75)
            span.set_attribute("app.validation_delay_seconds", delay)
            time.sleep(delay)
        log_json("INFO", "cart validated", item_id=item_id, quantity=quantity)


def price_order(inventory, quantity, scenario):
    with tracer.start_as_current_span("pricing.calculate") as span:
        subtotal = inventory["unit_price"] * quantity
        discount = 0.1 if quantity >= 3 else 0
        if scenario == "slow":
            time.sleep(random.uniform(0.15, 0.45))
        total = round(subtotal * (1 - discount), 2)
        span.set_attribute("app.subtotal", subtotal)
        span.set_attribute("app.discount", discount)
        span.set_attribute("app.total", total)
        return total


def authorize_payment(total, scenario):
    with tracer.start_as_current_span("payment.authorize", kind=SpanKind.CLIENT) as span:
        span.set_attribute("peer.service", "payment-gateway")
        span.set_attribute("http.method", "GET")
        span.set_attribute("http.url", PAYMENT_GATEWAY_URL)
        span.set_attribute("app.payment.amount", total)

        if scenario == "payment_error":
            PAYMENT_COUNT.labels(SERVICE_NAME, "declined").inc()
            span.set_status(Status(StatusCode.ERROR, "payment declined"))
            log_json("ERROR", "payment declined", amount=total, gateway="payment-gateway")
            return False

        try:
            response = requests.get(PAYMENT_GATEWAY_URL, timeout=PAYMENT_TIMEOUT_SECONDS)
            span.set_attribute("http.status_code", response.status_code)
            response.raise_for_status()
        except requests.RequestException as exc:
            span.record_exception(exc)
            span.set_attribute("app.payment.degraded", True)
            log_json("WARNING", "payment gateway call degraded", error=str(exc))
            if scenario in ("success", "slow"):
                PAYMENT_COUNT.labels(SERVICE_NAME, "authorized_degraded").inc()
                return True
            PAYMENT_COUNT.labels(SERVICE_NAME, "gateway_error").inc()
            span.set_status(Status(StatusCode.ERROR, "payment gateway error"))
            return False

        PAYMENT_COUNT.labels(SERVICE_NAME, "authorized").inc()
        log_json("INFO", "payment authorized", amount=total)
        return True


def publish_notification(order_id, scenario):
    with tracer.start_as_current_span("notification.publish", kind=SpanKind.PRODUCER) as span:
        span.set_attribute("messaging.system", "in-memory")
        span.set_attribute("messaging.destination.name", "order-events")
        span.set_attribute("messaging.operation", "publish")
        span.set_attribute("app.order_id", order_id)
        if scenario == "slow":
            time.sleep(random.uniform(0.1, 0.35))
        log_json("INFO", "order event published", order_id=order_id, topic="order-events")


@app.before_request
def start_timer():
    request.start_time = time.time()


@app.after_request
def record_metrics(response):
    route = request.path
    status = str(response.status_code)
    duration = time.time() - getattr(request, "start_time", time.time())
    REQ_COUNT.labels(SERVICE_NAME, request.method, route, status).inc()
    REQ_LATENCY.labels(SERVICE_NAME, request.method, route, status).observe(duration)
    return response


@app.route("/")
def index():
    with tracer.start_as_current_span("sample.index"):
        log_json("INFO", "normal request", route="/")
        return jsonify(
            service=SERVICE_NAME,
            status="ok",
            message="hello from observability sample app",
            demo_endpoints=[
                "/checkout?scenario=random",
                "/checkout?scenario=success",
                "/checkout?scenario=slow",
                "/checkout?scenario=payment_error",
                "/checkout?scenario=inventory_error",
                "/checkout?scenario=exception",
            ],
        )


@app.route("/healthz")
def healthz():
    return jsonify(status="ok")


@app.route("/work")
def work():
    with tracer.start_as_current_span("sample.work") as span:
        n = random.randint(10000, 50000)
        total = 0
        for i in range(n):
            total += i * i
        span.set_attribute("work.iterations", n)
        log_json("INFO", "work completed", iterations=n)
        return jsonify(status="ok", iterations=n, result=total % 99991)


@app.route("/slow")
def slow():
    with tracer.start_as_current_span("sample.slow") as span:
        delay = random.uniform(1.0, 3.0)
        span.set_attribute("delay.seconds", delay)
        time.sleep(delay)
        log_json("WARNING", "slow response simulated", delay_seconds=delay)
        return jsonify(status="slow", delay_seconds=delay)


@app.route("/error")
def error():
    with tracer.start_as_current_span("sample.error") as span:
        span.set_status(Status(StatusCode.ERROR, "simulated error"))
        span.set_attribute("error.type", "simulated")
        log_json("ERROR", "simulated application error", error_code="POC_ERROR_500")
        return jsonify(status="error", error="simulated error"), 500


@app.route("/checkout", methods=["GET", "POST"])
def checkout():
    started = time.time()
    raw_scenario = request.args.get("scenario", "random")
    scenario = choose_scenario(raw_scenario)
    item_id = request.args.get("item", random.choice(["obs-book", "latency-mug", "trace-hoodie"]))
    quantity = int(request.args.get("quantity", random.randint(1, 4)))
    order_id = f"ord-{int(time.time() * 1000)}-{random.randint(1000, 9999)}"
    outcome = "unknown"

    with tracer.start_as_current_span("checkout.process_order") as span:
        span.set_attribute("app.scenario", scenario)
        span.set_attribute("app.order_id", order_id)
        span.set_attribute("app.item_id", item_id)
        span.set_attribute("app.quantity", quantity)

        try:
            if scenario == "exception":
                raise RuntimeError("simulated checkout exception")

            validate_cart(item_id, quantity, scenario)
            inventory = get_inventory(item_id, scenario)
            if inventory is None:
                outcome = "inventory_error"
                span.set_status(Status(StatusCode.ERROR, "inventory unavailable"))
                return jsonify(status="error", order_id=order_id, error="inventory unavailable"), 409

            if inventory["stock"] < quantity:
                outcome = "inventory_error"
                span.set_status(Status(StatusCode.ERROR, "insufficient stock"))
                return jsonify(status="error", order_id=order_id, error="insufficient stock"), 409

            total = price_order(inventory, quantity, scenario)
            if not authorize_payment(total, scenario):
                outcome = "payment_error"
                span.set_status(Status(StatusCode.ERROR, "payment failed"))
                return jsonify(status="error", order_id=order_id, error="payment failed"), 402

            publish_notification(order_id, scenario)
            outcome = "success"
            log_json(
                "INFO",
                "checkout completed",
                order_id=order_id,
                item_id=item_id,
                quantity=quantity,
                total=total,
                scenario=scenario,
            )
            return jsonify(
                status="ok",
                order_id=order_id,
                item=inventory["item_id"],
                quantity=quantity,
                total=total,
                scenario=scenario,
            )
        except Exception as exc:
            outcome = "exception"
            span.record_exception(exc)
            span.set_status(Status(StatusCode.ERROR, str(exc)))
            log_json("ERROR", "checkout exception", order_id=order_id, error=str(exc), scenario=scenario)
            return jsonify(status="error", order_id=order_id, error=str(exc)), 500
        finally:
            duration = time.time() - started
            CHECKOUT_COUNT.labels(SERVICE_NAME, outcome, scenario).inc()
            CHECKOUT_LATENCY.labels(SERVICE_NAME, outcome, scenario).observe(duration)
            span.set_attribute("app.outcome", outcome)
            span.set_attribute("app.duration_seconds", duration)


@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


init_db()

if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
