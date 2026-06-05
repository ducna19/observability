#!/usr/bin/env bash
set -euo pipefail

IMAGE="observability-sample-api:0.1.0"

echo "Building ${IMAGE} for minikube docker env..."
eval "$(minikube docker-env)"
docker build -t "${IMAGE}" 40-poc-apps/sample-app
echo "Built ${IMAGE} inside minikube docker env."
