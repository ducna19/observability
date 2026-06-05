#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f 00-namespaces/namespaces.yaml

echo "Installing kube-prometheus-stack..."
helm upgrade --install kps prometheus-community/kube-prometheus-stack \
  --namespace obs-lgtm \
  -f 10-lgtm/kps-values.yaml \
  --wait \
  --timeout 20m

echo "Installing Loki..."
if ! helm upgrade --install loki grafana/loki \
  --namespace obs-lgtm \
  -f 10-lgtm/loki-values.yaml \
  --wait \
  --timeout 20m; then
  echo "Loki install with loki-values.yaml failed. Trying loki-values-monolithic-alt.yaml..."
  helm upgrade --install loki grafana/loki \
    --namespace obs-lgtm \
    -f 10-lgtm/loki-values-monolithic-alt.yaml \
    --wait \
    --timeout 20m
fi

echo "Installing Tempo..."
helm upgrade --install tempo grafana/tempo \
  --namespace obs-lgtm \
  -f 10-lgtm/tempo-values.yaml \
  --wait \
  --timeout 20m

echo "Installing Alloy..."
helm upgrade --install alloy grafana/alloy \
  --namespace obs-lgtm \
  -f 10-lgtm/alloy-values.yaml \
  --wait \
  --timeout 20m

kubectl apply -f 10-lgtm/alloy-otlp-service.yaml
kubectl apply -f 10-lgtm/grafana-datasources.yaml
kubectl apply -f 50-dashboards/poc-dashboard-configmap.yaml
kubectl apply -f 60-alerts/prometheus-rules.yaml

echo "Restarting Grafana to reload sidecar data sources/dashboards..."
kubectl -n obs-lgtm rollout restart deploy/kps-grafana || true

echo "LGTM Lite installed."
kubectl -n obs-lgtm get pods
