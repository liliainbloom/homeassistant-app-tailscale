#!/usr/bin/env bash
set -Eeuo pipefail

: "${RUN_SCRIPT:?RUN_SCRIPT must point to the share-homeassistant run script}"
: "${TAILSCALE_LOG:?TAILSCALE_LOG must be set}"

if [[ "${PRESERVE_READY_FD:-false}" != true ]]; then
  : "${READY_LOG:?READY_LOG must be set}"
  exec 3>"${READY_LOG}"
fi

bashio::config() {
  case "$1" in
    share_homeassistant)
      printf '%s' "${SHARE_HOMEASSISTANT:-serve}"
      ;;
    share_on_port)
      printf '%s' "${SHARE_ON_PORT:-443}"
      ;;
    *)
      return 1
      ;;
  esac
}

bashio::config.equals() {
  [[ "$(bashio::config "$1")" == "$2" ]]
}

bashio::core.port() {
  printf '%s' "${CORE_PORT:-8123}"
}

bashio::core.ssl() {
  printf '%s' "${CORE_SSL:-false}"
}

bashio::var.true() {
  case "${1,,}" in
    1 | true | yes | on)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

bashio::log.info() {
  printf 'INFO: %s\n' "$*"
}

bashio::log.notice() {
  printf 'NOTICE: %s\n' "$*"
}

bashio::log.warning() {
  printf 'WARNING: %s\n' "$*"
}

bashio::exit.nok() {
  printf 'FATAL: %s\n' "$*" >&2
  exit 1
}

jq() {
  cat >/dev/null
}

curl() {
  local arg
  local forwarded=false
  local status="${PLAIN_STATUS:-200}"

  for arg in "$@"; do
    if [[ "${arg}" == "X-Forwarded-For: 127.0.0.1" ]]; then
      forwarded=true
      break
    fi
  done

  if [[ "${forwarded}" == true ]]; then
    status="${FORWARDED_STATUS:-200}"
  fi

  printf '%s' "${status}"
  [[ "${status}" != "000" ]]
}

sleep() {
  :
}

# shellcheck source=/dev/null
source "${RUN_SCRIPT}"
