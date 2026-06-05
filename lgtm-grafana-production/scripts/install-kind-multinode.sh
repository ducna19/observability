#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAMESPACE="${NAMESPACE:-observability}"
AGENT_NAMESPACE="${AGENT_NAMESPACE:-observability-agents}"
CONTEXT="${CONTEXT:-kind-lgtm-multinode}"
OVERLAY_DIR="${ROOT_DIR}/overlays/kind-multinode"

kubectl config use-context "${CONTEXT}"

kubectl apply -f "${ROOT_DIR}/namespaces.yaml"
kubectl apply -f "${ROOT_DIR}/manifests/minio-sandbox.yaml"
kubectl apply -f "${ROOT_DIR}/secrets/object-storage.example.yaml"
kubectl apply -f "${ROOT_DIR}/secrets/grafana-admin.example.yaml"
kubectl apply -f "${ROOT_DIR}/secrets/grafana-oauth.example.yaml"

kubectl -n "${NAMESPACE}" rollout status statefulset/lgtm-minio --timeout=5m
kubectl -n "${NAMESPACE}" wait --for=condition=complete job/lgtm-minio-create-buckets --timeout=5m

echo "Installing Grafana Mimir on multi-node Kind..."
helm upgrade --install mimir grafana/mimir-distributed \
  --namespace "${NAMESPACE}" \
  -f "${ROOT_DIR}/values/mimir-production-values.yaml" \
  -f "${OVERLAY_DIR}/mimir-values.yaml" \
  --wait \
  --timeout 45m

echo "Installing Loki on multi-node Kind..."
helm upgrade --install loki grafana/loki \
  --namespace "${NAMESPACE}" \
  -f "${ROOT_DIR}/values/loki-production-values.yaml" \
  -f "${OVERLAY_DIR}/loki-values.yaml" \
  --wait \
  --timeout 45m

echo "Installing Tempo distributed on multi-node Kind..."
helm upgrade --install tempo grafana/tempo-distributed \
  --namespace "${NAMESPACE}" \
  -f "${ROOT_DIR}/values/tempo-production-values.yaml" \
  -f "${OVERLAY_DIR}/tempo-values.yaml" \
  --wait \
  --timeout 45m

echo "Installing kube-prometheus-stack and Grafana..."
helm upgrade --install kps prometheus-community/kube-prometheus-stack \
  --namespace "${NAMESPACE}" \
  -f "${ROOT_DIR}/values/kps-production-values.yaml" \
  --wait \
  --timeout 30m

echo "Installing Alloy gateway on multi-node Kind..."
helm upgrade --install alloy-gateway grafana/alloy \
  --namespace "${NAMESPACE}" \
  -f "${ROOT_DIR}/values/alloy-gateway-values.yaml" \
  -f "${OVERLAY_DIR}/alloy-gateway-values.yaml" \
  --wait \
  --timeout 20m

echo "Installing Alloy node agents..."
helm upgrade --install alloy-agent grafana/alloy \
  --namespace "${AGENT_NAMESPACE}" \
  -f "${ROOT_DIR}/values/alloy-agent-values.yaml" \
  --wait \
  --timeout 20m

"${ROOT_DIR}/scripts/apply-dashboards.sh"

echo "LGTM multi-node install completed."
kubectl -n "${NAMESPACE}" get pods -o wide
kubectl -n "${AGENT_NAMESPACE}" get pods -o wide
