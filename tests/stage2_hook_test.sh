#!/usr/bin/env bash
set -Eeuo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TESTS_DIR
REPOSITORY_DIR="$(cd "${TESTS_DIR}/.." && pwd)"
readonly REPOSITORY_DIR
readonly HARNESS="${TESTS_DIR}/fixtures/stage2_hook_harness.sh"
STAGE2_HOOK_SCRIPT="${STAGE2_HOOK_SCRIPT:-${REPOSITORY_DIR}/tailscale/rootfs/etc/s6-overlay/scripts/stage2_hook.sh}"
S6_FIXTURE_SOURCE="${S6_FIXTURE_SOURCE:-${REPOSITORY_DIR}/tailscale/rootfs/etc/s6-overlay}"
S6_BASE_SOURCE="${S6_BASE_SOURCE:-/package/admin/s6-overlay/etc/s6-rc/sources}"
readonly STAGE2_HOOK_SCRIPT S6_FIXTURE_SOURCE S6_BASE_SOURCE
TEST_ROOT="$(mktemp -d)"
readonly TEST_ROOT
trap 'rm -rf -- "${TEST_ROOT:?}"' EXIT

readonly DEFAULT_OPTIONS='{"userspace_networking":false,"accept_dns":true,"accept_routes":false,"advertise_routes":[],"taildrop":false,"share_homeassistant":"disabled"}'
readonly BUNDLE='/etc/s6-overlay/user-bundles.d/user/contents.d'
readonly SERVICES='/etc/s6-overlay/s6-rc.d'
declare CASE_DIR

fail() {
  printf 'not ok - %s\n' "$1" >&2
  if [[ -n "${CASE_DIR:-}" && -f "${CASE_DIR}/output.log" ]]; then
    sed 's/^/  /' "${CASE_DIR}/output.log" >&2
  fi
  exit 1
}

assert_present() {
  [[ -f "${CASE_DIR}$1" ]] || fail "expected $1 to remain enabled"
}

assert_absent() {
  [[ ! -e "${CASE_DIR}$1" ]] || fail "expected $1 to be disabled"
}

run_case() {
  local name="$1"
  local overrides="$2"
  local dns_locals="${3-}"
  local options

  options=$(jq -c --argjson overrides "${overrides}" '. + $overrides' <<<"${DEFAULT_OPTIONS}")
  CASE_DIR="${TEST_ROOT}/${name}"
  mkdir -p "${CASE_DIR}/etc"
  cp -R "${S6_FIXTURE_SOURCE}" "${CASE_DIR}/etc/s6-overlay"
  : >"${CASE_DIR}/updates.jsonl"

  if ! CASE_ROOT="${CASE_DIR}" RUN_SCRIPT="${STAGE2_HOOK_SCRIPT}" \
    OPTIONS_JSON="${options}" DNS_LOCALS="${dns_locals}" \
    bash "${HARNESS}" >"${CASE_DIR}/output.log" 2>&1; then
    fail "startup hook failed for ${name}"
  fi

  assert_absent "${SERVICES}/user"

  # The image includes the actual S6 compiler and base definitions. CI's host
  # runner still checks pruning and migrations without requiring S6 packages.
  if command -v s6-rc-compile >/dev/null && [[ -d "${S6_BASE_SOURCE}" ]]; then
    if ! s6-rc-compile "${CASE_DIR}/compiled" \
      "${CASE_DIR}${SERVICES}" \
      "${CASE_DIR}/etc/s6-overlay/user-bundles.d" \
      "${S6_BASE_SOURCE}" >>"${CASE_DIR}/output.log" 2>&1; then
      fail "S6 dependency graph did not compile for ${name}"
    fi
  fi
}

run_case defaults '{}'
assert_present "${BUNDLE}/magicdns-ingress-proxy"
assert_present "${BUNDLE}/magicdns-proxies-reconfigurator"
assert_present "${BUNDLE}/forwarding"
assert_present "${BUNDLE}/mss-clamping"
assert_absent "${BUNDLE}/share-homeassistant"
assert_absent "${BUNDLE}/taildrop"
assert_absent "${SERVICES}/post-tailscaled/dependencies.d/protect-subnets"
assert_absent "${SERVICES}/post-tailscaled/dependencies.d/local-network"
printf 'ok - default startup preserves the expected services\n'

run_case userspace '{"userspace_networking":true,"accept_routes":true,"advertise_routes":["local_subnets"],"taildrop":true,"share_homeassistant":"serve"}'
assert_absent "${BUNDLE}/magicdns-ingress-proxy"
assert_absent "${BUNDLE}/magicdns-proxies-reconfigurator"
assert_absent "${BUNDLE}/forwarding"
assert_absent "${BUNDLE}/mss-clamping"
assert_absent "${SERVICES}/tailscaled/dependencies.d/magicdns-egress-proxy"
assert_absent "${SERVICES}/post-tailscaled/dependencies.d/protect-subnets"
assert_present "${SERVICES}/post-tailscaled/dependencies.d/local-network"
assert_present "${BUNDLE}/share-homeassistant"
assert_present "${BUNDLE}/taildrop"
printf 'ok - userspace mode prunes only kernel-network services\n'

run_case accept_dns_disabled '{"accept_dns":false,"accept_routes":true}'
assert_absent "${BUNDLE}/magicdns-proxies-reconfigurator"
assert_present "${BUNDLE}/magicdns-ingress-proxy"
assert_present "${SERVICES}/tailscaled/dependencies.d/magicdns-egress-proxy"
assert_present "${SERVICES}/post-tailscaled/dependencies.d/protect-subnets"
printf 'ok - disabling DNS acceptance keeps the ingress proxy\n'

run_case enabled_features '{"accept_routes":true,"advertise_routes":["local_subnets"],"taildrop":true,"share_homeassistant":"funnel"}'
assert_present "${SERVICES}/post-tailscaled/dependencies.d/protect-subnets"
assert_present "${SERVICES}/post-tailscaled/dependencies.d/local-network"
assert_present "${BUNDLE}/share-homeassistant"
assert_present "${BUNDLE}/taildrop"
printf 'ok - enabled routing, sharing, and Taildrop remain enabled\n'

run_case invalid_dns_loop '{}' 'dns://100.100.100.100'
assert_absent "${BUNDLE}/magicdns-ingress-proxy"
assert_absent "${BUNDLE}/magicdns-proxies-reconfigurator"
assert_absent "${BUNDLE}/forwarding"
if ! jq -se 'any(.[]; .name == "userspace_networking" and .value == "true")' \
  "${CASE_DIR}/updates.jsonl" >/dev/null; then
  fail 'invalid DNS configuration did not retain the safe fallback'
fi
printf 'ok - invalid MagicDNS loop retains the userspace fallback\n'

run_case legacy_options '{"proxy":true,"funnel":true,"proxy_and_funnel_port":8443,"tags":["tag:example"],"taildrive":{"addons":true,"addon_configs":false}}'
if ! jq -se '
  . as $updates |
  any(.[]; .name == "share_homeassistant" and .value == "funnel") and
  any(.[]; .name == "share_on_port" and .value == "^8443") and
  any(.[]; .name == "taildrive" and
    (.value | ltrimstr("^") | fromjson) == {local_apps: true, app_configs: false}) and
  any(.[]; .name == "advertise_tags" and
    (.value | ltrimstr("^") | fromjson) == ["tag:example"]) and
  all(["proxy", "funnel", "proxy_and_funnel_port", "tags"][];
    . as $name | any($updates[]; .name == $name and .value == ""))
  ' \
  "${CASE_DIR}/updates.jsonl" >/dev/null; then
  fail 'legacy options were not migrated through the supported app API'
fi
printf 'ok - legacy options retain their migrations through the app API\n'

printf 'All 6 startup regression tests passed.\n'
