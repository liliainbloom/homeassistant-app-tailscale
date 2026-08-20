# Fork maintenance notes

This file records the baseline and review decisions used to create
liliainbloom's Fork. It is a point-in-time audit from **2026-08-09**; upstream
pull requests must be reviewed again if they change.

## Baseline

- The fork preserves the history and upgrade lineage of upstream release
  [`v0.28.1`](https://github.com/hassio-addons/app-tailscale/tree/v0.28.1).
- It includes upstream `main` through commit
  [`d491cfb`](https://github.com/hassio-addons/app-tailscale/commit/d491cfb8fd05e8eb5981f8ed3895a557809c4c2c),
  including Home Assistant base image `21.0.1` and Alpine 3.24 package updates.
- At the initial audit, Tailscale was pinned to `v1.102.2`, which was the
  release published on the
  [official stable package index](https://pkgs.tailscale.com/stable/) at that
  time. Subsequent dependency-only updates are recorded in the app changelog.
- The original [MIT license](LICENSE.md), copyright notice, commit authorship,
  and upstream attribution are retained.

## Open pull-request audit

All 18 pull requests that were open upstream at audit time were inspected for
their diffs, reviews, CI state, overlap, and runtime interactions.

| PR                                                              | Decision   | Reason and interaction notes                                                                                                                                                                                                                                                                                       |
| --------------------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [#585](https://github.com/hassio-addons/app-tailscale/pull/585) | Integrated | Aligns new-install defaults with stock Tailscale and migrates `tags` to `advertise_tags`. Existing installations already materialized the old defaults after upstream #541, so their behavior is preserved.                                                                                                        |
| [#605](https://github.com/hassio-addons/app-tailscale/pull/605) | Deferred   | Draft and non-mergeable. Its custom API helper adds substantial surface area, and the one-time notification marker would not correctly follow later key changes. Existing log warnings remain.                                                                                                                     |
| [#614](https://github.com/hassio-addons/app-tailscale/pull/614) | Deferred   | Draft cleanup that removes 25 logging workarounds. It is not needed for the Tailscale update and has a broad blast radius without a functional benefit.                                                                                                                                                            |
| [#662](https://github.com/hassio-addons/app-tailscale/pull/662) | Adapted    | Invalid Home Assistant local-DNS loops now enable userspace networking so the app can start. Ported into #667's replacement service graph, with an explicit in-process state update so dependency pruning cannot use stale configuration.                                                                          |
| [#663](https://github.com/hassio-addons/app-tailscale/pull/663) | Integrated | Adds local `OUTPUT` forwarding, fixing local tailnet targets such as AdGuard. Its rules coexist with #667's DNS-specific proxy chains.                                                                                                                                                                             |
| [#667](https://github.com/hassio-addons/app-tailscale/pull/667) | Integrated | Refactors MagicDNS proxies onto dynamic non-53 ports and reconfigures them from Tailscale `1.102` self-change events. All review fixes were included; explicit `log_upload` behavior from #681 was retained.                                                                                                       |
| [#669](https://github.com/hassio-addons/app-tailscale/pull/669) | Adapted    | Suppresses expected Supervisor probe output, but uses a function-scoped `LOG_FD=2` instead of the proposed `eval`, addressing the review's descriptor-validation concern without command-string evaluation.                                                                                                        |
| [#671](https://github.com/hassio-addons/app-tailscale/pull/671) | Integrated | Adds useful restart, example-configuration, and certificate-renewal guidance. Reconciled with #585's changed defaults.                                                                                                                                                                                             |
| [#673](https://github.com/hassio-addons/app-tailscale/pull/673) | Integrated | Forces reauthentication only when Tailscale reports a login-server change and hardens readiness handling, avoiding accidental reauthentication for unrelated failures.                                                                                                                                             |
| [#680](https://github.com/hassio-addons/app-tailscale/pull/680) | Integrated | Moves slow NetworkManager dispatcher work into an S6 FIFO listener. Included its readiness, shutdown, and logging follow-up fixes.                                                                                                                                                                                 |
| [#681](https://github.com/hassio-addons/app-tailscale/pull/681) | Integrated | Separates local verbosity from client log upload with a disabled-by-default `log_upload` option. Reconciled with #667's MagicDNS allowlist.                                                                                                                                                                        |
| [#700](https://github.com/hassio-addons/app-tailscale/pull/700) | Adapted    | Updates reusable CI to v3. The fork runs it for pull requests and `main`; organization-specific deploy dispatches, release drafting, labels, lock, and stale automation were removed because they depend on upstream-only secrets, labels, and companion repositories.                                             |
| [#702](https://github.com/hassio-addons/app-tailscale/pull/702) | Integrated | Keeps Serve/Funnel working for existing Home Assistant SSL setups via a loopback `https+insecure` backend. Current documentation still recommends Home Assistant's HTTP backend to avoid redundant local TLS.                                                                                                      |
| [#703](https://github.com/hassio-addons/app-tailscale/pull/703) | Integrated | Makes service shutdown on a manual app stop graceful. The related #667 and #680 finish scripts were checked together.                                                                                                                                                                                              |
| [#708](https://github.com/hassio-addons/app-tailscale/pull/708) | Integrated | Refreshes Tailscale admin/documentation URLs and improves Serve, Funnel, and exit-node error guidance. Reconciled with #702.                                                                                                                                                                                       |
| [#715](https://github.com/hassio-addons/app-tailscale/pull/715) | Deferred   | The Tailscale Services implementation has an unresolved major review issue: service cleanup can erase newly configured endpoints, and repeated entries for one service overwrite each other. Its checks also were not green.                                                                                       |
| [#722](https://github.com/hassio-addons/app-tailscale/pull/722) | Adapted    | Keeps the intended `local_apps`/`app_configs` Taildrive names and migration, but retains Supervisor-supported map types (`addons` and `all_addon_configs`) with explicit new mount paths. The PR's proposed map types fail Home Assistant app lint. Deprecated shares are removed before replacements are created. |
| [#727](https://github.com/hassio-addons/app-tailscale/pull/727) | Integrated | Updates Serve setup for the Home Assistant 2026.8 networking UI. Combined with #702 so the recommended HTTP setup and compatibility with existing SSL installations are both documented accurately.                                                                                                                |

## Integrated pull-request credits

Fork integration and adaptations are by
[`liliainbloom`](https://github.com/liliainbloom). Complete and partial PR
integrations are credited to their upstream authors:

- [Laszlo Magyar (`@lmagyar`)](https://github.com/lmagyar): #585, #662, #663,
  #667, #669, #671, #673, #680, #681, #703, #708, #722, and #727.
- [Sebestyén Bálint (`@dynamyc010`)](https://github.com/dynamyc010): #702.
- [Renovate](https://github.com/apps/renovate): #700.

Directly applied commits retain their original Git authorship, including
Franck Nijhof's contribution to #585. The original project and full upstream
contributor history remain credited in the README and Git history.

## High-risk interaction groups checked

- **MagicDNS and startup:** #662, #667, and #681 share configuration and service
  dependencies; the fallback flag, service pruning, daemon mode, proxy
  allowlists, and health checks were reconciled as one flow.
- **Network readiness and shutdown:** #673, #680, and #703 alter adjacent S6
  startup/finish paths; dependency targets and graceful termination were checked
  after the combined changes.
- **Home Assistant sharing:** #702, #708, and #727 touch the same Serve/Funnel
  path and documentation; SSL compatibility, current UI guidance, and error
  messages were combined rather than choosing one change wholesale.
- **Taildrive migration:** #722's visible terminology was separated from its
  unsupported Supervisor map types, preserving both upgrade behavior and app
  schema validity.
