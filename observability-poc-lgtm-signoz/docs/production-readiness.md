# Production Readiness Notes

POC này không bật đầy đủ production mode. Khi đi production cần bổ sung:

## LGTM production

```text
- Grafana HA + external database
- Mimir distributed + object storage
- Loki microservices hoặc simple scalable + object storage
- Tempo distributed + object storage
- Alloy gateway + daemonset profile
- Alertmanager HA
- SSO/RBAC
- Dashboard/alert/config provisioning bằng GitOps
- Backup/restore
- Capacity planning
```

## SigNoz production

```text
- SigNoz HA
- ClickHouse cluster
- ClickHouse Keeper/Zookeeper HA
- Backup ClickHouse
- Retention/TTL theo log/trace/metrics
- Collector gateway HA
- RBAC/SSO
- Resource quota
- Ingest guardrail
```

## Common governance

```text
- Service ownership matrix
- Label/tag standard
- Alert routing theo team/service/severity
- Dashboard folder convention
- Retention policy
- Runbook
- Incident workflow
```
