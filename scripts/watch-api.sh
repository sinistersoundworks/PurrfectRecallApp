#!/usr/bin/env bash
# Poll :8000 every 2s; log transitions to api-trace.log (run in a separate terminal).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_TRACE_ROOT="$ROOT"
# shellcheck source=scripts/api-trace.sh
source "${ROOT}/scripts/api-trace.sh"

API_PORT="${STUDYWEB_API_PORT:-8000}"
HOST="${STUDYWEB_HOST:-127.0.0.1}"

api_trace "WATCH-API started (poll every 2s)"
state="unknown"

while true; do
  if curl -sf "http://${HOST}:${API_PORT}/" >/dev/null 2>&1; then
    if [[ "$state" != "up" ]]; then
      api_trace "WATCH — API came UP"
      api_trace_port "$API_PORT"
      state="up"
    fi
  else
    if [[ "$state" != "down" ]]; then
      api_trace "WATCH — API went DOWN"
      api_trace_port "$API_PORT"
      state="down"
    fi
  fi
  sleep 2
done
