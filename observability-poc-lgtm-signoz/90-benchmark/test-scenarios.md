# Test Scenarios

## Scenario 1 — Normal traffic

Mục tiêu:

- App có metrics.
- App có logs.
- App có traces.
- Cả Grafana và SigNoz thấy service.

Cách chạy:

```bash
./scripts/60-port-forward-sample-app.sh
./scripts/70-generate-load.sh
```

## Scenario 2 — HTTP 500 error

```bash
curl http://localhost:18080/error
```

Kỳ vọng:

| Stack | Kỳ vọng |
|---|---|
| LGTM | Prometheus error rate tăng, Loki có ERROR log, Tempo có trace lỗi |
| SigNoz | Service error tăng, trace lỗi dễ tìm, log liên quan hiển thị |

## Scenario 3 — High latency

```bash
curl http://localhost:18080/slow
```

Kỳ vọng:

| Stack | Kỳ vọng |
|---|---|
| LGTM | Dashboard latency tăng, Tempo trace có span chậm |
| SigNoz | APM latency view thể hiện endpoint chậm |

## Scenario 4 — Pod restart

```bash
kubectl -n poc-apps rollout restart deploy/sample-api
```

Kỳ vọng:

- Kubernetes dashboard thấy pod restart.
- Alert nếu restart nhiều lần.

## Scenario 5 — Log volume nhỏ

```bash
DURATION_SECONDS=1800 ./scripts/70-generate-load.sh
```

Đo:

- Loki storage growth.
- ClickHouse storage growth.
- Query latency logs.
- CPU/RAM của Loki và ClickHouse.
