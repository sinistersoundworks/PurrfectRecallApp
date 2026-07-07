#!/usr/bin/env bash
# Shared API lifecycle tracing — append to .dev/api-trace.log
api_trace() {
  local root="${API_TRACE_ROOT:-}"
  if [[ -z "$root" ]]; then
    root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  fi
  local dev_dir="${root}/.dev"
  local log="${dev_dir}/api-trace.log"
  mkdir -p "$dev_dir"
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local ppid_cmd=""
  if [[ -n "${PPID:-}" ]]; then
    ppid_cmd="$(ps -p "$PPID" -o command= 2>/dev/null | sed 's/^[[:space:]]*//' || echo "?")"
  fi
  printf '[%s] %s | ppid=%s (%s)\n' "$ts" "$*" "${PPID:-?}" "$ppid_cmd" >>"$log"
}

api_trace_port() {
  local port="${1:-8000}"
  local pids
  pids="$(lsof -ti ":${port}" 2>/dev/null | tr '\n' ' ' | sed 's/ $//' || true)"
  if [[ -z "$pids" ]]; then
    api_trace "port :${port} — no listener"
    return
  fi
  local detail=""
  for pid in $pids; do
    local cmd
    cmd="$(ps -p "$pid" -o command= 2>/dev/null | sed 's/^[[:space:]]*//' || echo "?")"
    detail+=" pid=${pid} (${cmd});"
  done
  api_trace "port :${port} —${detail}"
}
