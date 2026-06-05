#!/usr/bin/env bash
set -euo pipefail

echo "Uninstalling Helm releases..."
helm -n obs-router uninstall otel-poc-router || true
helm -n obs-signoz uninstall signoz || true
helm -n obs-lgtm uninstall mimir || true
helm -n obs-lgtm uninstall alloy || true
helm -n obs-lgtm uninstall tempo || true
helm -n obs-lgtm uninstall loki || true
helm -n obs-lgtm uninstall kps || true

echo "Deleting sample app manifests..."
kubectl delete -f 40-poc-apps/k8s/servicemonitor.yaml || true
kubectl delete -f 40-poc-apps/k8s/deployment.yaml || true

echo "PVCs are NOT deleted automatically."
echo "To delete namespaces and PVCs:"
echo "  kubectl delete ns obs-lgtm obs-signoz obs-router poc-apps"
