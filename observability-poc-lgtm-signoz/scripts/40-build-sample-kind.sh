#!/usr/bin/env bash
set -euo pipefail

KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-observability-poc}"
SAMPLE_IMAGE="${SAMPLE_IMAGE:-observability-sample-api}"
SAMPLE_TAG="${SAMPLE_TAG:-0.1.0}"
SAMPLE_FULL_IMAGE="${SAMPLE_IMAGE}:${SAMPLE_TAG}"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker command not found."
  exit 1
fi

if ! command -v kind >/dev/null 2>&1; then
  echo "ERROR: kind command not found."
  exit 1
fi

if ! kind get clusters | grep -qx "${KIND_CLUSTER_NAME}"; then
  echo "ERROR: kind cluster '${KIND_CLUSTER_NAME}' not found."
  echo "Existing clusters:"
  kind get clusters || true
  exit 1
fi

echo "Building ${SAMPLE_FULL_IMAGE}..."
docker build -t "${SAMPLE_FULL_IMAGE}" 40-poc-apps/sample-app

echo "Loading image into kind cluster: ${KIND_CLUSTER_NAME}"
kind load docker-image "${SAMPLE_FULL_IMAGE}" --name "${KIND_CLUSTER_NAME}"

echo "Done."
