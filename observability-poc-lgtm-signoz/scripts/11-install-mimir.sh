#!/usr/bin/env bash
set -euo pipefail

echo "Installing optional Mimir POC..."
helm upgrade --install mimir grafana/mimir-distributed \
  --namespace obs-lgtm \
  -f 10-lgtm/mimir-values.yaml \
  --wait \
  --timeout 30m

echo "Upgrading Prometheus to remote_write into Mimir..."
helm upgrade --install kps prometheus-community/kube-prometheus-stack \
  --namespace obs-lgtm \
  -f 10-lgtm/kps-values-with-mimir.yaml \
  --wait \
  --timeout 20m

echo "Mimir installed and Prometheus remote_write enabled."
kubectl -n obs-lgtm get pods | grep -E 'mimir|kps' || true
