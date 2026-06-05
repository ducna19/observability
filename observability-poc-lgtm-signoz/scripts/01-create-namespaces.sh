#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f 00-namespaces/namespaces.yaml
kubectl get ns obs-lgtm obs-signoz obs-router poc-apps

echo "Namespaces created."
