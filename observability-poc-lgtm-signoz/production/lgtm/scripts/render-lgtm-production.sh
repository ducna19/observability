#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PROD_DIR="${ROOT_DIR}/production/lgtm"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/.rendered/lgtm-production}"
NAMESPACE="${NAMESPACE:-observability}"
AGENT_NAMESPACE="${AGENT_NAMESPACE:-observability-agents}"

mkdir -p "${OUT_DIR}"

helm template mimir grafana/mimir-distributed \
  --namespace "${NAMESPACE}" \
  -f "${PROD_DIR}/values/mimir-production-values.yaml" \
  > "${OUT_DIR}/mimir.yaml"

helm template loki grafana/loki \
  --namespace "${NAMESPACE}" \
  -f "${PROD_DIR}/values/loki-production-values.yaml" \
  > "${OUT_DIR}/loki.yaml"

helm template tempo grafana/tempo-distributed \
  --namespace "${NAMESPACE}" \
  -f "${PROD_DIR}/values/tempo-production-values.yaml" \
  > "${OUT_DIR}/tempo.yaml"

helm template kps prometheus-community/kube-prometheus-stack \
  --namespace "${NAMESPACE}" \
  -f "${PROD_DIR}/values/kps-production-values.yaml" \
  > "${OUT_DIR}/kps.yaml"

helm template alloy-gateway grafana/alloy \
  --namespace "${NAMESPACE}" \
  -f "${PROD_DIR}/values/alloy-gateway-values.yaml" \
  > "${OUT_DIR}/alloy-gateway.yaml"

helm template alloy-agent grafana/alloy \
  --namespace "${AGENT_NAMESPACE}" \
  -f "${PROD_DIR}/values/alloy-agent-values.yaml" \
  > "${OUT_DIR}/alloy-agent.yaml"

echo "Rendered manifests to ${OUT_DIR}"
