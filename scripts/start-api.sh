#!/usr/bin/env bash
# Start the FastAPI backend in the background (native apps depend on this).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
API_TRACE_ROOT="$ROOT"
# shellcheck source=scripts/api-trace.sh
source "${ROOT}/scripts/api-trace.sh"

export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH:-/usr/bin:/bin:/usr/sbin:/sbin}"

HOST="${STUDYWEB_HOST:-127.0.0.1}"
API_PORT="${STUDYWEB_API_PORT:-8000}"
DEV_DIR="${ROOT}/.dev"
HEALTH_URL="http://${HOST}:${API_PORT}/"
PID_FILE="${DEV_DIR}/backend.pid"
UVICORN="${ROOT}/.venv/bin/uvicorn"

if ! command -v uv &>/dev/null; then
  echo "Error: uv is required. Install from https://docs.astral.sh/uv/"
  exit 1
fi

mkdir -p "$DEV_DIR"

port_pid() {
  lsof -ti ":${API_PORT}" 2>/dev/null | head -1 || true
}

write_pid() {
  local pid
  pid="$(port_pid)"
  if [[ -n "$pid" ]]; then
    echo "$pid" >"$PID_FILE"
  fi
}

api_trace "START-API invoked"
api_trace_port "$API_PORT"

# Healthy server on the port? Done.
if curl -sf "$HEALTH_URL" >/dev/null 2>&1; then
  write_pid
  api_trace "SKIP — already healthy pid=$(cat "$PID_FILE" 2>/dev/null || echo none)"
  echo "API already running → ${HEALTH_URL}"
  exit 0
fi

# Stale pid / dead server — clean up port before restart.
rm -f "$PID_FILE"
"$(dirname "$0")/stop-api.sh" >/dev/null 2>&1 || true

if [[ ! -x "$UVICORN" ]]; then
  echo "Installing Python deps..."
  uv sync
fi

echo "Starting API → ${HEALTH_URL}"
nohup "$UVICORN" app.main:app --host "$HOST" --port "$API_PORT" \
  >>"${DEV_DIR}/backend.log" 2>&1 < /dev/null &

for _ in $(seq 1 40); do
  if curl -sf "$HEALTH_URL" >/dev/null 2>&1; then
    write_pid
    api_trace "ready pid=$(cat "$PID_FILE")"
    api_trace_port "$API_PORT"
    echo "API ready (pid $(cat "$PID_FILE"))"
    echo "API docs: http://${HOST}:${API_PORT}/docs"
    echo "Log:      ${DEV_DIR}/backend.log"
    exit 0
  fi
  sleep 0.25
done

echo "Error: API did not become ready on port ${API_PORT}." >&2
tail -15 "${DEV_DIR}/backend.log" 2>/dev/null >&2 || true
exit 1
