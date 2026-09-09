import 'dart:convert';
import 'dart:io';

import 'package:truetun/src/core/connection_snapshot.dart';
import 'package:truetun/src/core/sing_box_outbound_compiler.dart';
import 'package:truetun/src/routing/routing_rule.dart';
import 'package:truetun/src/routing/sing_box_routing_compiler.dart';

class ConfigCompileException implements Exception {
  const ConfigCompileException(this.message);

  final String message;

  @override
  String toString() => 'ConfigCompileException: $message';
}

class SingBoxConfigCompiler {
  const SingBoxConfigCompiler();

  static const _outboundCompiler = SingBoxOutboundCompiler();
  static const _routingCompiler = SingBoxRoutingCompiler();

  String compile(ConnectionSnapshot snapshot) =>
      jsonEncode(compileMap(snapshot));

  Map<String, Object> compileMap(ConnectionSnapshot snapshot) {
    _validatePreferences(snapshot);

    final proxy = _outboundCompiler.compile(snapshot.node, tag: 'proxy');
    proxy['domain_resolver'] = 'dns-direct';

    final tun = <String, Object>{
      'type': 'tun',
      'tag': 'tun-in',
      if (snapshot.platform != RoutingPlatform.android)
        'interface_name': 'truetun0',
      'address': <String>[
        '172.19.0.1/30',
        if (snapshot.preferences.ipv6) 'fdfe:dcba:9876::1/126',
      ],
      'mtu': snapshot.preferences.mtu,
      'auto_route': true,
      if (snapshot.platform != RoutingPlatform.android)
        'strict_route': snapshot.preferences.strictRoute,
      'stack': snapshot.preferences.stack,
    };

    if (snapshot.platform == RoutingPlatform.linux) {
      tun['auto_redirect'] = true;
    }

    if (snapshot.platform == RoutingPlatform.android) {
      for (final entry in snapshot.androidTunPatch.entries) {
        if (_allowedAndroidTunPatchKeys.contains(entry.key)) {
          tun[entry.key] = entry.value;
        }
      }
    }

    final routeRules = <Map<String, Object>>[
      // TUN receives a destination IP after DNS resolution. Sniff the
      // request's HTTP Host / TLS SNI / QUIC SNI before evaluating user
      // domain rules, otherwise domain_suffix rules such as `.ru` cannot
      // reliably match browser traffic.
      <String, Object>{
        'action': 'sniff',
        'sniffer': <String>['http', 'tls', 'quic', 'dns'],
      },
      <String, Object>{
        'port': <int>[53],
        'action': 'hijack-dns',
      },
      // Browsers prefer QUIC for HTTPS. When the selected proxy server cannot
      // carry UDP reliably, silently dropping those packets makes web-based
      // speed tests wait for a long timeout. An explicit TUN rejection makes
      // the browser immediately retry over TCP/HTTPS. Core transport sockets
      // are protected from the TUN, so UDP-based outbounds are unaffected.
      <String, Object>{
        'network': <String>['udp'],
        'port': <int>[443],
        'action': 'reject',
        'method': 'default',
        'no_drop': true,
      },
      if (snapshot.routingSettings.enabled) ...[
        ..._routingCompiler.compileRules(
          snapshot.routingRules,
          platform: snapshot.platform,
        ),
        if (snapshot.routingSettings.fallbackAction == RouteActionType.block)
          <String, Object>{
            'action': 'reject',
            'method': 'drop',
          },
      ],
    ];

    final fallbackOutbound = snapshot.routingSettings.enabled &&
            snapshot.routingSettings.fallbackAction == RouteActionType.direct
        ? 'direct'
        : 'proxy';

    final route = <String, Object>{
      'rules': routeRules,
      'final': fallbackOutbound,
      'default_domain_resolver': 'dns-direct',
      if (snapshot.platform == RoutingPlatform.linux ||
          snapshot.platform == RoutingPlatform.android)
        'auto_detect_interface': true,
    };

    return <String, Object>{
      'log': <String, Object>{
        'level': snapshot.preferences.logLevel,
        'timestamp': true,
      },
      'dns': <String, Object>{
        'servers': <Map<String, Object>>[
          _compileDnsServer(
            snapshot.preferences.directDns,
            tag: 'dns-direct',
            requireIpAddress: true,
          ),
          _compileDnsServer(
            snapshot.preferences.remoteDns,
            tag: 'dns-remote',
            detour: 'proxy',
          ),
        ],
        'final': 'dns-remote',
        'strategy': snapshot.preferences.ipv6 ? 'prefer_ipv4' : 'ipv4_only',
      },
      'inbounds': <Map<String, Object>>[tun],
      'outbounds': <Map<String, Object>>[
        proxy,
        <String, Object>{'type': 'direct', 'tag': 'direct'},
      ],
      'route': route,
      if (snapshot.platform == RoutingPlatform.linux)
        'experimental': <String, Object>{
          'clash_api': <String, Object>{
            'external_controller': '127.0.0.1:19090',
          },
        },
    };
  }

  void _validatePreferences(ConnectionSnapshot snapshot) {
    final preferences = snapshot.preferences;
    if (preferences.mtu < 1280 || preferences.mtu > 65535) {
      throw const ConfigCompileException('MTU must be between 1280 and 65535');
    }
    if (!const {'system', 'gvisor', 'mixed'}.contains(preferences.stack)) {
      throw ConfigCompileException(
          'Unsupported TUN stack: ${preferences.stack}');
    }
    if (!const {'trace', 'debug', 'info', 'warn', 'error'}
        .contains(preferences.logLevel)) {
      throw ConfigCompileException(
        'Unsupported core log level: ${preferences.logLevel}',
      );
    }
  }

  Map<String, Object> _compileDnsServer(
    String raw, {
    required String tag,
    String? detour,
    bool requireIpAddress = false,
  }) {
    final value = raw.trim();
    if (value.isEmpty) {
      throw ConfigCompileException('$tag DNS server is empty');
    }

    final uri = value.contains('://')
        ? Uri.tryParse(value)
        : Uri.tryParse('udp://$value');
    if (uri == null || uri.host.isEmpty) {
      throw ConfigCompileException('Invalid DNS server: $value');
    }

    final scheme = uri.scheme.toLowerCase();
    final type = switch (scheme) {
      'udp' => 'udp',
      'tcp' => 'tcp',
      'tls' || 'dot' => 'tls',
      'https' || 'doh' => 'https',
      'h3' || 'http3' => 'h3',
      _ => throw ConfigCompileException('Unsupported DNS scheme: $scheme'),
    };

    if (requireIpAddress && InternetAddress.tryParse(uri.host) == null) {
      throw ConfigCompileException(
        'Direct/bootstrap DNS must use an IP address to avoid a DNS dependency loop',
      );
    }

    final defaultPort = switch (type) {
      'tls' => 853,
      'https' || 'h3' => 443,
      _ => 53,
    };

    final result = <String, Object>{
      'type': type,
      'tag': tag,
      'server': uri.host,
      'server_port': uri.hasPort ? uri.port : defaultPort,
      if (detour != null) 'detour': detour,
    };

    if (type == 'https' || type == 'h3') {
      result['path'] = uri.path.isEmpty ? '/dns-query' : uri.path;
    }
    if (type == 'tls' || type == 'https' || type == 'h3') {
      result['tls'] = <String, Object>{
        'enabled': true,
        'server_name': uri.host,
      };
    }

    return result;
  }

  static const _allowedAndroidTunPatchKeys = <String>{
    'include_package',
    'exclude_package',
  };
}
