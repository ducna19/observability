# Observability POC README — LGTM Hybrid vs SigNoz + ClickHouse

README này dùng để đưa thẳng vào Codex/VS Code để build, kiểm tra và sửa lỗi repo POC Observability local.

## 1. Mục tiêu

Repo này dựng POC nhỏ cho 2 stack:

### Stack A — LGTM Hybrid
- Grafana: dashboard, Explore, alert UI
- Prometheus / kube-prometheus-stack: metrics scrape, PrometheusRule
- Alertmanager: alert routing
- Loki: logs
- Tempo: traces
- Alloy: collection layer
- Mimir: optional, central metrics long-term storage

### Stack B — SigNoz + ClickHouse
- SigNoz UI / Query Service
- SigNoz OpenTelemetry Collector
- ClickHouse
- Zookeeper / Keeper tùy chart version

Mục tiêu POC:
- Kiểm tra metrics, logs, traces.
- Kiểm tra correlation giữa metrics, logs, traces.
- So sánh Grafana/LGTM với SigNoz APM.
- Đo CPU, RAM, storage, query latency.
- Đánh giá stack nào dễ vận hành hơn cho DevOps/SRE.

---

## 2. Kiến trúc tổng thể

```text
                         +----------------------+
                         |    Sample App/API    |
                         |  FastAPI + OTel SDK  |
                         +----------+-----------+
                                    |
                                    | OTLP / logs / metrics / traces
                                    v
                     +--------------+---------------+
                     |    OpenTelemetry / Alloy      |
                     | collect / enrich / route      |
                     +----------+-----------+--------+
                                |           |
                                |           |
                                v           v
                 +--------------+--+     +--+------------------+
                 |   LGTM Hybrid   |     | SigNoz + ClickHouse |
                 | Grafana         |     | SigNoz UI           |
                 | Prometheus      |     | SigNoz Collector    |
                 | Loki            |     | ClickHouse          |
                 | Tempo           |     | Zookeeper/Keeper    |
                 | Alloy           |     |                     |
                 +-----------------+     +---------------------+
```

Trong POC nhỏ, có thể chạy 2 stack song song. Khi cần benchmark công bằng hơn, dùng `OpenTelemetry Collector Router` để app gửi về một endpoint rồi router forward sang cả LGTM và SigNoz.

---

## 3. Yêu cầu local

Máy local cần có:

```text
docker
kind
kubectl
helm
make
curl
git
```

Khuyến nghị tài nguyên nếu chạy cả 2 stack cùng lúc:

```text
CPU:     12–16 vCPU
RAM:     24–32 GB
Storage: 300–500 GB
```

Nếu laptop yếu, chạy từng stack một:

```bash
make lgtm-lite
make app
make load

make uninstall-lgtm

make signoz
make app
make load
```

---

## 4. Namespace

```text
obs-lgtm      # Grafana, Prometheus, Loki, Tempo, Alloy, Mimir optional
obs-signoz    # SigNoz, ClickHouse, SigNoz Collector
obs-router    # OpenTelemetry Collector Router optional
poc-apps      # Sample app
```

Tạo namespace:

```bash
make ns
```

Hoặc:

```bash
kubectl apply -f 00-namespaces/namespaces.yaml
```

---

## 5. Biến cấu hình quan trọng

Nên thêm các biến này vào đầu `Makefile`:

```makefile
KIND_CLUSTER_NAME ?= observability-poc
SAMPLE_IMAGE ?= observability-sample-api
SAMPLE_TAG ?= 0.1.0
SAMPLE_FULL_IMAGE ?= $(SAMPLE_IMAGE):$(SAMPLE_TAG)
```

Không hard-code cluster name là `kind`, vì cluster local hiện tại có thể tên khác.

Kiểm tra tên cluster:

```bash
kind get clusters
```

Ví dụ output:

```text
observability-poc
```

---

## 6. Bug đã gặp: `make build-kind` load image sai cluster

### Triệu chứng

```text
Loading image into kind cluster: kind
ERROR: no nodes found for cluster "kind"
```

### Nguyên nhân

Script đang hard-code cluster name `kind`, trong khi cluster thực tế là:

```text
observability-poc
```

### Fix nhanh

```bash
kind load docker-image observability-sample-api:0.1.0 --name observability-poc
make app
```

### Fix đúng trong repo

Sửa file:

```text
scripts/40-build-sample-kind.sh
```

Nội dung đề xuất:

```bash
#!/usr/bin/env bash
set -euo pipefail

KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-observability-poc}"
SAMPLE_IMAGE="${SAMPLE_IMAGE:-observability-sample-api}"
SAMPLE_TAG="${SAMPLE_TAG:-0.1.0}"
SAMPLE_FULL_IMAGE="${SAMPLE_IMAGE}:${SAMPLE_TAG}"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker command not found."
  exit 1
fi

if ! command -v kind >/dev/null 2>&1; then
  echo "ERROR: kind command not found."
  exit 1
fi

if ! kind get clusters | grep -qx "${KIND_CLUSTER_NAME}"; then
  echo "ERROR: kind cluster '${KIND_CLUSTER_NAME}' not found."
  echo "Existing clusters:"
  kind get clusters || true
  exit 1
fi

echo "Building ${SAMPLE_FULL_IMAGE}..."
docker build -t "${SAMPLE_FULL_IMAGE}" ./40-poc-apps

echo "Loading image into kind cluster: ${KIND_CLUSTER_NAME}"
kind load docker-image "${SAMPLE_FULL_IMAGE}" --name "${KIND_CLUSTER_NAME}"

echo "Done."
```

Sửa target trong `Makefile`:

```makefile
build-kind:
	KIND_CLUSTER_NAME=$(KIND_CLUSTER_NAME) \
	SAMPLE_IMAGE=$(SAMPLE_IMAGE) \
	SAMPLE_TAG=$(SAMPLE_TAG) \
	./scripts/40-build-sample-kind.sh
```

Chạy lại:

```bash
make build-kind
```

Hoặc override:

```bash
make build-kind KIND_CLUSTER_NAME=observability-poc
```

---

## 7. Thứ tự build nhanh

### 7.1 Add Helm repos

```bash
make repos
```

Nếu lỗi:

```text
helm: command not found
```

Cài Helm trước.

### 7.2 Tạo namespace

```bash
make ns
```

Nếu lỗi:

```text
kubectl: command not found
```

Cài kubectl trước.

### 7.3 Cài LGTM Lite

```bash
make lgtm-lite
```

Kiểm tra:

```bash
kubectl -n obs-lgtm get pods
kubectl -n obs-lgtm get svc
```

### 7.4 Cài SigNoz + ClickHouse

```bash
make signoz
```

Kiểm tra:

```bash
kubectl -n obs-signoz get pods
kubectl -n obs-signoz get svc
```

SigNoz/ClickHouse có thể mất vài phút để ổn định.

### 7.5 Cài OpenTelemetry Router optional

```bash
make router-lite
```

Kiểm tra:

```bash
kubectl -n obs-router get pods
kubectl -n obs-router get svc
```

### 7.6 Build sample app image vào kind

```bash
make build-kind
```

Nếu cluster không tên `kind`, dùng:

```bash
make build-kind KIND_CLUSTER_NAME=observability-poc
```

### 7.7 Deploy sample app

```bash
make app
```

Kiểm tra:

```bash
kubectl -n poc-apps get pods
kubectl -n poc-apps get svc
kubectl -n poc-apps logs deploy/observability-sample-api
```

### 7.8 Port-forward

Mở 3 terminal:

```bash
make pf-grafana
```

```bash
make pf-signoz
```

```bash
make pf-app
```

URL mặc định:

```text
Grafana: http://localhost:3000
SigNoz:  http://localhost:8080
App:     http://localhost:8081
```

### 7.9 Tạo traffic

```bash
make load
```

Test thủ công:

```bash
curl http://localhost:8081/
curl http://localhost:8081/health
curl http://localhost:8081/slow
curl http://localhost:8081/error
curl http://localhost:8081/metrics
```

---

## 8. Stack A — LGTM Hybrid POC

### 8.1 Thành phần

```text
Grafana
Prometheus
Alertmanager
Loki
Tempo
Alloy
Mimir optional
```

### 8.2 Luồng dữ liệu

```text
Kubernetes metrics
    -> kube-prometheus-stack
    -> Prometheus
    -> Grafana

Container logs
    -> Alloy
    -> Loki
    -> Grafana Explore

Application traces
    -> OTLP
    -> Alloy hoặc OTel Router
    -> Tempo
    -> Grafana Explore

Optional metrics long-term
    -> Prometheus remote_write
    -> Mimir
    -> Grafana
```

### 8.3 Files liên quan

```text
10-lgtm/kps-values.yaml
10-lgtm/loki-values.yaml
10-lgtm/tempo-values.yaml
10-lgtm/alloy-values.yaml
10-lgtm/mimir-values.yaml
10-lgtm/grafana-datasources.yaml
60-alerts/prometheus-rules.yaml
```

### 8.4 Kiểm tra trong Grafana

```bash
make pf-grafana
```

Mở:

```text
http://localhost:3000
```

Kiểm tra datasource:

```text
Prometheus
Loki
Tempo
Mimir optional
```

Query test:

```text
Prometheus:
up

Loki:
{namespace="poc-apps"}

Tempo:
Search traces by service.name
```

---

## 9. Stack B — SigNoz + ClickHouse POC

### 9.1 Thành phần

```text
SigNoz UI
SigNoz Query Service
SigNoz OTel Collector
ClickHouse
Zookeeper hoặc Keeper
```

### 9.2 Luồng dữ liệu

```text
Application OTLP
    -> SigNoz OTel Collector
    -> ClickHouse
    -> SigNoz UI
```

### 9.3 Files liên quan

```text
20-signoz/signoz-values.yaml
20-signoz/clickhouse-notes.md
```

### 9.4 Kiểm tra SigNoz

```bash
make pf-signoz
```

Mở:

```text
http://localhost:8080
```

Kiểm tra:

```text
Services
Traces
Logs
Dashboards
Alerts
```

Nếu không có data, kiểm tra app đang gửi OTLP vào đúng endpoint.

---

## 10. Sample app

### 10.1 Mục tiêu

Sample app tạo telemetry cơ bản:

```text
HTTP request metrics
Application logs
Distributed traces
Error scenario
Latency scenario
Prometheus /metrics endpoint
```

### 10.2 Endpoints

```text
GET /          # normal request
GET /health    # health check
GET /slow      # tạo latency
GET /error     # tạo lỗi 500
GET /metrics   # Prometheus metrics
```

### 10.3 Build image

```bash
make build-kind
```

### 10.4 Deploy app

```bash
make app
```

### 10.5 Test app

```bash
make pf-app
```

```bash
curl http://localhost:8081/
curl http://localhost:8081/health
curl http://localhost:8081/slow
curl http://localhost:8081/error
curl http://localhost:8081/metrics
```

---

## 11. OpenTelemetry Router

### 11.1 Mục tiêu

Dùng khi muốn app chỉ gửi telemetry vào một endpoint:

```text
App
  -> otel-poc-router
       -> Tempo/Loki/Mimir
       -> SigNoz Collector
```

### 11.2 Cài router

```bash
make router-lite
```

### 11.3 App gửi OTLP về router

Trong deployment app:

```yaml
env:
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: http://otel-poc-router-opentelemetry-collector.obs-router.svc.cluster.local:4318
  - name: OTEL_EXPORTER_OTLP_PROTOCOL
    value: http/protobuf
```

Nếu chưa dùng router, app có thể gửi trực tiếp về Alloy hoặc SigNoz.

---

## 12. Label và OpenTelemetry resource attributes chuẩn

Kubernetes labels:

```yaml
env: poc
system: observability-poc
service: observability-sample-api
team: devops
owner: devops-platform
criticality: tier-3
cluster: k8s-poc-01
```

OpenTelemetry resource attributes:

```text
service.name=observability-sample-api
service.namespace=observability-poc
service.version=0.1.0
deployment.environment.name=poc
k8s.cluster.name=k8s-poc-01
team.name=devops
owner=devops-platform
criticality=tier-3
```

---

## 13. Benchmark scenarios

### 13.1 Normal traffic

```bash
curl http://localhost:8081/
curl http://localhost:8081/health
```

Kỳ vọng:

```text
Grafana có metrics
Loki có logs
Tempo có traces
SigNoz có service/traces/logs
```

### 13.2 Error traffic

```bash
curl http://localhost:8081/error
```

Kỳ vọng:

```text
Error log xuất hiện
Trace có error
Error rate tăng
```

### 13.3 Slow traffic

```bash
curl http://localhost:8081/slow
```

Kỳ vọng:

```text
Latency tăng
Trace waterfall thể hiện span chậm
p95/p99 latency tăng
```

### 13.4 Load test nhỏ

```bash
make load
```

Ghi lại:

```text
CPU/RAM Prometheus
CPU/RAM Loki
CPU/RAM Tempo
CPU/RAM ClickHouse
Storage growth
Query latency
```

---

## 14. Scorecard so sánh

Dùng file:

```text
90-benchmark/final-scorecard.md
```

Tiêu chí:

```text
Dễ cài đặt
Dễ troubleshoot
Metrics coverage
Logs coverage
Tracing/APM
Dashboard
Alert
Query latency
Storage growth
CPU/RAM
Khả năng mở rộng
Độ phức tạp vận hành
Phù hợp production
```

Thang điểm:

```text
1 = yếu
2 = cần custom nhiều
3 = đạt POC
4 = tốt
5 = rất tốt
```

---

## 15. Troubleshooting nhanh

### 15.1 `helm: command not found`

```bash
helm version
```

Nếu chưa có Helm, cài Helm rồi chạy lại:

```bash
make repos
```

### 15.2 `kubectl: command not found`

```bash
kubectl version --client
```

Nếu chưa có kubectl, cài kubectl rồi chạy lại:

```bash
make ns
```

### 15.3 `ERROR: no nodes found for cluster "kind"`

Kiểm tra:

```bash
kind get clusters
```

Nếu output là:

```text
observability-poc
```

thì chạy:

```bash
make build-kind KIND_CLUSTER_NAME=observability-poc
```

Hoặc:

```bash
kind load docker-image observability-sample-api:0.1.0 --name observability-poc
```

### 15.4 Pod `ImagePullBackOff`

Kiểm tra image:

```bash
kubectl -n poc-apps describe pod <pod-name>
```

Kiểm tra deployment:

```bash
kubectl -n poc-apps get deploy observability-sample-api -o yaml | grep image:
```

Manifest nên có:

```yaml
image: observability-sample-api:0.1.0
imagePullPolicy: IfNotPresent
```

### 15.5 Không có logs trong Loki

Kiểm tra Alloy:

```bash
kubectl -n obs-lgtm get pods | grep alloy
kubectl -n obs-lgtm logs daemonset/alloy
```

Query Loki trong Grafana:

```text
{namespace="poc-apps"}
```

### 15.6 Không có traces trong Tempo

Kiểm tra env của app:

```bash
kubectl -n poc-apps get deploy observability-sample-api -o yaml | grep OTEL -A20
```

Endpoint phổ biến:

```text
Router:
http://otel-poc-router-opentelemetry-collector.obs-router.svc.cluster.local:4318

Alloy:
http://alloy.obs-lgtm.svc.cluster.local:4318

SigNoz:
http://signoz-otel-collector.obs-signoz.svc.cluster.local:4318
```

### 15.7 SigNoz không lên

Kiểm tra pods:

```bash
kubectl -n obs-signoz get pods
kubectl -n obs-signoz get pvc
```

Kiểm tra ClickHouse logs:

```bash
kubectl -n obs-signoz logs <clickhouse-pod>
```

ClickHouse cần nhiều RAM. Nếu máy yếu, không chạy LGTM và SigNoz song song.

### 15.8 PVC Pending

Kiểm tra StorageClass:

```bash
kubectl get storageclass
kubectl get pvc -A
```

Nếu không có default StorageClass, sửa `global.storageClass` trong values hoặc tạo StorageClass phù hợp.

---

## 16. Uninstall

Gỡ app:

```bash
kubectl delete namespace poc-apps
```

Gỡ LGTM:

```bash
make uninstall-lgtm
```

Gỡ SigNoz:

```bash
make uninstall-signoz
```

Gỡ toàn bộ POC:

```bash
make uninstall
```

Xóa kind cluster:

```bash
kind delete cluster --name observability-poc
```

---

## 17. Checklist cho Codex / VS Code

Khi mở repo này bằng VS Code hoặc đưa cho Codex, yêu cầu kiểm tra và sửa các điểm sau.

### 17.1 Makefile

- Thêm biến:

```makefile
KIND_CLUSTER_NAME ?= observability-poc
SAMPLE_IMAGE ?= observability-sample-api
SAMPLE_TAG ?= 0.1.0
```

- Đảm bảo target `build-kind` truyền biến xuống script.

### 17.2 `scripts/40-build-sample-kind.sh`

- Không hard-code `kind`.
- Dùng biến `KIND_CLUSTER_NAME`.
- Kiểm tra cluster tồn tại trước khi load image.
- In hướng dẫn rõ nếu cluster không tồn tại.

### 17.3 Deployment app

- `imagePullPolicy: IfNotPresent`.
- Image đúng `observability-sample-api:0.1.0`.
- Env `OTEL_EXPORTER_OTLP_ENDPOINT` trỏ đúng router hoặc backend mong muốn.

### 17.4 Helm chart values

- Kiểm tra chart Loki tương thích với `deploymentMode`.
- Kiểm tra chart SigNoz tương thích với các key trong `signoz-values.yaml`.
- Thêm command debug:

```bash
helm show values grafana/loki > /tmp/loki-default-values.yaml
helm show values signoz/signoz > /tmp/signoz-default-values.yaml
```

### 17.5 Target status

Nên có target:

```makefile
status:
	./scripts/90-status.sh
```

Nội dung `scripts/90-status.sh` nên gồm:

```bash
#!/usr/bin/env bash
set -euo pipefail

kubectl get nodes
kubectl get pods -n obs-lgtm || true
kubectl get pods -n obs-signoz || true
kubectl get pods -n obs-router || true
kubectl get pods -n poc-apps || true
kubectl get pvc -A || true
```

---

## 18. Lệnh end-to-end sau khi fix

```bash
make repos
make ns
make lgtm-lite
make signoz
make router-lite
make build-kind KIND_CLUSTER_NAME=observability-poc
make app
make status
```

Port-forward:

```bash
make pf-grafana
make pf-signoz
make pf-app
```

Sinh traffic:

```bash
make load
```

---

## 19. Kỳ vọng kết quả

### LGTM

```text
Grafana thấy Kubernetes metrics.
Grafana Explore query được Loki logs.
Grafana Explore search được Tempo traces.
PrometheusRule tạo được alert cơ bản.
```

### SigNoz

```text
SigNoz thấy service observability-sample-api.
SigNoz thấy traces.
SigNoz thấy logs.
SigNoz thấy metrics hoặc application telemetry.
ClickHouse lưu telemetry.
```

### Benchmark

```text
Có số liệu CPU/RAM/storage.
Có nhận xét dashboard/troubleshooting.
Có scorecard so sánh LGTM và SigNoz.
```

---

## 20. Kết luận

POC này không nhằm chứng minh scale lớn. Mục tiêu là kiểm chứng 5 câu hỏi:

```text
1. Service nào đang lỗi?
2. Lỗi bắt đầu từ khi nào?
3. Metrics, logs, traces có liên kết được không?
4. Alert có dẫn tới dashboard/log/trace/runbook không?
5. Stack nào dễ vận hành và tối ưu chi phí hơn?
```

Nếu LGTM thắng, hướng production:

```text
Grafana HA
Mimir distributed
Loki distributed hoặc simple scalable
Tempo distributed
Alloy chuẩn hóa toàn công ty
Object storage production
Alertmanager routing theo team
Dashboard/alert/config bằng GitOps
```

Nếu SigNoz thắng, hướng production:

```text
SigNoz HA
ClickHouse cluster
Keeper/Zookeeper HA
OTel Collector Gateway
Retention/TTL rõ ràng
Backup/restore ClickHouse
RBAC/multi-team
Cost guardrail theo telemetry volume
```
