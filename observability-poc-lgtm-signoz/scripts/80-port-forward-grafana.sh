#!/usr/bin/env bash
set -euo pipefail

echo "Grafana: http://localhost:3000"
echo "User: admin"
echo "Pass: admin-poc-change-me"
kubectl -n obs-lgtm port-forward svc/kps-grafana 3000:80
