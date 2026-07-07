#!/usr/bin/env bash
# Stop the background API started by scripts/start-api.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_TRACE_ROOT="$ROOT"
# shellcheck source=scripts/api-trace.sh
source "${ROOT}/scripts/api-trace.sh"

DEV_DIR="${ROOT}/.dev"
API_PORT="${STUDYWEB_API_PORT:-8000}"

api_trace "STOP-API invoked"
api_trace_port "$API_PORT"

kill_port() {
  local port="$1"
  local pids
  pids="$(lsof -ti ":${port}" 2>/dev/null || true)"
  if [[ -z "$pids" ]]; then
    return 0
  fi
  for pid in $pids; do
    local cmd
    cmd="$(ps -p "$pid" -o command= 2>/dev/null | sed 's/^[[:space:]]*//' || echo "?")"
    api_trace "kill port :${port} pid=${pid} (${cmd})"
  done
  echo "Stopping process(es) on port ${port}..."
  # shellcheck disable=SC2086
  kill $pids 2>/dev/null || true
  sleep 0.3
  pids="$(lsof -ti ":${port}" 2>/dev/null || true)"
  if [[ -n "$pids" ]]; then
    api_trace "kill -9 port :${port} pids=${pids}"
    # shellcheck disable=SC2086
    kill -9 $pids 2>/dev/null || true
  fi
}

# Port listener is authoritative; pid file may be stale.
kill_port "$API_PORT"
rm -f "${DEV_DIR}/backend.pid" "${DEV_DIR}/api-supervisor.pid"
api_trace_port "$API_PORT"

echo "API stopped."
