#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "${ROOT_DIR}/namespaces.yaml"

helm upgrade --install signoz signoz/signoz \
  --namespace signoz-production \
  --version 0.126.1 \
  -f "${ROOT_DIR}/values/signoz-production-values.yaml" \
  --wait \
  --timeout 45m

"${ROOT_DIR}/scripts/patch-static-collector.sh"

helm upgrade --install signoz-k8s-infra signoz/k8s-infra \
  --namespace signoz-production-agents \
  -f "${ROOT_DIR}/values/k8s-infra-production-values.yaml" \
  --wait \
  --timeout 20m

"${ROOT_DIR}/scripts/status-signoz-production.sh"
