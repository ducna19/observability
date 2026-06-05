# LGTM Grafana Production Baseline

Thư mục này đã được tách riêng khỏi POC cũ để bạn học và chuẩn hóa stack LGTM theo hướng production.

Stack gồm:

- Grafana
- Mimir
- Loki
- Tempo
- Alloy Gateway
- Alloy Agent DaemonSet
- Prometheus / kube-prometheus-stack
- Alertmanager

## Mục Tiêu

Mục tiêu không phải deploy thẳng vào production công ty ngay. Mục tiêu hiện tại là:

- Có một baseline production rõ ràng.
- Render được manifest để đọc, review, hiểu từng component.
- Có default sandbox để học mà không cần quyền production.
- Sau này chỉ thay secret/domain/storage/cluster overlay là dùng được cho môi trường thật.

## Kiến Trúc

```text
Applications
  -> OTLP HTTP/gRPC
  -> Alloy Gateway
  -> Mimir / Loki / Tempo
  -> Grafana

Kubernetes metrics
  -> Prometheus
  -> remote_write
  -> Mimir

Kubernetes pod logs
  -> Alloy Agent DaemonSet
  -> Loki

Alerts
  -> PrometheusRule
  -> Alertmanager
  -> Receiver: Slack/PagerDuty/Email/etc.
```

## Default Sandbox Đã Tự Sinh

Các placeholder production đã được thay bằng giá trị học tập:

```text
cluster: learning-lab
Grafana URL: https://grafana.grafana.local
env: production
tenant: production
S3 endpoint: lgtm-minio.observability.svc.cluster.local:9000
region: local-1
Grafana admin password: admin-learning-lab-change-me
```

Các giá trị này giúp bạn render/review mà không cần quyền công ty. Không dùng các secret demo này cho production thật.

## Cấu Trúc

```text
values/
  kps-production-values.yaml
  mimir-production-values.yaml
  loki-production-values.yaml
  tempo-production-values.yaml
  alloy-gateway-values.yaml
  alloy-agent-values.yaml

secrets/
  object-storage.example.yaml
  grafana-admin.example.yaml
  grafana-oauth.example.yaml

scripts/
  render-lgtm-production.sh
  bootstrap-sandbox-secrets.sh
  install-lgtm-production.sh
  status-lgtm-production.sh
```

## Bước 1: Render Để Học Trước

Render manifest:

```bash
cd /home/ducna/Documents/Observability/lgtm-grafana-production
make render
```

Output:

```text
.rendered/
  mimir.yaml
  loki.yaml
  tempo.yaml
  kps.yaml
  alloy-gateway.yaml
  alloy-agent.yaml
```

Đây là bước quan trọng nhất để học. Bạn mở từng file và xem Kubernetes sẽ tạo gì:

```text
Deployment
StatefulSet
Service
ConfigMap
PVC
ServiceMonitor
PodMonitor
RBAC
```

## Chạy Multi-Node Trên Máy Local

Nếu muốn demo stack LGTM trên nhiều Kubernetes node bằng Kind:

```bash
cd /home/ducna/Documents/Observability/lgtm-grafana-production
make kind-multinode
make install-kind-multinode
make test-kind-multinode
```

Mở Grafana:

```bash
make pf-grafana
```

Chi tiết kiến trúc, lý do scale từng component và cách demo nằm trong:

```text
MULTINODE_RUNBOOK.md
```

## Bước 2: Hiểu Từng Thành Phần

### Mimir

Lưu metrics dài hạn.

Prometheus chỉ giữ local ngắn hạn rồi đẩy metrics sang Mimir qua `remote_write`.

### Loki

Lưu logs.

Alloy Agent đọc pod logs trên từng node và gửi về Loki.

### Tempo

Lưu traces.

Application gửi OTLP traces về Alloy Gateway, Alloy forward sang Tempo.

### Grafana

UI để xem:

```text
Metrics: Mimir
Logs: Loki
Traces: Tempo
Dashboards
Alert UX
Explore
```

### Alloy Gateway

Endpoint trung tâm cho application gửi telemetry:

```text
OTLP HTTP: http://alloy-gateway.observability.svc.cluster.local:4318
OTLP gRPC: alloy-gateway.observability.svc.cluster.local:4317
```

### Alloy Agent

DaemonSet chạy trên node để gom Kubernetes pod logs.

## Bước 3: Bootstrap Secret Sandbox

Nếu chỉ muốn thử trên cluster học tập:

```bash
make bootstrap-secrets
```

Lệnh này tạo:

```text
namespace/observability
namespace/observability-agents
secret/lgtm-object-storage
secret/grafana-admin
secret/grafana-oauth
```

Lưu ý: package này tự triển khai MinIO sandbox nội bộ tại `lgtm-minio.observability.svc.cluster.local:9000`, rồi tạo bucket cho Mimir/Loki/Tempo. Khi có môi trường công ty, thay MinIO này bằng S3/object storage thật.

## Bước 4: Install Khi Đã Có Object Storage

Khi bạn có S3 hoặc MinIO sandbox, chạy:

```bash
make install
```

Kiểm tra:

```bash
make status
```

## Bước 5: App Gửi Telemetry Như Thế Nào

Application cần cấu hình:

```text
OTEL_EXPORTER_OTLP_ENDPOINT=http://alloy-gateway.observability.svc.cluster.local:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
OTEL_SERVICE_NAME=my-service
OTEL_RESOURCE_ATTRIBUTES=deployment.environment=production,k8s.cluster.name=learning-lab,team.name=my-team,owner=my-owner
```

## Khi Có Quyền Production Công Ty

Bạn thay các nhóm cấu hình này:

```text
cluster name
domain Grafana
S3 endpoint/region/buckets
secret thật
Grafana OIDC
storage class
resource sizing
retention
alert routing
Ingress/TLS
```

Kiểm tra placeholder còn sót:

```bash
make placeholders
```

## Không Đụng POC Cũ

Thư mục này độc lập với:

```text
observability-poc-lgtm-signoz/
```

Bạn có thể học production baseline ở đây mà không ảnh hưởng sample app, SigNoz POC, dashboard JSON cũ.
