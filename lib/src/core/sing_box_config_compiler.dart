import 'dart:convert';

import 'package:truetun/src/core/connection_snapshot.dart';
import 'package:truetun/src/core/sing_box_outbound_compiler.dart';
import 'package:truetun/src/profiles/proxy_node.dart';
import 'package:truetun/src/routing/routing_rule.dart';
import 'package:truetun/src/routing/sing_box_routing_compiler.dart';

class SingBoxConfigCompiler {
  const SingBoxConfigCompiler({
    this.outboundCompiler = const SingBoxOutboundCompiler(),
    this.routingCompiler = const SingBoxRoutingCompiler(),
  });

  final SingBoxOutboundCompiler outboundCompiler;
  final SingBoxRoutingCompiler routingCompiler;

  String compile(ConnectionSnapshot snapshot) =>
      jsonEncode(compileMap(snapshot));

  Map<String, Object> compileMap(ConnectionSnapshot snapshot) {
    final tag = snapshot.nodeTag.trim();
    if (tag.isEmpty || tag == 'direct' || tag == 'block' || tag == 'dns-out') {
      throw const OutboundCompileException(
          'Proxy outbound tag is invalid or reserved');
    }

    final proxy = switch (snapshot.node) {
      final VlessNode node => outboundCompiler.compileVless(node, tag: tag),
    };

    final routeRules = <Map<String, Object>>[
      <String, Object>{
        'port': <int>[53],
        'action': 'hijack-dns',
      },
      ...routingCompiler.compileRules(
        snapshot.rules,
        platform: snapshot.platform,
      ),
    ];

    return <String, Object>{
      'log': <String, Object>{
        'level': snapshot.logLevel,
        'timestamp': true,
      },
      'dns': <String, Object>{
        'servers': <Map<String, Object>>[
          _compileDnsServer(
            snapshot.dns.remoteServer,
            tag: 'remote-dns',
            detour: tag,
          ),
          _compileDnsServer(snapshot.dns.directServer, tag: 'direct-dns'),
        ],
        'final': 'remote-dns',
      },
      'inbounds': <Map<String, Object>>[
        <String, Object>{
          'type': 'tun',
          'tag': 'tun-in',
          'interface_name': snapshot.tun.interfaceName,
          'address': <String>[
            '172.19.0.1/30',
            if (snapshot.tun.ipv6) 'fdfe:dcba:9876::1/126',
          ],
          'mtu': snapshot.tun.mtu,
          'auto_route': snapshot.tun.autoRoute,
          'strict_route': snapshot.tun.strictRoute,
          'stack': snapshot.tun.stack,
        },
      ],
      'outbounds': <Map<String, Object>>[
        proxy,
        <String, Object>{'type': 'direct', 'tag': 'direct'},
      ],
      'route': <String, Object>{
        'auto_detect_interface': true,
        'default_domain_resolver': 'direct-dns',
        'rules': routeRules,
        'final': _finalOutbound(snapshot.finalAction, tag),
      },
      'experimental': <String, Object>{
        'clash_api': <String, Object>{
          'external_controller': '127.0.0.1:19090',
        },
      },
    };
  }

  String _finalOutbound(RouteAction action, String proxyTag) {
    return switch (action.type) {
      RouteActionType.proxy => action.outboundTag?.trim().isNotEmpty == true
          ? action.outboundTag!.trim()
          : proxyTag,
      RouteActionType.direct => 'direct',
      RouteActionType.block => throw const RoutingCompileException(
          'Block cannot be used as the final outbound',
        ),
    };
  }

  Map<String, Object> _compileDnsServer(
    String address, {
    required String tag,
    String? detour,
  }) {
    final normalized = address.trim();
    if (normalized == 'local') {
      return <String, Object>{'type': 'local', 'tag': tag};
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty) {
      throw OutboundCompileException('Invalid DNS server: $address');
    }
    final type = switch (uri.scheme) {
      'https' => 'https',
      'tls' => 'tls',
      'tcp' => 'tcp',
      'udp' || '' => 'udp',
      _ => throw OutboundCompileException(
          'Unsupported DNS transport: ${uri.scheme}',
        ),
    };
    return <String, Object>{
      'type': type,
      'tag': tag,
      'server': uri.host,
      if (uri.hasPort) 'server_port': uri.port,
      if (type == 'https' && uri.path.isNotEmpty) 'path': uri.path,
      if (detour != null) 'detour': detour,
    };
  }
}
