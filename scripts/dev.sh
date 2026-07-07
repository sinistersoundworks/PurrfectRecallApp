#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

HOST="${STUDYWEB_HOST:-127.0.0.1}"
API_PORT="${STUDYWEB_API_PORT:-8000}"
FRONTEND_PORT="${STUDYWEB_FRONTEND_PORT:-5500}"

BACKEND_PID=""
FRONTEND_PID=""

cleanup() {
  echo ""
  echo "Shutting down..."
  if [[ -n "$BACKEND_PID" ]]; then
    kill "$BACKEND_PID" 2>/dev/null || true
    wait "$BACKEND_PID" 2>/dev/null || true
  fi
  if [[ -n "$FRONTEND_PID" ]]; then
    kill "$FRONTEND_PID" 2>/dev/null || true
    wait "$FRONTEND_PID" 2>/dev/null || true
  fi
  exit 0
}

trap cleanup SIGINT SIGTERM

if ! command -v uv &>/dev/null; then
  echo "Error: uv is required. Install from https://docs.astral.sh/uv/"
  exit 1
fi

echo "Starting backend  → http://${HOST}:${API_PORT}"
uv run uvicorn app.main:app --reload --host "$HOST" --port "$API_PORT" &
BACKEND_PID=$!

echo "Starting frontend → http://${HOST}:${FRONTEND_PORT}"
(
  cd frontend
  uv run python -m http.server "$FRONTEND_PORT" --bind "$HOST"
) &
FRONTEND_PID=$!

echo ""
echo "Purrfect Recall is running:"
echo "  App:      http://${HOST}:${FRONTEND_PORT}"
echo "  API:      http://${HOST}:${API_PORT}"
echo "  API docs: http://${HOST}:${API_PORT}/docs"
echo ""
echo "Press Ctrl+C to stop both servers."

wait "$BACKEND_PID" "$FRONTEND_PID"
