# LGTM Grafana Multi-Node Runbook

Runbook này mô tả bản LGTM multi-node chạy thật trên máy local bằng Kind. Mục tiêu là giúp bạn hiểu cách stack production tách thành nhiều thành phần và chạy phân tán trên nhiều Kubernetes node.

## Kết Quả Đã Build

Cluster mới:

```text
kind-lgtm-multinode
```

Node:

```text
1 control-plane
3 worker
```

Namespace:

```text
observability
observability-agents
```

Stack:

```text
Grafana
Prometheus / kube-prometheus-stack
Alertmanager
Mimir
Loki
Tempo
Alloy Gateway
Alloy Agent DaemonSet
MinIO sandbox
```

## Vì Sao Gọi Là Multi-Node

Trước đây lab chỉ có một Kubernetes node, nên mọi pod đều nằm chung một node. Bản này có 4 node Kind, trong đó workload chính được scheduler trải lên 3 worker.

Ví dụ:

```text
Alloy Gateway: 2 replicas, chạy trên worker khác nhau
Alloy Agent: DaemonSet, mỗi worker có 1 pod agent
Loki read/write/gateway: nhiều replica, trải trên nhiều worker
Mimir distributor/querier/query-frontend/query-scheduler: nhiều replica
Tempo distributor/querier/query-frontend/gateway: nhiều replica
node-exporter: chạy trên cả control-plane và worker
```

Nhờ vậy dashboard có thể thể hiện:

```text
node inventory
pod distribution
metrics pipeline
logs pipeline
traces pipeline
PVC/storage
restart/readiness
```

## Vì Sao Không Scale Mọi Thứ Lên 3

Máy local có 8 CPU và 60Gi RAM, đủ học multi-node nhưng không phải production thật. Vì vậy overlay lab chỉ scale các thành phần stateless hoặc ít rủi ro:

```text
Scale lên:
- Mimir distributor, querier, query-frontend, query-scheduler
- Loki read, write, gateway
- Tempo distributor, querier, query-frontend, gateway
- Alloy Gateway

Giữ 1 replica:
- Grafana, vì đang dùng 1 PVC ReadWriteOnce
- Prometheus, vì lab không cần HA Prometheus
- Alertmanager, vì lab chưa cần HA alert routing
- MinIO sandbox, vì chỉ là object storage học tập
- Tempo ingester, vì lab single-machine giữ replication_factor=1
```

Production thật có thể tăng các phần stateful, nhưng phải đi kèm storage, anti-affinity, zone-aware replication và capacity planning.

## File Đã Thêm

```text
kind/lgtm-multinode.yaml
overlays/kind-multinode/mimir-values.yaml
overlays/kind-multinode/loki-values.yaml
overlays/kind-multinode/tempo-values.yaml
overlays/kind-multinode/alloy-gateway-values.yaml
scripts/create-kind-multinode.sh
scripts/install-kind-multinode.sh
scripts/test-lgtm-multinode.sh
scripts/port-forward-grafana.sh
```

## Lệnh Triển Khai

```bash
cd /home/ducna/Documents/Observability/lgtm-grafana-production
make kind-multinode
make install-kind-multinode
```

Nếu Kind báo lỗi `Too many open files`, tăng inotify:

```bash
sudo sysctl -w fs.inotify.max_user_instances=1024 fs.inotify.max_user_watches=1048576
```

Script `make kind-multinode` đã tự thử tăng bằng `sudo -n` nếu giới hạn quá thấp.

## Lệnh Test

```bash
make test-kind-multinode
```

Test này kiểm tra:

```text
Mimir: query count(up), xác nhận metrics đi được vào Mimir
Loki: query log trong namespace observability, xác nhận Alloy Agent -> Loki
Tempo: gửi OTLP trace vào Alloy Gateway, sau đó query trace từ Tempo
```

Kết quả pass quan trọng:

```text
Mimir count(up) > 0
Loki trả streams có log
Tempo trả trace service.name=lgtm-multinode-smoke
```

## Mở Grafana

```bash
make pf-grafana
```

Truy cập:

```text
http://127.0.0.1:3001
```

Đăng nhập:

```text
User: admin
Pass: admin-learning-lab-change-me
```

Dashboard đã apply:

```text
LGTM Production Stack Overview
```

## Điểm Cần Giải Thích Khi Demo

### Metrics

Prometheus scrape Kubernetes metrics như pod, node, kube-state-metrics. Sau đó Prometheus remote_write sang Mimir. Grafana dùng datasource Mimir để query lại.

### Logs

Alloy Agent chạy dạng DaemonSet trên từng worker node. Agent đọc pod logs của node đó, gắn label như namespace, pod, container, cluster, env rồi gửi vào Loki.

### Traces

Application gửi OTLP HTTP/gRPC vào Alloy Gateway. Alloy Gateway batch và forward traces sang Tempo. Grafana dùng datasource Tempo để tra trace.

### Object Storage

Mimir, Loki và Tempo dùng MinIO sandbox làm object storage. Trong production thật, thay MinIO bằng S3 hoặc object storage nội bộ của công ty.

### Multi-Node Scheduling

Kubernetes scheduler trải pod lên nhiều worker. Khi một pod stateless có 2 replica, hệ thống có khả năng chịu lỗi tốt hơn một chút vì một node/pod chết thì replica còn lại vẫn chạy. Với stateful component, HA thật cần replication factor, nhiều PVC, anti-affinity và zone-aware replication.

## Cleanup

Xóa cluster multi-node:

```bash
kind delete cluster --name lgtm-multinode
```

Quay lại cluster cũ:

```bash
kubectl config use-context kind-observability-poc
```
