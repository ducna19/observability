#!/usr/bin/env bash
set -euo pipefail

kubectl -n poc-apps port-forward svc/sample-api 18080:8080
