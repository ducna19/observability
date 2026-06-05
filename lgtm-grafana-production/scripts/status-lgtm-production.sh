#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-observability}"
AGENT_NAMESPACE="${AGENT_NAMESPACE:-observability-agents}"

echo "=== Helm releases ==="
helm -n "${NAMESPACE}" list || true
helm -n "${AGENT_NAMESPACE}" list || true

echo
echo "=== Core pods ==="
kubectl -n "${NAMESPACE}" get pods -o wide || true

echo
echo "=== Agent pods ==="
kubectl -n "${AGENT_NAMESPACE}" get pods -o wide || true

echo
echo "=== Services ==="
kubectl -n "${NAMESPACE}" get svc || true
