#!/usr/bin/env bash
set -Eeuo pipefail

: "${CASE_ROOT:?CASE_ROOT must be set}"
: "${RUN_SCRIPT:?RUN_SCRIPT must be set}"
: "${OPTIONS_JSON:?OPTIONS_JSON must be set}"

bashio::app.options() {
  printf '%s' "${OPTIONS_JSON}"
}

bashio::app.option() {
  jq -cn --arg name "$1" --arg value "${2-}" \
    '{name: $name, value: $value}' >>"${CASE_ROOT}/updates.jsonl"
}

bashio::jq() {
  jq -r "$2" <<<"$1"
}

bashio::config() {
  jq -r ".${1} | if type == \"array\" then .[] else . end" <<<"${OPTIONS_JSON}"
}

bashio::config.false() {
  [[ "$(bashio::config "$1")" == false ]]
}

bashio::config.equals() {
  [[ "$(bashio::config "$1")" == "$2" ]]
}

bashio::var.true() {
  [[ "${1-}" == true ]]
}

bashio::var.false() {
  [[ "${1-}" == false ]]
}

bashio::var.equals() {
  [[ "$1" == "$2" ]]
}

bashio::var.has_value() {
  [[ -n "${1-}" && "${1-}" != null ]]
}

bashio::dns.locals() {
  printf '%s\n' "${DNS_LOCALS:-}"
}

bashio::log.info() {
  printf 'INFO: %s\n' "$*"
}

bashio::log.warning() {
  printf 'WARNING: %s\n' "$*"
}

# Redirect every removal into a fresh test-only filesystem. No live files or
# Supervisor APIs are used by this harness.
rm() {
  local path
  for path in "$@"; do
    case "${path}" in
      /etc/s6-overlay/*)
        command rm -- "${CASE_ROOT}${path}"
        ;;
      *)
        printf 'Unexpected removal target\n' >&2
        return 1
        ;;
    esac
  done
}

# shellcheck source=/dev/null
source "${RUN_SCRIPT}"
