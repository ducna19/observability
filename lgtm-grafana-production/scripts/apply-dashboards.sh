#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl -n observability create configmap lgtm-stack-overview-dashboard \
  --from-file=lgtm-stack-overview.json="${ROOT_DIR}/dashboards/lgtm-stack-overview.json" \
  --dry-run=client \
  -o yaml |
  kubectl label --local -f - \
    grafana_dashboard=1 \
    -o yaml |
  kubectl annotate --local -f - \
    grafana_folder="Stack Overview" \
    -o yaml |
  kubectl apply -f -

echo "Applied LGTM Grafana dashboard."
