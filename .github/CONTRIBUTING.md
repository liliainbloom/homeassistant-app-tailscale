# Contributing

Please discuss non-trivial changes in a
[fork issue](https://github.com/liliainbloom/app-tailscale/issues) before opening
a pull request. Search existing issues and pull requests first.

Pull requests should:

- explain the user-visible problem and why the change is appropriate for this
  fork;
- preserve existing configuration or include an explicit upgrade migration;
- describe interactions with MagicDNS, routing, S6 services, and Home Assistant
  Supervisor APIs when those areas are touched;
- pass the repository's CI checks; and
- retain upstream authorship and the MIT license notice when copying or
  adapting upstream work.

Security vulnerabilities must be reported privately as described in
[SECURITY.md](SECURITY.md), not in a public issue.
