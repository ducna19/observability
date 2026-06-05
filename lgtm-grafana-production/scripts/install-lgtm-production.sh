#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROD_DIR="${ROOT_DIR}"
NAMESPACE="${NAMESPACE:-observability}"
AGENT_NAMESPACE="${AGENT_NAMESPACE:-observability-agents}"

if grep -R "REPLACE_ME" "${PROD_DIR}/values" >/dev/null 2>&1; then
  echo "ERROR: values still contains REPLACE_ME placeholders."
  echo "Edit values and secrets first, or render a cluster-specific overlay from these baselines."
  exit 1
fi

kubectl apply -f "${PROD_DIR}/namespaces.yaml"
kubectl apply -f "${PROD_DIR}/manifests/minio-sandbox.yaml"
kubectl apply -f "${PROD_DIR}/secrets/object-storage.example.yaml"
kubectl apply -f "${PROD_DIR}/secrets/grafana-admin.example.yaml"
kubectl apply -f "${PROD_DIR}/secrets/grafana-oauth.example.yaml"

kubectl -n "${NAMESPACE}" rollout status statefulset/lgtm-minio --timeout=5m
kubectl -n "${NAMESPACE}" wait --for=condition=complete job/lgtm-minio-create-buckets --timeout=5m

if ! kubectl -n "${NAMESPACE}" get secret lgtm-object-storage >/dev/null 2>&1; then
  echo "ERROR: secret '${NAMESPACE}/lgtm-object-storage' not found."
  echo "Create it from your secret manager or run: ./scripts/bootstrap-sandbox-secrets.sh"
  exit 1
fi

if ! kubectl -n "${NAMESPACE}" get secret grafana-admin >/dev/null 2>&1; then
  echo "ERROR: secret '${NAMESPACE}/grafana-admin' not found."
  echo "Create it from your secret manager or run: ./scripts/bootstrap-sandbox-secrets.sh"
  exit 1
fi

echo "Installing Grafana Mimir..."
helm upgrade --install mimir grafana/mimir-distributed \
  --namespace "${NAMESPACE}" \
  -f "${PROD_DIR}/values/mimir-production-values.yaml" \
  --wait \
  --timeout 45m

echo "Installing Loki..."
helm upgrade --install loki grafana/loki \
  --namespace "${NAMESPACE}" \
  -f "${PROD_DIR}/values/loki-production-values.yaml" \
  --wait \
  --timeout 45m

echo "Installing Tempo distributed..."
helm upgrade --install tempo grafana/tempo-distributed \
  --namespace "${NAMESPACE}" \
  -f "${PROD_DIR}/values/tempo-production-values.yaml" \
  --wait \
  --timeout 45m

echo "Installing kube-prometheus-stack and Grafana..."
helm upgrade --install kps prometheus-community/kube-prometheus-stack \
  --namespace "${NAMESPACE}" \
  -f "${PROD_DIR}/values/kps-production-values.yaml" \
  --wait \
  --timeout 30m

echo "Installing Alloy gateway..."
helm upgrade --install alloy-gateway grafana/alloy \
  --namespace "${NAMESPACE}" \
  -f "${PROD_DIR}/values/alloy-gateway-values.yaml" \
  --wait \
  --timeout 20m

echo "Installing Alloy node agents..."
helm upgrade --install alloy-agent grafana/alloy \
  --namespace "${AGENT_NAMESPACE}" \
  -f "${PROD_DIR}/values/alloy-agent-values.yaml" \
  --wait \
  --timeout 20m

echo "Production LGTM install completed."
kubectl -n "${NAMESPACE}" get pods
kubectl -n "${AGENT_NAMESPACE}" get pods
