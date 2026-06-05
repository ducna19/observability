#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f 00-namespaces/namespaces.yaml

# Nếu cluster có storageClass cụ thể, có thể set:
# export STORAGE_CLASS=standard
STORAGE_CLASS="${STORAGE_CLASS:-}"

VALUES_FILE="/tmp/signoz-values-rendered.yaml"
cp 20-signoz/signoz-values.yaml "${VALUES_FILE}"

if [[ -n "${STORAGE_CLASS}" ]]; then
  echo "Using STORAGE_CLASS=${STORAGE_CLASS}"
  python3 - <<PY
from pathlib import Path
p = Path("${VALUES_FILE}")
s = p.read_text()
s = s.replace('storageClass: ""', 'storageClass: "${STORAGE_CLASS}"')
p.write_text(s)
PY
fi

echo "Installing SigNoz..."
helm upgrade --install signoz signoz/signoz \
  --namespace obs-signoz \
  --create-namespace \
  -f "${VALUES_FILE}" \
  --wait \
  --timeout 45m

echo "SigNoz installed."
kubectl -n obs-signoz get pods
kubectl -n obs-signoz get svc
