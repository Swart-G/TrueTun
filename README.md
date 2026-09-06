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

- Flutter application shell for Android/Linux product development.
- Core abstraction and process-based sing-box runner for Linux development.
- Core-neutral routing model and sing-box route-rule compiler.
- Android application-routing model and local smart-suggestion engine.
- Profile input detection layer for share links, subscription URLs, sing-box JSON and Clash/Mihomo YAML.
- Architecture, routing and implementation roadmap documentation.
- Unit tests for routing compilation.
- CI for formatting/analyze/tests.

Platform shells and native Android VPN/core integration are intentionally the next step; the domain model is already shaped so those integrations do not leak into the UI.

## Core strategy

The default production target should be a **sing-box-compatible core**. Upstream sing-box is the conservative baseline. An extended build can be supplied through the same adapter for features not available upstream, such as XHTTP or Amnezia-specific functionality.

Do not import Hiddify application code into TrueTun. Reusing the architecture is enough and keeps the project independent.

See:

- `docs/ARCHITECTURE.md`
- `docs/ROUTING.md`
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

When the native shells are committed, the first command is no longer necessary.

## Project direction

The first usable milestone is intentionally narrow: import a VLESS link/subscription, select a node, connect through TUN, create ordered routing rules, and configure Android app include/exclude routing. Everything else builds on top of that path.
