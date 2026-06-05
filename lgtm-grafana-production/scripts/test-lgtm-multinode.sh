#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-observability}"
AGENT_NAMESPACE="${AGENT_NAMESPACE:-observability-agents}"
CONTEXT="${CONTEXT:-kind-lgtm-multinode}"

kubectl config use-context "${CONTEXT}" >/dev/null

echo "=== Nodes ==="
kubectl get nodes -o wide

echo
echo "=== LGTM pods by node ==="
kubectl -n "${NAMESPACE}" get pods -o wide

echo
echo "=== Alloy agents by node ==="
kubectl -n "${AGENT_NAMESPACE}" get pods -o wide

echo
echo "=== Mimir query smoke ==="
kubectl run -n "${NAMESPACE}" lgtm-mimir-smoke --rm -i --restart=Never \
  --image=curlimages/curl:8.8.0 --quiet -- \
  curl -fsS -H 'X-Scope-OrgID: production' \
  'http://mimir-gateway.observability.svc.cluster.local/prometheus/api/v1/query?query=count(up)' \
  | sed 's/,"/,\n  "/g'

echo
echo "=== Loki query smoke ==="
kubectl run -n "${NAMESPACE}" lgtm-loki-smoke --rm -i --restart=Never \
  --image=curlimages/curl:8.8.0 --quiet -- \
  curl -fsS -G \
  'http://loki-gateway.observability.svc.cluster.local/loki/api/v1/query_range' \
  --data-urlencode 'query={namespace="observability"}' \
  --data-urlencode 'limit=3' \
  | sed 's/,"/,\n  "/g'

echo
echo "=== Tempo OTLP smoke ==="
TRACE_ID="$(printf '%032x' "$(date +%s)")"
SPAN_ID="$(printf '%016x' "$(( $(date +%s) % 4294967295 ))")"
START_NS="$(date +%s%N)"
END_NS="$((START_NS + 220000000))"

kubectl run -n "${NAMESPACE}" lgtm-tempo-smoke --rm -i --restart=Never \
  --image=curlimages/curl:8.8.0 --quiet -- \
  curl -fsS -X POST 'http://alloy-gateway.observability.svc.cluster.local:4318/v1/traces' \
  -H 'Content-Type: application/json' \
  -d "{\"resourceSpans\":[{\"resource\":{\"attributes\":[{\"key\":\"service.name\",\"value\":{\"stringValue\":\"lgtm-multinode-smoke\"}},{\"key\":\"deployment.environment\",\"value\":{\"stringValue\":\"production-lab\"}}]},\"scopeSpans\":[{\"scope\":{\"name\":\"codex-lgtm-test\"},\"spans\":[{\"traceId\":\"${TRACE_ID}\",\"spanId\":\"${SPAN_ID}\",\"name\":\"GET /lgtm-multinode-smoke\",\"kind\":2,\"startTimeUnixNano\":\"${START_NS}\",\"endTimeUnixNano\":\"${END_NS}\",\"attributes\":[{\"key\":\"http.method\",\"value\":{\"stringValue\":\"GET\"}},{\"key\":\"http.route\",\"value\":{\"stringValue\":\"/lgtm-multinode-smoke\"}},{\"key\":\"http.status_code\",\"value\":{\"intValue\":200}}],\"status\":{\"code\":1}}]}]}]}"

sleep 10

kubectl run -n "${NAMESPACE}" lgtm-tempo-query --rm -i --restart=Never \
  --image=curlimages/curl:8.8.0 --quiet -- \
  curl -fsS "http://tempo-query-frontend.observability.svc.cluster.local:3200/api/traces/${TRACE_ID}" \
  | sed 's/,"/,\n  "/g'

echo
echo "Trace ID: ${TRACE_ID}"
