#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f 00-namespaces/namespaces.yaml

echo "Installing OTel Router with Mimir exporter..."
helm upgrade --install otel-poc-router open-telemetry/opentelemetry-collector \
  --namespace obs-router \
  --create-namespace \
  -f 30-router/otel-router-values-with-mimir.yaml \
  --wait \
  --timeout 15m

kubectl -n obs-router get pods
kubectl -n obs-router get svc
echo "OTel Router with Mimir installed."
