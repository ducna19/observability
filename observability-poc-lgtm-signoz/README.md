# Production Observability: Grafana LGTM Stack

Repo này hiện chuyển trọng tâm sang production baseline cho stack LGTM:

- Grafana
- Mimir
- Loki
- Tempo
- Alloy
- Prometheus / kube-prometheus-stack
- Alertmanager

Các phần POC local và SigNoz trước đây vẫn còn để tham khảo, nhưng đường triển khai production mới nằm ở:

```text
production/lgtm/
```

## Kiến Trúc Production

```text
Applications
  -> OTLP gRPC/HTTP
  -> Alloy Gateway
  -> Mimir / Loki / Tempo
  -> Grafana

Kubernetes pod logs
  -> Alloy Agent DaemonSet
  -> Loki

Kubernetes metrics
  -> Prometheus
  -> remote_write
  -> Mimir
```

## Thư Mục Chính

```text
production/lgtm/README.md                 Production runbook
production/lgtm/values/                   Helm values production
production/lgtm/secrets/                  Secret templates
production/lgtm/scripts/                  Render/install/status scripts
production/lgtm/namespaces.yaml           Production namespaces
```

## Render Production Manifests

```bash
make prod-render
```

Output:

```text
.rendered/lgtm-production/
```

## Install Production LGTM

Trước khi install, thay toàn bộ placeholder:

```bash
grep -R "REPLACE_ME" production/lgtm
```

Sau đó tạo secrets thật qua secret manager hoặc apply secret đã được render an toàn.

Cài stack:

```bash
make prod-lgtm
```

Kiểm tra:

```bash
make prod-status
```

## OTLP Endpoint Cho Application

OTLP HTTP:

```text
http://alloy-gateway.observability.svc.cluster.local:4318
```

OTLP gRPC:

```text
alloy-gateway.observability.svc.cluster.local:4317
```

Resource attributes nên chuẩn hóa:

```text
service.name
service.namespace
service.version
deployment.environment=production
k8s.cluster.name
team.name
owner
criticality
```

## Clear POC Cũ

Nếu muốn xóa stack local POC đã dựng trước đó:

```bash
make uninstall
kubectl delete ns obs-lgtm obs-signoz obs-router poc-apps
```

Kiểm tra PVC/PV trước khi xóa dữ liệu:

```bash
kubectl get pvc -A | grep -E 'obs-lgtm|obs-signoz|obs-router|poc-apps'
kubectl get pv
```

Production baseline dùng namespace mới:

```text
observability
observability-agents
```

## Ghi Chú

Values production trong repo là baseline để review/GitOps. Trước khi dùng thật cần chỉnh:

- S3/object storage buckets
- domain/Ingress/TLS
- Grafana OIDC/SSO
- storage class
- resource sizing theo traffic thực tế
- retention theo yêu cầu compliance
- alert routing theo team/severity
