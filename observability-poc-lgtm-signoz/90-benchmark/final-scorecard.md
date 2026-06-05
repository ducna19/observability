# Final Scorecard

Thang điểm:

```text
1 = yếu
2 = cần custom nhiều
3 = đạt POC
4 = tốt
5 = rất tốt / gần production-ready
```

| Tiêu chí | LGTM | SigNoz + ClickHouse | Ghi chú |
|---|---:|---:|---|
| Dễ cài đặt ban đầu |  |  |  |
| Metrics coverage |  |  |  |
| Logs coverage |  |  |  |
| Trace/APM experience |  |  |  |
| Correlation M/L/T |  |  |  |
| Dashboard flexibility |  |  |  |
| Alerting |  |  |  |
| Kubernetes monitoring |  |  |  |
| Query latency |  |  |  |
| Storage efficiency |  |  |  |
| RBAC/multi-team |  |  |  |
| Backup/restore |  |  |  |
| Upgrade complexity |  |  |  |
| Skill requirement |  |  |  |
| Production readiness |  |  |  |

## Decision rule

LGTM thắng nếu:

```text
- Dashboard/NOC/Executive tốt hơn.
- Kubernetes monitoring tốt hơn.
- Alert/SLO governance tốt hơn.
- DevOps vận hành tự tin hơn.
- Cost không cao hơn SigNoz quá 30–40%.
```

SigNoz thắng nếu:

```text
- Cost thấp hơn LGTM ít nhất 30–40%.
- APM out-of-box tốt hơn rõ rệt.
- Query log/trace nhanh hơn.
- Ít thành phần phải vận hành hơn.
- ClickHouse ổn định và team vận hành tự tin.
```
