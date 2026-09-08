import 'package:flutter_test/flutter_test.dart';
import 'package:truetun/src/core/connection_snapshot.dart';
import 'package:truetun/src/core/core_preferences.dart';
import 'package:truetun/src/core/sing_box_config_compiler.dart';
import 'package:truetun/src/core/sing_box_outbound_compiler.dart';
import 'package:truetun/src/profiles/vless_link_parser.dart';
import 'package:truetun/src/routing/routing_rule.dart';

void main() {
  const parser = VlessLinkParser();
  const compiler = SingBoxConfigCompiler();

  final node = parser.parse(
    'vless://00000000-0000-4000-8000-000000000000@vpn.example.com:443'
    '?security=tls&sni=vpn.example.com&type=ws&path=%2Fws',
  );

  test('Linux TUN config has anti-loop routing and conservative MTU', () {
    final config = compiler.compileMap(
      ConnectionSnapshot(node: node, platform: RoutingPlatform.linux),
    );

    final tun = (config['inbounds']! as List<Map<String, Object>>).single;
    expect(tun['auto_route'], isTrue);
    expect(tun['auto_redirect'], isTrue);
    expect(tun['mtu'], 1400);
    expect(tun['stack'], 'mixed');
    expect(tun['address'], ['172.19.0.1/30']);

    final route = config['route']! as Map<String, Object>;
    expect(route['auto_detect_interface'], isTrue);
    expect(route['default_domain_resolver'], 'dns-direct');
    expect(route['final'], 'proxy');

    final experimental = config['experimental']! as Map<String, Object>;
    final clashApi = experimental['clash_api']! as Map<String, Object>;
    expect(clashApi['external_controller'], '127.0.0.1:19090');
  });

  test('DNS bootstrap is direct and user DNS is proxied', () {
    final config = compiler.compileMap(
      ConnectionSnapshot(node: node, platform: RoutingPlatform.linux),
    );
    final dns = config['dns']! as Map<String, Object>;
    final servers = dns['servers']! as List<Map<String, Object>>;

    expect(servers[0]['tag'], 'dns-direct');
    expect(servers[0]['server'], '1.1.1.1');
    expect(servers[0].containsKey('detour'), isFalse);
    expect(servers[1]['tag'], 'dns-remote');
    expect(servers[1]['type'], 'https');
    expect(servers[1]['detour'], 'proxy');
    expect(dns['final'], 'dns-remote');
    expect(dns['strategy'], 'ipv4_only');
  });

  test('IPv6 is only advertised when explicitly enabled', () {
    final config = compiler.compileMap(
      ConnectionSnapshot(
        node: node,
        platform: RoutingPlatform.linux,
        preferences: const CorePreferences(ipv6: true),
      ),
    );
    final tun = (config['inbounds']! as List<Map<String, Object>>).single;
    expect(
      tun['address'],
      ['172.19.0.1/30', 'fdfe:dcba:9876::1/126'],
    );
    final dns = config['dns']! as Map<String, Object>;
    expect(dns['strategy'], 'prefer_ipv4');
  });

  test('VLESS packetEncoding=none is encoded in sing-box form', () {
    final noPacketEncoding = parser.parse(
      'vless://00000000-0000-4000-8000-000000000000@vpn.example.com:443'
      '?security=tls&type=tcp&packetEncoding=none',
    );
    final outbound = const SingBoxOutboundCompiler().compileVless(
      noPacketEncoding,
      tag: 'proxy',
    );
    expect(outbound['packet_encoding'], '');
  });

  test('invalid bootstrap DNS hostname is rejected before core startup', () {
    expect(
      () => compiler.compileMap(
        ConnectionSnapshot(
          node: node,
          platform: RoutingPlatform.linux,
          preferences: const CorePreferences(directDns: 'dns.example.com'),
        ),
      ),
      throwsA(isA<ConfigCompileException>()),
    );
  });
}
