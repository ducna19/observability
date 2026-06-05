# SigNoz + ClickHouse Full Flow

This POC flow is designed to exercise the main SigNoz + ClickHouse capabilities:

- APM service overview
- HTTP endpoint latency, rate, and status codes
- Distributed traces with child spans
- Error traces and exception events
- JSON application logs with trace IDs
- Database-like spans for inventory lookup
- External HTTP client spans for payment gateway calls
- Messaging producer spans for order notification
- Custom Prometheus metrics on `/metrics`

## 1. Keep Port-Forwards Open

```bash
make pf-app
make pf-signoz
```

Open SigNoz:

```text
http://127.0.0.1:8080
```

## 2. Generate Full-Flow Load

```bash
make load
```

Useful overrides:

```bash
make load DURATION_SECONDS=600 SLEEP_SECONDS=0.1
make load MODE=legacy
```

## 3. Manual Scenarios

```bash
curl 'http://127.0.0.1:18080/checkout?scenario=success'
curl 'http://127.0.0.1:18080/checkout?scenario=slow'
curl 'http://127.0.0.1:18080/checkout?scenario=payment_error'
curl 'http://127.0.0.1:18080/checkout?scenario=inventory_error'
curl 'http://127.0.0.1:18080/checkout?scenario=exception'
```

## 4. Import Dashboards

Import these JSON files in SigNoz:

```text
90-benchmark/signoz-dashboard-pack/01-http-api-monitoring.json
90-benchmark/signoz-dashboard-pack/02-key-operations.json
90-benchmark/signoz-dashboard-pack/03-db-calls-monitoring.json
```

Use these variables:

```text
service.name = sample-api
deployment.environment = poc
```

## 5. What To Look For

In Services:

- `sample-api` latency, request rate, and error rate
- Operations such as `GET /checkout`

In Traces:

- `checkout.process_order`
- `cart.validate`
- `inventory.lookup`
- `pricing.calculate`
- `payment.authorize`
- `notification.publish`

In Logs:

- `checkout completed`
- `payment declined`
- `inventory lookup miss`
- `checkout exception`

In ClickHouse-backed dashboards:

- HTTP endpoint p90 latency
- status code distribution: `200`, `402`, `409`, `500`
- DB call tables for SQLite-style inventory spans
- key operations sorted by p99/error/rate
