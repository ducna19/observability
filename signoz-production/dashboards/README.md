# SigNoz Dashboards

## SigNoz Production Stack Overview

File:

```text
dashboards/signoz-stack-overview.json
```

Import in SigNoz:

```text
Dashboards > New Dashboard / Import JSON
```

What it shows:

- SigNoz component inventory
- Telemetry volume in ClickHouse: logs, metric samples, metric series, traces
- Logs/events by component
- Recent Kubernetes events
- Metric samples by minute
- Logs by minute
- Smoke-test traces for service `signoz-production-smoke`

Demo message:

```text
Dashboard nay chung minh SigNoz dang gom logs, metrics, traces vao ClickHouse.
Khac voi LGTM tach backend, SigNoz tap trung vao mot san pham APM va mot storage chinh la ClickHouse.
```

If a Helm upgrade resets the collector to OpAMP/nop mode, reapply:

```bash
make patch-static-collector
```
