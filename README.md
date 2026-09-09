# TrueTun

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

TrueTun is a cross-platform TUN proxy client for **Android** and **Linux**. The Flutter application owns profiles, subscriptions, routing and persistence; platform adapters own the actual VPN/TUN runtime.

## TrueTun 0.4.0

The first combined Android + Linux release provides real traffic forwarding on both targets.

### Android

- Native Android `VpnService` with a real TUN interface.
- Foreground service lifecycle and Disconnect notification action.
- `VpnService.protect()` integration so proxy-core sockets do not loop back into the VPN.
- Physical-network monitoring and interface auto-detection.
- Pinned `sing-box-lx 1.14.0-lx.35` libbox runtime with XHTTP support.
- VLESS with TLS/Reality and TCP, HTTP, WebSocket, gRPC, HTTPUpgrade, QUIC and XHTTP transport compilation.
- Hysteria2 URI/YAML/Mihomo import and connection path.
- Single-profile import and remote subscriptions.
- Ordered proxy/direct/block routing rules.
- Application whitelist and blacklist routing through Android TUN package filters.
- Local smart app-routing suggestions.
- Live traffic counters, connection test, logs and native diagnostics.
- Optimized traffic graph/state subscriptions and regression coverage for dialog lifecycle failures found during beta device testing.

### Linux

- Release-mode Flutter desktop application with system tray and per-user autostart.
- Pinned `sing-box-lx 1.14.0-lx.35` executable from the same XHTTP-capable core family used on Android.
- Unprivileged GUI with a narrowly scoped root-owned helper for TUN/core startup.
- VLESS/Reality/XHTTP and Hysteria2 through the normalized TrueTun profile path.
- Profiles, subscriptions, persistence, connection testing, logs and live traffic statistics.
- Full ordered routing editor for domains, IP/CIDR, ports, protocol/network and Linux process matching.
- Dedicated process-routing page for process name, exact executable path or path regex with proxy/direct/block actions.
- Desktop-menu installer and cleanup helper in the release archive.

## Protocol support

TrueTun distinguishes **core capability** from **implemented import support**. Version 0.4.0 has first-class profile parsing/compilation for:

- **VLESS**, including Reality and XHTTP.
- **Hysteria2**.

The bundled sing-box-lx core supports additional protocols, but TrueTun does not yet claim full UI/share-link import support for VMess, Trojan, Shadowsocks, TUIC, SSH or WireGuard. See `docs/PROTOCOLS.md` for the support matrix.

## Architecture

```text
Flutter UI
   |
Application state / persistence
   |-- Profiles and subscriptions
   |-- Ordered routing rules
   |-- Android application policy
   |-- Linux process rules
   |-- Settings and diagnostics
   |
Core-neutral configuration compiler
   |
ProxyCoreAdapter
   |-- Android native libbox + VpnService
   `-- Linux sing-box-lx process + privileged helper
```

Rules are stored independently of the core and compiled when a connection starts. Platform-specific matchers are rejected on incompatible targets instead of silently becoming match-all rules.

## Installation

### Android

Download `TrueTun-android-v0.4.0.apk` from the GitHub `v0.4.0` release and install it. Android will request VPN permission on the first connection.

GitHub source releases fall back to the project test signing key when production signing secrets are not configured. The Gradle build supports a production keystore through `TRUETUN_KEYSTORE_PATH`, `TRUETUN_KEYSTORE_PASSWORD`, `TRUETUN_KEY_ALIAS` and `TRUETUN_KEY_PASSWORD`.

### Linux x86_64

Download and unpack `TrueTun-linux-x86_64-v0.4.0.tar.gz`, then run:

```bash
./truetun
```

On the first launch after installation/core update, PolicyKit asks for authentication once. TrueTun installs the verified core and a narrow helper under `/usr/local/libexec/truetun`; the Flutter GUI itself continues to run as the normal desktop user.

Optional application-menu integration:

```bash
./install-desktop.sh
```

Cleanup of desktop/autostart integration and the privileged helper:

```bash
./uninstall.sh
```

Typical runtime/build dependencies are GTK 3, libstdc++, libsecret, PolicyKit/pkexec, sudo/visudo and the normal Flutter Linux runtime libraries.

## Building from source

Install Flutter with Android and/or Linux desktop toolchains, then:

```bash
flutter pub get
flutter analyze
flutter test
```

Linux self-contained release packaging:

```bash
TRUETUN_VERSION=0.4.0 bash tool/package_linux_release.sh
```

The release packager downloads an exact sing-box-lx archive and verifies its SHA-256 before embedding it. Android Gradle does the same for the exact libbox AAR.

## Security and third-party source

TrueTun project code is licensed under Apache-2.0. Distributed sing-box/sing-box-lx components are GPL-3.0-or-later and retain their own obligations. Stable GitHub releases attach the corresponding sing-box-lx source archive together with `THIRD_PARTY_NOTICES.md` and `SHA256SUMS.txt`.

See:

- `docs/ARCHITECTURE.md`
- `docs/ROUTING.md`
- `docs/PROTOCOLS.md`
- `docs/ROADMAP.md`
- `docs/LICENSING.md`
- `THIRD_PARTY_NOTICES.md`

## Validation scope

CI analyzes/tests the Flutter code, builds Android, builds a self-contained Linux release bundle and smoke-checks the Linux executable/core packaging. Android beta device testing has already exercised the real VPN path and Hysteria2 and exposed/fixed a Flutter dialog lifecycle bug and UI performance problems.

Network behavior still depends on the Android vendor kernel, Linux distribution, local firewall, DNS and network policy. Reproducible runtime failures should include the TrueTun Logs/diagnostic output and the exact profile transport involved.
