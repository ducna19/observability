#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="${CLUSTER_NAME:-lgtm-multinode}"
CONFIG_FILE="${ROOT_DIR}/kind/lgtm-multinode.yaml"

MAX_USER_INSTANCES="$(cat /proc/sys/fs/inotify/max_user_instances 2>/dev/null || echo 0)"
if [ "${MAX_USER_INSTANCES}" -lt 512 ]; then
  echo "Increasing inotify limits for multi-node Kind..."
  sudo -n sysctl -w fs.inotify.max_user_instances=1024 fs.inotify.max_user_watches=1048576 >/dev/null
fi

if kind get clusters | grep -qx "${CLUSTER_NAME}"; then
  echo "Kind cluster '${CLUSTER_NAME}' already exists."
else
  kind create cluster --config "${CONFIG_FILE}"
fi

kubectl config use-context "kind-${CLUSTER_NAME}"
kubectl get nodes -o wide
