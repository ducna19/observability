#!/usr/bin/env bash
set -euo pipefail

echo "=== Helm releases ==="
helm -n signoz-production list || true
helm -n signoz-production-agents list || true

echo
echo "=== SigNoz core pods ==="
kubectl -n signoz-production get pods -o wide || true

echo
echo "=== SigNoz agent pods ==="
kubectl -n signoz-production-agents get pods -o wide || true

echo
echo "=== Services ==="
kubectl -n signoz-production get svc || true
kubectl -n signoz-production-agents get svc || true

echo
echo "=== PVCs ==="
kubectl -n signoz-production get pvc || true
