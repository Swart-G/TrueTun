# TrueTun

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

TrueTun is a cross-platform proxy client for **Android** and **Linux**.

The project follows the architecture that makes Hiddify stable in practice: the UI and product logic are independent from the proxy core. TrueTun uses an adapter around a sing-box-compatible core instead of coupling profiles, routing and UI directly to one binary/fork.

## Product goals

- Stable TUN-based proxying on Android and Linux.
- VLESS first-class support, including Reality and modern transports.
- Broad protocol support through a sing-box-compatible core: VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, SSH, WireGuard and others supported by the selected core build.
- Import both single share links and remote subscriptions.
- Subscription formats: plain/base64 share-link lists, sing-box JSON, Clash/Mihomo YAML and panel-generated subscription URLs.
- Ordered routing rules inspired by Mihomo: domain, suffix, keyword, regex, IP/CIDR, port, protocol, rule-set, Android package and Linux process rules.
- Routing targets: proxy/group, direct and block.
- Android per-app routing with both modes:
  - **Proxy all except selected apps** (blacklist/bypass list).
  - **Proxy only selected apps** (whitelist/include list).
- Local smart app suggestions for per-app routing without sending the installed-app list to a server.
- Profiles, proxy groups, latency testing, automatic node selection and failover.
- No dependency of UI/domain logic on a specific core implementation.

## Architecture

```text
Flutter UI
   |
Application services
   |-- Profiles / subscriptions
   |-- Routing rules
   |-- App routing policy
   |-- Proxy groups / health
   |-- Settings / persistence
   |
Core configuration compiler
   |
ProxyCoreAdapter
   |-- Native/mobile core adapter (Android)
   |-- sing-box process adapter (Linux)
   `-- optional extended-core adapter
```

The internal routing model is deliberately core-neutral. UI rules are compiled to the target core configuration only at connection time.

## Repository status

This first foundation contains:

- Flutter Material 3 application shell with adaptive Android/Linux navigation.
- Core lifecycle abstraction and process-based sing-box runner for Linux development.
- Core-neutral routing model and sing-box route-rule compiler.
- Android native VPN allow/deny policy model plus compatible core TUN package filtering.
- Local explainable smart-app suggestion baseline.
- Profile input detection for share links, subscription URLs, sing-box JSON and Clash/Mihomo YAML.
- Typed VLESS parser with TLS, Reality, uTLS fingerprint, WebSocket, gRPC, HTTPUpgrade and XHTTP import preservation.
- Hysteria2 import from `hysteria2://` / `hy2://`, official client YAML, sing-box JSON, and Mihomo/Clash YAML, with sing-box outbound compilation and persistence.
- Stable-backend VLESS -> sing-box outbound compiler. XHTTP remains capability-gated for an extended backend rather than being silently miscompiled.
- Architecture, routing, protocol and implementation-roadmap documentation.
- Unit tests and GitHub Actions CI for format/analyze/tests.

The Linux client is usable with the packaged extended core, persistent profiles,
subscriptions, diagnostics, traffic statistics, tray mode, and autostart. The
Android APK currently provides the application UI and persistent profile
management; native `VpnService`/mobile-core integration is still required before
Android can carry device traffic.

## Core strategy

The default production target should be a **sing-box-compatible core**. Upstream sing-box is the conservative baseline. An extended build can be supplied through the same adapter for features not available upstream, such as XHTTP or Amnezia-specific functionality.

Do not import Hiddify application code into TrueTun. Reusing the architecture is enough and keeps the project independent.

See:

- `docs/ARCHITECTURE.md`
- `docs/ROUTING.md`
- `docs/PROTOCOLS.md`
- `docs/ROADMAP.md`
- `docs/LICENSING.md`

## Development bootstrap

Install Flutter with Android and Linux desktop toolchains, then from the repository root run:

```bash
flutter pub get
flutter analyze
flutter test
```

The same dependency and validation commands are available through `tool/bootstrap.sh`.

## Linux test build

Create a self-contained debug bundle with the pinned sing-box core:

```bash
FLUTTER_BIN=/path/to/flutter/bin/flutter tool/package_linux_test.sh
build/linux/x64/debug/bundle/truetun
```

The `truetun` launcher asks for administrator authentication once. It installs
a root-owned core and a narrow helper with a `sudoers` rule limited to core
configuration validation and startup. Connections use non-interactive sudo, so
TUN routing and systemd-resolved setup do not request a second password. The
Flutter UI itself remains unprivileged. The Home page runs an HTTPS connection
test, displays its latency and reads traffic counters from the core. Core output
and connection-test results are available on the Logs page.

Closing the Linux window keeps TrueTun running in the system tray. The Settings
page controls per-user autostart, background operation, TUN stack, MTU, strict
routing, IPv6, DNS servers, and the core log level.

## Project direction

The first usable milestone is intentionally narrow: import a VLESS link/subscription, select a node, connect through TUN, create ordered routing rules, and configure Android app include/exclude routing. Everything else builds on top of that path.
