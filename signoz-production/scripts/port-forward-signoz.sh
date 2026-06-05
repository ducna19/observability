#!/usr/bin/env bash
set -euo pipefail

LOCAL_PORT="${LOCAL_PORT:-8081}"
SERVICE_NAME="${SERVICE_NAME:-signoz}"

echo "SigNoz: http://127.0.0.1:${LOCAL_PORT}"
echo "First visit creates the admin account."
kubectl -n signoz-production port-forward "svc/${SERVICE_NAME}" "${LOCAL_PORT}:8080"
