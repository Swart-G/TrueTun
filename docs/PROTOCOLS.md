# Protocol support plan

TrueTun separates **import support**, **core capability** and **tested production support**. A protocol appearing in a core build does not automatically mean the UI should claim it as supported.

## Priority matrix

| Priority | Protocol / transport | Import | Stable backend | Extended backend | Notes |
|---|---|---:|---:|---:|---|
| P0 | VLESS TCP | In progress | Yes | Yes | First end-to-end path |
| P0 | VLESS Reality | In progress | Yes | Yes | First-class support |
| P0 | VLESS WebSocket | In progress | Yes | Yes | CDN-friendly legacy/common path |
| P0 | VLESS gRPC | In progress | Yes | Yes | Requires compatible core build |
| P0 | VLESS HTTPUpgrade | In progress | Yes | Yes | Supported by sing-box V2Ray transport |
| P0 | VLESS XHTTP | Preserve import | No | Planned | Must be capability-gated and integration-tested |
| P1 | VMess | Planned | Yes | Yes | Share link + subscription import |
| P1 | Trojan | Planned | Yes | Yes | TLS + V2Ray transports where supported |
| P1 | Shadowsocks | Planned | Yes | Yes | SIP002-style links first |
| P1 | Hysteria2 | Implemented | Yes | Yes | URI + official YAML + sing-box JSON + Mihomo/Clash YAML; TLS pin/ECH inputs are rejected until they can be translated safely |
| P1 | TUIC | Planned | Yes | Yes | QUIC-based |
| P2 | SSH | Planned | Yes | Yes | Useful for simple deployments |
| P2 | WireGuard | Planned | Yes | Extended options possible | Core support and platform behavior need testing |
| P2 | AnyTLS | Planned | Core-dependent | Core-dependent | Expose only when capability reports it |
| P3 | NaiveProxy | Planned | Build/platform-dependent | Build/platform-dependent | Optional backend feature |
| P3 | Amnezia variants | Planned | No | Planned | Extended backend only |

## Support states

Every importer/backend pair should expose one of:

- `unsupported` — parser/core cannot represent it.
- `importOnly` — TrueTun can preserve/display the profile but cannot connect with the current backend.
- `experimental` — connect path exists but is not yet part of the stable compatibility promise.
- `supported` — covered by config tests and platform integration tests.

This prevents the common failure mode where a link imports successfully but breaks only after the user presses Connect.

## VLESS import fields

The typed VLESS model should preserve:

- UUID
- server / port
- flow (`xtls-rprx-vision`)
- packet encoding
- TLS state
- SNI
- ALPN
- insecure flag
- uTLS fingerprint when provided
- Reality public key / short ID
- transport type
- WebSocket host/path
- gRPC service name
- HTTP/HTTPUpgrade host/path
- XHTTP mode/host/path and future extended parameters

Unknown query parameters should eventually be retained in an extension map so future versions can re-import/export profiles without losing information.

## Backend policy

### Stable

Use a pinned stable sing-box-compatible build and support only features validated against that version.

### Extended

Use a separately identified build for capabilities not available in the stable backend, such as XHTTP or Amnezia-specific functionality. The extended backend must have its own compatibility tests and version pin.

The user can later choose a release channel such as:

- Stable core
- Extended core

Profiles remain the same domain objects. The backend capability check decides whether Connect is allowed.

## Compatibility tests

For each claimed protocol/transport, test at minimum:

1. Parser fixture -> normalized node.
2. Normalized node -> generated core JSON.
3. Core `check` accepts generated JSON.
4. TCP download/upload.
5. UDP where the protocol claims it.
6. DNS through TUN.
7. reconnect after network change.
8. large bidirectional transfer, not only latency/ping.
9. Android and Linux separately.

XHTTP specifically needs upload/download tests with explicit mode handling because a config can appear connected while persistent/bidirectional traffic is broken.
