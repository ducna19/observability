#!/usr/bin/env bash
set -euo pipefail

kubectl -n signoz-production patch deployment signoz-otel-collector \
  --type='json' \
  -p='[
    {
      "op": "replace",
      "path": "/spec/template/spec/containers/0/args",
      "value": ["--config=/conf/otel-collector-config.yaml"]
    }
  ]'

kubectl -n signoz-production rollout status deployment/signoz-otel-collector --timeout=5m
