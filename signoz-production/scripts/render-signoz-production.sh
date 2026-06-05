#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RENDERED_DIR="${ROOT_DIR}/.rendered"

mkdir -p "${RENDERED_DIR}"

kubectl kustomize "${ROOT_DIR}" >/dev/null 2>&1 || true
cp "${ROOT_DIR}/namespaces.yaml" "${RENDERED_DIR}/namespaces.yaml"

helm template signoz signoz/signoz \
  --namespace signoz-production \
  --version 0.126.1 \
  -f "${ROOT_DIR}/values/signoz-production-values.yaml" \
  > "${RENDERED_DIR}/signoz.yaml"

helm template signoz-k8s-infra signoz/k8s-infra \
  --namespace signoz-production-agents \
  -f "${ROOT_DIR}/values/k8s-infra-production-values.yaml" \
  > "${RENDERED_DIR}/k8s-infra.yaml"

echo "Rendered manifests to ${RENDERED_DIR}"
