# TrueTun

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

## Documentation for AI agents

Start with [AGENTS.md](AGENTS.md) and the [documentation map](docs/README.md). The detailed Russian-language specification covers module boundaries, data and IPC contracts, lifecycle/recovery, routing semantics, DNS, Android/Linux integration, security, UI, acceptance tests and implementation tasks. It describes the target architecture; see the [checked baseline](docs/architecture/01-baseline.md) for actual implementation status.

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
- Stable-backend VLESS -> sing-box outbound compiler. XHTTP remains capability-gated for an extended backend rather than being silently miscompiled.
- Architecture, routing, protocol and implementation-roadmap documentation.
- Unit tests and GitHub Actions CI for format/analyze/tests.

Native Android `VpnService`/mobile-core integration and generated Android/Linux Flutter platform shells are the next implementation step. The domain model is already shaped so native details do not leak into profiles, routing or the UI.

## Core strategy

The default production target should be a **sing-box-compatible core**. Upstream sing-box is the conservative baseline. An extended build can be supplied through the same adapter for features not available upstream, such as XHTTP or Amnezia-specific functionality.

Do not import Hiddify application code into TrueTun. Reusing the architecture is enough and keeps the project independent.

See:

- [Documentation map](docs/README.md)
- [Architecture](docs/ARCHITECTURE.md)
- `docs/ROUTING.md`
- `docs/PROTOCOLS.md`
- `docs/ROADMAP.md`
- `docs/LICENSING.md`

## Development bootstrap

Install Flutter with Android and Linux desktop toolchains, then from the repository root run:

```bash
flutter create --platforms=android,linux --project-name truetun .
flutter pub get
flutter analyze
flutter test
```

The same bootstrap is available as `tool/bootstrap.sh`. When the generated native shells are committed, `flutter create` is no longer necessary.

## Project direction

The first usable milestone is intentionally narrow: import a VLESS link/subscription, select a node, connect through TUN, create ordered routing rules, and configure Android app include/exclude routing. Everything else builds on top of that path.
