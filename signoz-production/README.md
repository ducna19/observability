# SigNoz Production Stack

This folder is the SigNoz side of the comparison with `lgtm-grafana-production`.

It deploys:

- SigNoz UI and query service
- OpenTelemetry Collector ingestion endpoint
- ClickHouse plus Zookeeper for telemetry storage
- SigNoz Alertmanager
- SigNoz Kubernetes infra collectors for logs, host metrics, kubelet metrics, cluster metrics, and Kubernetes events

This is production-like, not final production. It uses persistent volumes and separated namespaces, but requests are reduced so it can run on the current one-node Kind lab beside the LGTM stack.

## Architecture

```text
Applications / Kubernetes
        |
        v
SigNoz OpenTelemetry Collector
        |
        v
ClickHouse
        |
        v
SigNoz UI
```

Kubernetes infra data follows this path:

```text
Pods / nodes / kubelet / events
        |
        v
signoz-k8s-infra collectors
        |
        v
signoz-otel-collector.signoz-production.svc.cluster.local:4318
        |
        v
ClickHouse
```

## Commands

Render manifests:

```bash
make render
```

Install:

```bash
make install
```

Check status:

```bash
make status
```

If a Helm upgrade reintroduces OpAMP-managed collector args, reapply the static collector patch:

```bash
make patch-static-collector
```

Open UI:

```bash
make pf-signoz
```

Then visit:

```text
http://127.0.0.1:8081
```

The first visit creates the SigNoz admin account.

## Application OTLP Endpoint

For applications running inside the cluster:

```text
OTLP gRPC: signoz-otel-collector.signoz-production.svc.cluster.local:4317
OTLP HTTP: http://signoz-otel-collector.signoz-production.svc.cluster.local:4318
```

For local applications, port-forward the collector:

```bash
kubectl -n signoz-production port-forward svc/signoz-otel-collector 4317:4317 4318:4318
```

## Production Gaps To Replace Later

- Replace single-node lab sizing with HA sizing.
- Use real storage classes and backup policy.
- Configure ingress, TLS, SSO, and SMTP/webhook alert routing.
- Review retention and ClickHouse TTL policy for company data volume.
- Move passwords/secrets out of plain values into managed secrets.
