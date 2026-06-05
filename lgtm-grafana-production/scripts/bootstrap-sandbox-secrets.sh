#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "${ROOT_DIR}/namespaces.yaml"
kubectl apply -f "${ROOT_DIR}/manifests/minio-sandbox.yaml"
kubectl apply -f "${ROOT_DIR}/secrets/object-storage.example.yaml"
kubectl apply -f "${ROOT_DIR}/secrets/grafana-admin.example.yaml"
kubectl apply -f "${ROOT_DIR}/secrets/grafana-oauth.example.yaml"

kubectl -n observability rollout status statefulset/lgtm-minio --timeout=5m
kubectl -n observability wait --for=condition=complete job/lgtm-minio-create-buckets --timeout=5m

echo "Sandbox namespaces, MinIO, buckets, and demo secrets applied."
echo "These secrets are for learning only. Replace them before any real production deployment."
