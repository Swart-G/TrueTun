# Routing design

TrueTun routing is inspired by Mihomo's ordered rules but stored in a core-neutral schema.

## User model

Each rule has:

1. Name and enabled state.
2. One or more match conditions.
3. One action.
4. Position in the ordered list.

Example UI representation:

```text
Telegram
  PACKAGE-NAME = org.telegram.messenger
  -> Proxy / Auto

Local network
  IP-CIDR = 192.168.0.0/16, 10.0.0.0/8
  -> DIRECT

Ads
  RULE-SET = ads
  -> BLOCK

Fallback
  MATCH
  -> Proxy / Auto
```

`MATCH` is represented separately as the final/default action; ordinary rules are not allowed to have an empty matcher.

## Matchers planned for the UI

### Network-independent

- DOMAIN
- DOMAIN-SUFFIX
- DOMAIN-KEYWORD
- DOMAIN-REGEX
- IP-CIDR
- SRC-IP-CIDR
- DST-PORT / port range
- SRC-PORT / port range
- NETWORK: TCP / UDP / ICMP where supported
- PROTOCOL: DNS / HTTP / TLS / QUIC / STUN / etc. after sniffing
- RULE-SET

### Android

- PACKAGE-NAME
- PACKAGE-NAME-REGEX when supported by the selected core

### Linux

- PROCESS-NAME
- PROCESS-PATH
- PROCESS-PATH-REGEX
- USER / UID later

## Actions

- `Proxy(groupOrNode)` -> sing-box `action: route`, `outbound: <tag>`.
- `Direct` -> `action: route`, `outbound: direct`.
- `Block` -> `action: reject`, defaulting to drop.

## Rule sets

Rule sets are first-class objects rather than opaque URLs attached to a rule.

A rule-set record should contain:

- stable ID/tag
- display name
- source URL or bundled asset
- source format
- update interval
- current checksum/version
- last successful update
- last-known-good local path
- optional expected signature/hash

Planned sources include domain/IP lists and sing-box binary/source rule sets. Importing common Mihomo rule-provider layouts should be supported by converting them into the internal representation.

## Proxy groups

Routing targets should point to stable group IDs, not ephemeral node tags.

Initial group types:

- Manual selector
- URL-test / fastest
- Fallback
- Load balance later

A subscription refresh can replace nodes without invalidating user routing rules because the rule points to the group.

## DNS interaction

Routing and DNS cannot be implemented independently. The configuration compiler must ensure:

- DNS traffic is hijacked into the core when TUN mode requires it.
- Domain-based rules see the original/sniffed domain where possible.
- Rule-set domain matches do not get lost after premature DNS resolution.
- Direct DNS and proxy DNS can be routed separately.
- FakeIP is optional, not a hard dependency of the rule engine.

## Android app routing vs route rules

There are two distinct mechanisms and both are useful:

1. **Native Android VPN app filter** decides which applications enter the VPN at all. TrueTun maps the simple whitelist/blacklist UI to `VpnService.Builder.addAllowedApplication(...)` and `addDisallowedApplication(...)`. A compatible core-level `include_package` / `exclude_package` filter is secondary rather than authoritative.
2. **Route `package_name` rule** decides what to do with traffic from a package that has already entered the VPN. This powers advanced rules such as `Telegram -> proxy A`, `Browser -> proxy B`, direct, or block.

TrueTun keeps these concepts separate in both persistence and UI. The first is an application-access policy; the second is an ordered routing rule.

## Linux app routing

Linux does not have Android package names. The app picker should resolve desktop applications to executable/process information and generate process rules. The UI can still call the feature “Apps”, but the persisted matcher must record the platform-specific identity.

## Import/export

Later, advanced users should be able to:

- export TrueTun routing as JSON
- import a practical subset of Mihomo `rules:` syntax
- paste individual Mihomo-style lines into the visual editor
- preview generated sing-box rules for debugging

The visual/domain model remains authoritative; imported text is converted into it.
