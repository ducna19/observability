#!/usr/bin/env bash
set -euo pipefail

CONTEXT="${CONTEXT:-kind-lgtm-multinode}"
NAMESPACE="${NAMESPACE:-observability}"
LOCAL_PORT="${LOCAL_PORT:-3001}"

kubectl config use-context "${CONTEXT}" >/dev/null

echo "Grafana: http://127.0.0.1:${LOCAL_PORT}"
echo "User: admin"
echo "Pass: admin-learning-lab-change-me"
kubectl -n "${NAMESPACE}" port-forward svc/kps-grafana "${LOCAL_PORT}:80"
