#!/usr/bin/env bash
set -euo pipefail

echo "=== obs-lgtm pods ==="
kubectl -n obs-lgtm get pods || true

echo
echo "=== obs-signoz pods ==="
kubectl -n obs-signoz get pods || true

echo
echo "=== obs-router pods ==="
kubectl -n obs-router get pods || true

echo
echo "=== poc-apps pods ==="
kubectl -n poc-apps get pods || true

echo
echo "=== Services ==="
kubectl -n obs-lgtm get svc || true
kubectl -n obs-signoz get svc || true
kubectl -n obs-router get svc || true
kubectl -n poc-apps get svc || true
