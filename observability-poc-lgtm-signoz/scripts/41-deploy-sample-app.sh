#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f 00-namespaces/namespaces.yaml
kubectl apply -f 40-poc-apps/k8s/deployment.yaml
kubectl apply -f 40-poc-apps/k8s/servicemonitor.yaml

kubectl -n poc-apps rollout status deploy/sample-api --timeout=5m
kubectl -n poc-apps get pods -l app.kubernetes.io/name=sample-api
echo "Sample app deployed."
