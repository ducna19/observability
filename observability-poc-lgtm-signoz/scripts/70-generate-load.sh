#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:18080}"
DURATION_SECONDS="${DURATION_SECONDS:-300}"
SLEEP_SECONDS="${SLEEP_SECONDS:-0.2}"
MODE="${MODE:-full}"

echo "Generating load against ${BASE_URL} for ${DURATION_SECONDS}s"
echo "Mode: ${MODE}"
echo "Make sure sample app is port-forwarded:"
echo "  ./scripts/60-port-forward-sample-app.sh"

END=$((SECONDS + DURATION_SECONDS))
while [[ ${SECONDS} -lt ${END} ]]; do
  if [[ "${MODE}" == "legacy" ]]; then
    curl -fsS "${BASE_URL}/" >/dev/null || true
    curl -fsS "${BASE_URL}/work" >/dev/null || true

    # Tạo lỗi và latency có kiểm soát.
    if (( RANDOM % 10 < 2 )); then
      curl -fsS "${BASE_URL}/slow" >/dev/null || true
    fi

    if (( RANDOM % 10 < 1 )); then
      curl -s "${BASE_URL}/error" >/dev/null || true
    fi
  else
    curl -fsS "${BASE_URL}/checkout?scenario=random" >/dev/null || true

    if (( RANDOM % 10 < 3 )); then
      curl -fsS "${BASE_URL}/checkout?scenario=slow" >/dev/null || true
    fi

    if (( RANDOM % 10 < 2 )); then
      curl -s "${BASE_URL}/checkout?scenario=payment_error" >/dev/null || true
    fi

    if (( RANDOM % 10 < 1 )); then
      curl -s "${BASE_URL}/checkout?scenario=inventory_error" >/dev/null || true
    fi

    if (( RANDOM % 20 < 1 )); then
      curl -s "${BASE_URL}/checkout?scenario=exception" >/dev/null || true
    fi
  fi

  sleep "${SLEEP_SECONDS}"
done

echo "Load generation completed."
