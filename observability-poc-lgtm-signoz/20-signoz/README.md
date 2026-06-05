# SigNoz + ClickHouse POC

## Install

```bash
./scripts/20-install-signoz.sh
```

## Port-forward

```bash
./scripts/81-port-forward-signoz.sh
```

## Health check

```bash
curl http://localhost:8080/api/v1/health
```

## OTLP endpoints thường gặp

Các service name có thể khác theo chart version. Kiểm tra bằng:

```bash
kubectl -n obs-signoz get svc
```

Thường dùng:

```text
signoz-otel-collector.obs-signoz.svc.cluster.local:4317
http://signoz-otel-collector.obs-signoz.svc.cluster.local:4318
```

Nếu tên service khác, sửa file:

```text
30-router/otel-router-values-lite.yaml
30-router/otel-router-values-with-mimir.yaml
40-poc-apps/k8s/deployment.yaml
```
