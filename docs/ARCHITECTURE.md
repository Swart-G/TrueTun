# TrueTun architecture

## 1. Architectural decision

TrueTun is a Flutter product with a replaceable proxy-core backend.

The important constraint is that **profiles, routing rules, subscriptions, app policies and UI must not depend on a concrete core API**. A connection session is built in stages:

```text
Profile source -> normalized nodes -> proxy groups
                              \
Routing policy ----------------> Core config compiler -> ProxyCoreAdapter -> TUN
App policy --------------------/
DNS policy -------------------/
```

This gives us Hiddify's useful separation without inheriting Hiddify application code or making the product impossible to migrate later.

## 2. Core strategy

### Baseline

Use a stable sing-box release/build as the baseline backend. It already provides TUN, VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, SSH, WireGuard, selectors, URL tests and rich routing.

### Extended backend

Some deployments need functionality that is present in extended forks earlier than upstream, notably XHTTP or Amnezia-specific features. TrueTun should expose these through a separate backend capability flag rather than adding fork-specific concepts to every layer.

Example:

```text
CoreCapabilities
- protocols: vless, hysteria2, ...
- transports: tcp, ws, grpc, xhttp?, ...
- features: tun, rule_sets, app_routing, tls_fragment, ...
```

The UI can then hide or disable unsupported profile options for the selected backend.

## 3. Layers

### Presentation

Flutter pages and widgets only talk to application services/state. The UI never writes sing-box JSON directly.

Main product areas:

- Home / connection state
- Profiles and subscriptions
- Proxy groups / node selection
- Routing
- Android apps / Linux applications
- Logs and diagnostics
- Settings

### Domain

Core-neutral models:

- `ProxyNode`
- `Subscription`
- `ProxyGroup`
- `RoutingRule`
- `RuleMatcher`
- `RouteAction`
- `AppRoutingPolicy`
- `DnsPolicy`

They are persisted in our own schema with migrations.

### Import / normalization

Importers turn external formats into domain models:

1. Single share links.
2. Plain/base64 lists of share links.
3. sing-box JSON.
4. Clash/Mihomo YAML.
5. Remote subscription URLs with headers/metadata.

External configuration is never used as the application's database format. We normalize it first.

### Configuration compiler

A compiler receives a connection snapshot and produces a complete core config. It owns:

- TUN inbound
- DNS servers/rules
- proxy outbounds
- selector/urltest groups
- ordered route rules
- rule-set definitions
- platform-specific patches

All generated configs are validated by the core before replacing a running session.

### Core adapter

`ProxyCoreAdapter` owns lifecycle only:

- capabilities/version
- validate
- start
- stop
- state events
- logs

Linux initially uses the process adapter. Android uses a native binding/VPN service, but both expose the same Dart interface.

## 4. Android

Native Android responsibilities should stay small and explicit:

- `VpnService` lifecycle and permission flow.
- Native core binding / file descriptors required by the core.
- Installed application enumeration via `PackageManager`.
- App icons and labels.
- Foreground service notification.
- Network change callbacks.
- Protecting sockets/control channels from the VPN where required.
- Applying the per-app allow/deny list to `VpnService.Builder`.

Flutter owns the app-selection UX and the persisted policy.

### Per-app modes

TrueTun exposes two simple product modes:

- `proxyAllExceptSelected` -> native `VpnService.Builder.addDisallowedApplication(...)` for the selected packages.
- `proxyOnlySelected` -> native `VpnService.Builder.addAllowedApplication(...)` for the selected packages.

This native filter is the production authority because it decides which application traffic enters the Android VPN at all. A core-level TUN `include_package`/`exclude_package` patch can be generated for compatible backends, but it is secondary.

More precise package rules are a different layer: once an app is inside the VPN, sing-box `package_name` routing can send one app to proxy A, another to proxy B, direct or block.

## 5. Linux

Start with a sing-box-compatible child process because it is easy to debug and isolates crashes.

Current test build includes:

- packaged x86_64 core binary
- root-owned helper restricted to config validation and core startup
- one PolicyKit authentication during launcher startup

Later add:

- packaged core binaries for other architectures
- dedicated PolicyKit service instead of the temporary sudoers integration
- system tray
- process/app discovery from desktop entries + `/proc`
- `process_name` / `process_path` routing

The GUI should remain unprivileged.

## 6. Routing semantics

Rules are ordered and first-match wins, matching the mental model users know from Mihomo.

A rule can contain several matcher categories. Values inside one category are OR; different categories are AND, following sing-box semantics. The UI should show this explicitly.

Targets:

- proxy or proxy group
- direct
- block

The compiler rejects rules containing a platform-only matcher for the wrong platform. This prevents a package-only Android rule from turning into an accidental match-all rule on Linux.

## 7. Smart app selection

The first implementation is deliberately local and explainable:

- Always bypass TrueTun itself.
- Recommend bypass for other VPN/proxy apps.
- Recommend bypass for sensitive system components by default.
- Recommend proxy for browser/messaging/social categories with moderate confidence.
- Leave ambiguous apps unchanged.

The next layer adds curated regional package sets, similar in spirit to Hiddify's region-based auto-selection, but kept as replaceable TrueTun data providers rather than hard-coded product logic.

Later inputs can include:

- user-selected country/preset
- known app domains from local rule-set metadata
- previous connection failures
- whether an app works only with/without proxy
- user's previous choices

Every recommendation must show a reason and remain one-tap reversible. Installed-app inventory should not be uploaded just to obtain recommendations.

## 8. Reliability requirements

- Generate new config -> validate -> only then switch sessions.
- Store the last known-good config snapshot.
- If a new config fails, restore the previous session.
- Core crash must not crash the Flutter process.
- Subscription refresh must be transactional.
- Rule-set downloads require checksum/cache handling and a last-known-good copy.
- Logs must redact credentials, UUIDs, passwords, subscription tokens and query parameters where appropriate.

## 9. Security boundaries

- Secret profile data is stored using platform-protected storage where possible.
- Debug exports are redacted by default.
- Remote subscription TLS verification stays enabled by default.
- Never execute shell fragments from subscriptions/configs.
- Linux privileged operations are isolated in a narrow helper API.
