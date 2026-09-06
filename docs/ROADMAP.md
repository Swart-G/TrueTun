# TrueTun implementation roadmap

The roadmap is ordered by dependency, not by visual priority. The goal is to reach a reliable end-to-end VLESS connection early and then add breadth without destabilizing the connection path.

## Phase 0 — Foundation

Status: **started in repository**

- [x] Flutter app shell.
- [x] Core lifecycle abstraction.
- [x] Linux process-based sing-box adapter for development.
- [x] Core-neutral routing models.
- [x] sing-box route-rule compiler baseline.
- [x] Android include/exclude app-policy model.
- [x] Local smart-app suggestion baseline.
- [x] Profile input type detector.
- [x] Architecture/routing docs and tests.
- [x] Generate and commit Android/Linux Flutter platform shells.
- [x] Add initial Drift persistence and Riverpod state-management layer.

Acceptance: domain tests pass and the UI shell runs on both targets.

## Phase 1 — Core packaging and native platform bridge

### Linux

- Package a pinned core binary for `x86_64` and `aarch64`.
- Resolve core path through an installation service rather than PATH in production.
- Add config/runtime directories under the appropriate XDG paths.
- Add an unprivileged GUI + narrow privileged helper using Polkit.
- Implement TUN start/stop and clean rollback of routes on crash.
- [x] Add Linux system tray lifecycle and background operation.
- [x] Add per-user Linux autostart.

### Android

- Create `VpnService` and foreground notification.
- Integrate a mobile/library build of the chosen sing-box-compatible core.
- Bridge lifecycle/events to Flutter with a MethodChannel/EventChannel or generated Pigeon API.
- Pass/own the TUN file descriptor correctly.
- Handle VPN permission, revoke, app kill and device reboot.
- Exclude/protect TrueTun control traffic to prevent loops.

Acceptance: a hardcoded outbound can establish a TUN connection on Android and Linux, survive reconnect, and stop without leaving broken routes.

## Phase 2 — VLESS end-to-end MVP

Priority: **highest protocol priority**

Implement `vless://` parsing into a normalized `ProxyNode` model (initial parser complete):

- UUID
- host / port
- TLS on/off
- SNI
- ALPN
- Reality public key / short ID / fingerprint
- flow (`xtls-rprx-vision` where applicable)
- transport: TCP, WebSocket, gRPC, HTTPUpgrade and capability-gated extended transports
- host/path/service name
- UDP/package options supported by the core

Then implement:

- [x] one-node config generation
- [x] direct outbound
- [x] TUN inbound
- [x] DNS baseline
- [x] validation before start
- latency test
- [x] initial connect/disconnect UI
- [x] redacted core events baseline

Acceptance: paste one VLESS link -> connect -> DNS/TCP/UDP work -> reconnect works on both platforms.

## Phase 3 — Profiles and subscriptions

### Single links

Add parsers in priority order:

1. VLESS
2. VMess
3. Trojan
4. Shadowsocks
5. Hysteria2
6. TUIC
7. SSH
8. WireGuard
9. other core-supported schemes

### Remote subscriptions

Pipeline:

```text
URL -> HTTP fetch -> detect format -> parse -> normalize -> validate -> transactionally replace profile
```

Formats:

- plain share-link list
- base64 share-link list
- sing-box JSON
- Clash/Mihomo YAML
- common panel subscription outputs

Features:

- custom user agent/header support where needed
- ETag / Last-Modified
- update interval
- manual update
- profile traffic/expiry metadata from response headers
- last-known-good subscription snapshot
- duplicate-node detection using stable fingerprints

Acceptance: refresh cannot destroy the active profile if the new response is malformed.

## Phase 4 — Routing editor comparable to Mihomo

Implement the visual ordered editor and persistence.

Matchers:

- domain / suffix / keyword / regex
- IP/CIDR
- source IP/CIDR
- ports/ranges
- network/protocol
- rule sets
- Android package
- Linux process name/path

Actions:

- proxy node/group
- direct
- block

UX:

- drag reorder
- enable/disable
- duplicate
- search/filter
- human-readable summary
- generated-config preview
- validation warnings
- final default route separate from ordinary rules

Import a useful Mihomo subset such as `DOMAIN`, `DOMAIN-SUFFIX`, `DOMAIN-KEYWORD`, `IP-CIDR`, `PROCESS-NAME`, `RULE-SET`, `MATCH`, then map it into TrueTun models.

Acceptance: rule order is deterministic and unit-tested; platform-incompatible rules cannot silently become match-all.

## Phase 5 — Android app whitelist/blacklist + smart selection

### Installed-app provider

Native Android service returns:

- package name
- label
- icon handle/cache key
- system/user app flag
- category where available
- launchable status

### Product modes

- **All through proxy except selected** -> TUN exclude list.
- **Only selected through proxy** -> TUN include list.

Add search, multi-select, select all user apps, hide system apps, and per-app advanced route action.

### Smart selection v1

Local explainable rules:

- own package -> bypass
- other VPN/proxy packages -> bypass
- system services -> bypass suggestion
- browsers/messaging/social -> proxy suggestion
- everything uncertain -> no automatic change

### Smart selection v2

Add optional local/regional presets and learning from user-confirmed outcomes:

- “works only through proxy” / “works better direct” feedback
- repeated connection failures
- app-associated domain rule-set hints
- user-created category presets

Never silently rewrite the app list. Show proposed changes, confidence and reasons, then let the user apply them.

Acceptance: switching whitelist/blacklist updates TUN filtering correctly without reconnect loops or excluding the VPN service incorrectly.

## Phase 6 — Proxy groups, health and failover

- Manual selector.
- URL-test / fastest.
- Fallback group.
- Per-node latency/history.
- Background health checks while connected with sane battery/network limits.
- Sticky node selection to prevent unnecessary hopping.
- Manual “test all” and per-profile test URL.
- Optional independent groups for routing rules.

Acceptance: node failures can move a group to a healthy node without changing user routing rules.

## Phase 7 — DNS and rule sets

- Core-native DNS module.
- Direct and proxied DNS paths.
- DoH / DoT / UDP/TCP where supported.
- DNS leak tests.
- Rule-set manager with transactional updates.
- Bundled local/private-network rules.
- Remote binary/source rules.
- Optional ad-block rule sets.
- Clear cache and inspect matched rule tools.

Acceptance: domain routing remains correct and DNS behavior is explainable in diagnostics.

## Phase 8 — Advanced core support

Capability-gated features:

- XHTTP through an extended backend if required.
- Amnezia variants supported by the selected extended core.
- AnyTLS / additional modern protocols.
- TLS fragmentation / other routing options where appropriate.
- multiple core channels: Stable and Extended.

Do not force all users onto an extended fork only to support one transport.

Acceptance: importing an unsupported link gives a precise capability message instead of a generic parser error.

## Phase 9 — Product hardening and releases

- Crash-safe connection recovery.
- Structured/redacted log viewer.
- Diagnostic bundle export.
- Auto-update on Linux.
- Android release signing and reproducible CI artifacts.
- Architecture matrix builds.
- Migration tests for persisted data.
- Performance/battery profiling.
- Accessibility and keyboard navigation.
- Russian and English localization first.

## Implementation order summary

The practical sequence is:

```text
Native core/TUN
  -> one VLESS link
  -> subscriptions
  -> routing rules
  -> Android app routing
  -> smart suggestions
  -> groups/failover
  -> DNS/rule sets
  -> protocol breadth
  -> hardening/release
```

This avoids the common trap of implementing a large settings UI before the connection lifecycle is reliable.
