# Production LGTM Stack

This directory is the production baseline for the Grafana LGTM platform:

- Grafana for UI, dashboards, Explore, and alert UX
- Mimir for long-term metrics storage
- Loki for logs
- Tempo for traces
- Alloy gateway for OTLP ingest
- Alloy node agents for Kubernetes log collection
- kube-prometheus-stack for Prometheus, Alertmanager, kube-state-metrics, node-exporter, and Grafana

The old local POC flow remains in the repo for reference, but production work should start here.

## Production Shape

```text
Applications
  -> OTLP
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

## Namespaces

```text
observability         # Grafana, Mimir, Loki, Tempo, Prometheus, Alertmanager, Alloy gateway
observability-agents  # Alloy daemonset/node agents
```

## Required External Dependencies

Production needs real external services:

- S3-compatible object storage for Mimir, Loki, and Tempo
- A secret manager or ExternalSecrets/SealedSecrets
- Ingress controller and TLS certificates
- Optional but recommended: external Grafana database
- Optional but recommended: OIDC/SSO provider

Do not use MinIO or filesystem storage for production.

## Configure First

Replace every `REPLACE_ME_*` placeholder in production values:

```bash
grep -R "REPLACE_ME" production/lgtm/values
```

Create real secrets through your secret manager. Example templates:

```text
production/lgtm/secrets/object-storage.example.yaml
production/lgtm/secrets/grafana-admin.example.yaml
production/lgtm/secrets/grafana-oauth.example.yaml
```

For a quick non-GitOps test only:

```bash
kubectl apply -f production/lgtm/namespaces.yaml
kubectl apply -f production/lgtm/secrets/object-storage.example.yaml
kubectl apply -f production/lgtm/secrets/grafana-admin.example.yaml
kubectl apply -f production/lgtm/secrets/grafana-oauth.example.yaml
```

Replace the example secret values before applying them.

## Render Manifests

```bash
make prod-render
```

Rendered output goes to:

```text
.rendered/lgtm-production/
```

Use this for review, policy checks, kubeconform, or GitOps PRs.

## Install

```bash
make prod-lgtm
```

The install script intentionally fails if any `REPLACE_ME` placeholder remains in `production/lgtm/values`.

## Status

```bash
make prod-status
```

## Application OTLP Endpoint

Send application telemetry to:

```text
http://alloy-gateway.observability.svc.cluster.local:4318
```

For OTLP/gRPC:

```text
alloy-gateway.observability.svc.cluster.local:4317
```

Recommended resource attributes:

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

## Production Defaults In This Baseline

Retention:

```text
Mimir: 30 days
Loki: 30 days
Tempo: 14 days
Prometheus local: 6 hours
```

High availability:

```text
Grafana: 2 replicas
Prometheus: 2 replicas
Alertmanager: 3 replicas
Mimir: HA distributed components
Loki: SimpleScalable read/write/backend replicas
Tempo: distributed components
Alloy gateway: 3 replicas
Alloy agents: DaemonSet
```

## Clear Old Local POC

Only run this when you are comfortable deleting local POC resources:

```bash
make uninstall
```

PVCs may remain depending on storage class reclaim policy. Review before deleting:

```bash
kubectl get pvc -A | grep -E 'obs-lgtm|obs-signoz|obs-router|poc-apps'
kubectl get pv
```

Delete old POC namespaces only after confirming no data is needed:

```bash
kubectl delete ns obs-lgtm obs-signoz obs-router poc-apps
```

This production baseline uses `observability` and `observability-agents`, not the old POC namespaces.
