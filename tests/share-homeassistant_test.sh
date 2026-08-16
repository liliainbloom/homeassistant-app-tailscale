#!/usr/bin/env bash
set -Eeuo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TESTS_DIR
REPOSITORY_DIR="$(cd "${TESTS_DIR}/.." && pwd)"
readonly REPOSITORY_DIR
readonly HARNESS="${TESTS_DIR}/fixtures/share-homeassistant_harness.sh"
readonly TAILSCALE_MOCK="${TESTS_DIR}/fixtures/tailscale_mock.sh"
SHARE_RUN_SCRIPT="${SHARE_RUN_SCRIPT:-${REPOSITORY_DIR}/tailscale/rootfs/etc/s6-overlay/s6-rc.d/share-homeassistant/run}"
readonly SHARE_RUN_SCRIPT
TEST_ROOT="$(mktemp -d)"
readonly TEST_ROOT

trap 'rm -rf "${TEST_ROOT}"' EXIT

declare CASE_DIR
declare CASE_EXIT

fail() {
  printf 'not ok - %s\n' "$1" >&2
  if [[ -n "${CASE_DIR:-}" && -f "${CASE_DIR}/output.log" ]]; then
    sed 's/^/  /' "${CASE_DIR}/output.log" >&2
  fi
  exit 1
}

assert_exit() {
  [[ "${CASE_EXIT}" == "$1" ]] || fail "expected exit $1, got ${CASE_EXIT}"
}

assert_contains() {
  grep -Fq -- "$1" "$2" || fail "expected '$1' in $2"
}

assert_empty() {
  [[ ! -s "$1" ]] || fail "expected $1 to be empty"
}

assert_ready() {
  [[ -s "${CASE_DIR}/ready.log" ]] || fail "service did not notify readiness"
}

run_case() {
  local name="$1"
  local plain_status="$2"
  local forwarded_status="$3"
  local core_ssl="$4"

  CASE_DIR="${TEST_ROOT}/${name}"
  mkdir -p "${CASE_DIR}"
  touch "${CASE_DIR}/tailscale.log"

  set +e
  RUN_SCRIPT="${SHARE_RUN_SCRIPT}" \
    READY_LOG="${CASE_DIR}/ready.log" \
    TAILSCALE_LOG="${CASE_DIR}/tailscale.log" \
    TAILSCALE_CLI="${TAILSCALE_MOCK}" \
    PLAIN_STATUS="${plain_status}" \
    FORWARDED_STATUS="${forwarded_status}" \
    CORE_SSL="${core_ssl}" \
    bash "${HARNESS}" >"${CASE_DIR}/output.log" 2>&1
  CASE_EXIT=$?
  set -e
}

run_case http_success 200 200 false
assert_exit 0
assert_ready
assert_contains \
  "serve --bg=false --https=443 --set-path=/ http://127.0.0.1:8123" \
  "${CASE_DIR}/tailscale.log"
printf 'ok - HTTP backend accepted\n'

run_case https_success 200 200 true
assert_exit 0
assert_ready
assert_contains \
  "serve --bg=false --https=443 --set-path=/ https+insecure://127.0.0.1:8123" \
  "${CASE_DIR}/tailscale.log"
assert_contains "Home Assistant is using SSL" "${CASE_DIR}/output.log"
printf 'ok - HTTPS backend accepted\n'

run_case unavailable 000 200 false
assert_exit 0
assert_ready
assert_contains "HTTP status 000" "${CASE_DIR}/output.log"
assert_contains \
  "serve --bg=false --https=443 --set-path=/ http://127.0.0.1:8123" \
  "${CASE_DIR}/tailscale.log"
printf 'ok - unavailable backend remains recoverable\n'

run_case proxy_rejected 200 400 false
assert_exit 1
assert_ready
assert_empty "${CASE_DIR}/tailscale.log"
assert_contains \
  "Home Assistant rejected the reverse-proxy test (HTTP 400)" \
  "${CASE_DIR}/output.log"
assert_contains "Trust X-Forwarded-For" "${CASE_DIR}/output.log"
assert_contains "127.0.0.1" "${CASE_DIR}/output.log"
assert_contains "confirm the pending HTTP configuration" "${CASE_DIR}/output.log"
printf 'ok - rejected proxy gets actionable guidance\n'

printf 'All 4 share-homeassistant regression tests passed.\n'
