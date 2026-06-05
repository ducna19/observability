# Alert Standard

## Severity

| Severity | Ý nghĩa |
|---|---|
| critical | Ảnh hưởng service hoặc customer/business |
| warning | Có rủi ro, cần xử lý trong giờ làm việc hoặc theo quy trình |
| info | Chỉ ghi nhận, không đánh thức on-call |

## Labels bắt buộc trong alert

```yaml
severity: warning
env: poc
system: observability-poc
service: sample-api
team: devops
owner: devops-platform
criticality: tier-3
```

## Alert tối thiểu cho POC

```text
- PodCrashLooping
- DeploymentUnavailable
- NodeNotReady
- HighErrorRate
- HighLatencyP95
- CollectorDown
- LokiIngestionIssue
- TempoIngestionIssue
- ClickHouseDiskHigh
- ClickHouseHighMemory
```
