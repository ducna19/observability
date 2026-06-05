#!/usr/bin/env bash
set -euo pipefail

helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add signoz https://charts.signoz.io
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts

helm repo update

echo "Helm repos added."
