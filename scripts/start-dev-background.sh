#!/usr/bin/env bash
# Start API + frontend in the background (used by `make start` / `make rebuild`)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

HOST="${STUDYWEB_HOST:-127.0.0.1}"
API_PORT="${STUDYWEB_API_PORT:-8000}"
FRONTEND_PORT="${STUDYWEB_FRONTEND_PORT:-5500}"
DEV_DIR="${ROOT}/.dev"

if ! command -v uv &>/dev/null; then
  echo "Error: uv is required. Install from https://docs.astral.sh/uv/"
  exit 1
fi

mkdir -p "$DEV_DIR"

if [[ -f "${DEV_DIR}/backend.pid" ]] && kill -0 "$(cat "${DEV_DIR}/backend.pid")" 2>/dev/null \
   && curl -sf "http://${HOST}:${API_PORT}/" >/dev/null 2>&1; then
  echo "Backend already running (pid $(cat "${DEV_DIR}/backend.pid"))."
else
  rm -f "${DEV_DIR}/backend.pid"
  echo "Starting backend → http://${HOST}:${API_PORT}"
  UVICORN="${ROOT}/.venv/bin/uvicorn"
  [[ -x "$UVICORN" ]] || uv sync
  nohup "$UVICORN" app.main:app --host "$HOST" --port "$API_PORT" \
    >>"${DEV_DIR}/backend.log" 2>&1 < /dev/null &
  sleep 0.5
  pid="$(lsof -ti ":${API_PORT}" 2>/dev/null | head -1 || true)"
  if [[ -n "$pid" ]]; then
    echo "$pid" >"${DEV_DIR}/backend.pid"
  fi
fi

if [[ -f "${DEV_DIR}/frontend.pid" ]] && kill -0 "$(cat "${DEV_DIR}/frontend.pid")" 2>/dev/null; then
  echo "Frontend already running (pid $(cat "${DEV_DIR}/frontend.pid"))."
else
  echo "Starting frontend → http://${HOST}:${FRONTEND_PORT}"
  (
    cd frontend
    nohup uv run python -m http.server "$FRONTEND_PORT" --bind "$HOST" \
      >"${DEV_DIR}/frontend.log" 2>&1 &
    echo $! >"${DEV_DIR}/frontend.pid"
  )
fi

sleep 1

echo ""
echo "Purrfect Recall is running:"
echo "  App:      http://${HOST}:${FRONTEND_PORT}"
echo "  API:      http://${HOST}:${API_PORT}"
echo "  API docs: http://${HOST}:${API_PORT}/docs"
echo ""
echo "Logs:  ${DEV_DIR}/backend.log  ${DEV_DIR}/frontend.log"
echo "Stop:  make stop"
echo "Tip:   make dev for foreground servers with --reload"
