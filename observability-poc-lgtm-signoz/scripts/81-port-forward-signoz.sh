#!/usr/bin/env bash
set -euo pipefail

echo "Trying to port-forward SigNoz service to http://localhost:8080"

if kubectl -n obs-signoz get svc signoz >/dev/null 2>&1; then
  kubectl -n obs-signoz port-forward svc/signoz 8080:8080
else
  echo "Service 'signoz' not found. Available services:"
  kubectl -n obs-signoz get svc
  echo
  echo "Try one of these manually, depending on chart service name:"
  echo "  kubectl -n obs-signoz port-forward svc/<signoz-frontend-or-query-service> 8080:8080"
  exit 1
fi
