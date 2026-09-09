# Protocol support

TrueTun separates **import support**, **core capability** and **platform validation**. A protocol existing in the bundled core does not automatically mean the application can import and manage it.

## TrueTun 0.4.0 matrix

| Protocol / transport | Import/model | Config compiler | Android core | Linux core | Status |
|---|---:|---:|---:|---:|---|
| VLESS TCP | Yes | Yes | Yes | Yes | Supported path |
| VLESS Reality | Yes | Yes | Yes | Yes | Supported path |
| VLESS WebSocket | Yes | Yes | Yes | Yes | Supported path |
| VLESS gRPC | Yes | Yes | Yes | Yes | Supported path |
| VLESS HTTPUpgrade | Yes | Yes | Yes | Yes | Supported path |
| VLESS QUIC transport | Yes | Yes | Core-supported | Core-supported | Experimental |
| VLESS XHTTP | Yes | Yes | `sing-box-lx 1.14.0-lx.35` | `sing-box-lx 1.14.0-lx.35` | Experimental / device validation ongoing |
| Hysteria2 | Yes | Yes | Yes | Yes | Supported path; Android device test confirmed basic connection |
| VMess | Planned | Planned | Core-capable | Core-capable | Not claimed by UI |
| Trojan | Planned | Planned | Core-capable | Core-capable | Not claimed by UI |
| Shadowsocks | Planned | Planned | Core-capable | Core-capable | Not claimed by UI |
| TUIC | Planned | Planned | Core-capable | Core-capable | Not claimed by UI |
| SSH | Planned | Planned | Core-capable | Core-capable | Not claimed by UI |
| WireGuard | Planned | Planned | Core-capable | Core-capable | Not claimed by UI |
| AnyTLS / Amnezia variants | Planned | Planned | Build-dependent | Build-dependent | Not claimed |

## Support states

- `unsupported` — TrueTun cannot represent the profile/backend combination.
- `importOnly` — the profile can be preserved/displayed but not connected with the active backend.
- `experimental` — a connection path exists and passes config/build tests but still needs broader platform/network validation.
- `supported` — implemented in the TrueTun model/compiler and covered by the relevant integration path.

## VLESS fields

The VLESS model currently preserves and compiles:

- UUID
- server and port
- flow
- packet encoding
- TLS state
- SNI
- ALPN
- insecure flag
- uTLS fingerprint
- Reality public key and short ID
- transport type
- WebSocket host/path
- gRPC service name
- HTTP/HTTPUpgrade host/path
- XHTTP mode/host/path
- unknown query parameters in an extension map

## XHTTP backend

Both release platforms use the pinned XHTTP-capable `Leadaxe/sing-box-lx 1.14.0-lx.35` core family:

- Android: `libbox-1.14.0-lx.35.aar`.
- Linux: architecture-specific `sing-box-1.14.0-lx.35-linux-*` executable.

XHTTP configuration emits `transport.type = xhttp`, carries the imported `mode`, `host` and `path`, and defaults omitted mode to the core's `auto` behavior. The runtime fork supports packet-up, stream-up and stream-one modes; interoperability still depends on the target Xray/sing-box-extended server and reverse-proxy/CDN configuration.

## Hysteria2

TrueTun imports Hysteria2 from:

- `hysteria2://` and `hy2://` links
- official client YAML
- sing-box JSON where handled by the subscription pipeline
- Mihomo/Clash YAML proxy entries

The model supports TLS configuration, port hopping, bandwidth hints and supported obfuscation fields. Inputs that cannot currently be translated without weakening security are rejected rather than ignored.

## Compatibility validation

For every protocol/transport promoted to stable support, the intended validation set is:

1. Parser fixture -> normalized node.
2. Normalized node -> generated core JSON.
3. Pinned core `check` accepts the generated JSON.
4. DNS through TUN.
5. TCP upload/download.
6. UDP where applicable.
7. reconnect after network changes.
8. large bidirectional transfer.
9. Android and Linux separately.

XHTTP additionally needs explicit upload/download testing per mode because a transport can establish an HTTP session while one direction remains unusable.
