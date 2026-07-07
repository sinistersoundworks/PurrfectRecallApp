#!/usr/bin/env bash
# Start the FastAPI backend in the background (native apps depend on this).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

HOST="${STUDYWEB_HOST:-127.0.0.1}"
API_PORT="${STUDYWEB_API_PORT:-8000}"
DEV_DIR="${ROOT}/.dev"

if ! command -v uv &>/dev/null; then
  echo "Error: uv is required. Install from https://docs.astral.sh/uv/"
  exit 1
fi

mkdir -p "$DEV_DIR"

if [[ -f "${DEV_DIR}/backend.pid" ]] && kill -0 "$(cat "${DEV_DIR}/backend.pid")" 2>/dev/null; then
  echo "API already running (pid $(cat "${DEV_DIR}/backend.pid"))."
else
  echo "Starting API → http://${HOST}:${API_PORT}"
  nohup uv run uvicorn app.main:app --host "$HOST" --port "$API_PORT" \
    >"${DEV_DIR}/backend.log" 2>&1 &
  echo $! >"${DEV_DIR}/backend.pid"
  sleep 0.5
fi

echo "API docs: http://${HOST}:${API_PORT}/docs"
echo "Log:      ${DEV_DIR}/backend.log"
