# Troubleshooting

## Kiểm tra pod

```bash
./scripts/50-status.sh
```

## Loki install fail vì deploymentMode

Thử file alternative:

```bash
helm upgrade --install loki grafana/loki \
  --namespace obs-lgtm \
  -f 10-lgtm/loki-values-monolithic-alt.yaml
```

## Grafana không thấy datasource

```bash
kubectl -n obs-lgtm get cm | grep datasource
kubectl -n obs-lgtm logs deploy/kps-grafana -c grafana-sc-datasources
kubectl -n obs-lgtm rollout restart deploy/kps-grafana
```

## Tempo không thấy trace

```bash
kubectl -n obs-router logs deploy/otel-poc-router-opentelemetry-collector
kubectl -n obs-lgtm logs deploy/tempo
```

## SigNoz service name khác

```bash
kubectl -n obs-signoz get svc
```

Sửa endpoint trong:

```text
30-router/otel-router-values-lite.yaml
30-router/otel-router-values-with-mimir.yaml
40-poc-apps/k8s/deployment.yaml
```

## Sample image không pull được

Nếu dùng kind:

```bash
./scripts/40-build-sample-kind.sh
```

Nếu dùng minikube:

```bash
./scripts/40-build-sample-minikube.sh
```

Hoặc push image vào registry nội bộ và sửa:

```text
40-poc-apps/k8s/deployment.yaml
```
