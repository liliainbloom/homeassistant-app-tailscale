# Tailscale for Home Assistant — liliainbloom's Fork

[![CI](https://github.com/liliainbloom/homeassistant-app-tailscale/actions/workflows/ci.yaml/badge.svg)](https://github.com/liliainbloom/homeassistant-app-tailscale/actions/workflows/ci.yaml)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.md)

> [!IMPORTANT]
> This is liliainbloom's unofficial fork of
> [hassio-addons/app-tailscale](https://github.com/hassio-addons/app-tailscale).
> It is not supported by Tailscale, Home Assistant, or the upstream maintainers.

Run Tailscale on Home Assistant to connect the host and its local networks to a
tailnet. The app supports `aarch64` and `amd64` Home Assistant systems.

## What is in this fork?

This fork keeps the upstream `v0.28.1` lineage, incorporates the useful changes
from the upstream `main` branch, and packages Tailscale `1.102.2`—the current
stable release when the fork was audited on 2026-08-09.

The open upstream pull requests were reviewed individually. Compatible fixes
were integrated, interacting changes were reconciled, and unfinished or unsafe
changes were left out. See [FORK_NOTES.md](FORK_NOTES.md) for the complete audit
and decision record.

## Installation

This is the source repository. Add the companion app repository—not this source
fork—to Home Assistant:

1. In Home Assistant, open **Settings** -> **Apps** -> **App store**.
2. Open the app-store menu, choose **Repositories**, and add:
   `https://github.com/liliainbloom/homeassistant-repository`
3. Install **Tailscale (liliainbloom's Fork)**.
4. Start the app and use its Web UI to authenticate with Tailscale.

Read the [app documentation](tailscale/DOCS.md) before enabling subnet routing,
an exit node, Serve/Funnel, MagicDNS, Taildrop, or Taildrive.

## Credits

This fork was integrated and adapted by
[`liliainbloom`](https://github.com/liliainbloom). It incorporates complete or
partial work from these upstream pull-request authors:

- [Laszlo Magyar (`@lmagyar`)](https://github.com/lmagyar):
  [#585](https://github.com/hassio-addons/app-tailscale/pull/585),
  [#662](https://github.com/hassio-addons/app-tailscale/pull/662),
  [#663](https://github.com/hassio-addons/app-tailscale/pull/663),
  [#667](https://github.com/hassio-addons/app-tailscale/pull/667),
  [#669](https://github.com/hassio-addons/app-tailscale/pull/669),
  [#671](https://github.com/hassio-addons/app-tailscale/pull/671),
  [#673](https://github.com/hassio-addons/app-tailscale/pull/673),
  [#680](https://github.com/hassio-addons/app-tailscale/pull/680),
  [#681](https://github.com/hassio-addons/app-tailscale/pull/681),
  [#703](https://github.com/hassio-addons/app-tailscale/pull/703),
  [#708](https://github.com/hassio-addons/app-tailscale/pull/708),
  [#722](https://github.com/hassio-addons/app-tailscale/pull/722), and
  [#727](https://github.com/hassio-addons/app-tailscale/pull/727).
- [Sebestyén Bálint (`@dynamyc010`)](https://github.com/dynamyc010):
  [#702](https://github.com/hassio-addons/app-tailscale/pull/702).
- [Renovate](https://github.com/apps/renovate):
  [#700](https://github.com/hassio-addons/app-tailscale/pull/700).

Directly applied commits retain their original Git authorship. Franck Nijhof
and the Home Assistant Community Apps contributors created and maintain the
original project; its complete contributor history remains upstream.

## Support and upstream

Report fork-specific problems in this fork's
[issue tracker](https://github.com/liliainbloom/homeassistant-app-tailscale/issues). When an
issue also affects the unmodified upstream app, include that fact and a minimal
reproduction so it can be evaluated upstream separately.

The original project and its contributor history remain available at
[hassio-addons/app-tailscale](https://github.com/hassio-addons/app-tailscale)
and the [upstream contributors page](https://github.com/hassio-addons/app-tailscale/graphs/contributors).

## License

This fork remains licensed under the [MIT License](LICENSE.md) and retains the
original copyright and permission notice. Original project by Franck Nijhof and
the Home Assistant Community Apps contributors.
