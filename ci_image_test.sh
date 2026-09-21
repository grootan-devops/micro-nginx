#!/usr/bin/env bash

set -euo pipefail

fail() {
  printf 'image test failed: %s\n' "$1" >&2
  exit 1
}

[[ "$(id -u)" == "10001" ]] || fail "expected UID 10001, got $(id -u)"
[[ "$(id -g)" == "10001" ]] || fail "expected GID 10001, got $(id -g)"
nginx -version 2>&1 | grep -q '1\.31\.6' || fail "unexpected Nginx version"
nginx -g 'daemon off;' -t

log_dir="${TMPDIR:-/tmp}/nginx-test"
mkdir -p "${log_dir}"
nginx -g 'daemon off;' >"${log_dir}/stdout.log" 2>"${log_dir}/stderr.log" &
nginx_pid=$!
cleanup() {
  kill "${nginx_pid}" 2>/dev/null || true
  wait "${nginx_pid}" 2>/dev/null || true
}
trap cleanup EXIT
sleep 2
kill -0 "${nginx_pid}" || fail "Nginx exited during startup"
! grep -Eiq 'emerg|alert|crit' "${log_dir}/stderr.log" || fail "Nginx emitted a critical startup error"
