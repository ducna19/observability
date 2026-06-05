FROM python:3.11-slim

WORKDIR /app

ENV PYTHONUNBUFFERED=1
ENV OTEL_PYTHON_LOG_CORRELATION=true
ENV OTEL_TRACES_EXPORTER=otlp
ENV OTEL_METRICS_EXPORTER=otlp
ENV OTEL_LOGS_EXPORTER=otlp
ENV OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 8080

CMD ["opentelemetry-instrument", "gunicorn", "-b", "0.0.0.0:8080", "app:app"]
