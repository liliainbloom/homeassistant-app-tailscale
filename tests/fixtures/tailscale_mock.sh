#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${1:-}" == "status" ]]; then
  printf '{"Self":{"CapMap":{"https":true,"funnel":true}}}\n'
  exit 0
fi

: "${TAILSCALE_LOG:?TAILSCALE_LOG must be set}"
printf '%s\n' "$*" >>"${TAILSCALE_LOG}"
