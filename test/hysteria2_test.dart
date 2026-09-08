import 'package:flutter_test/flutter_test.dart';
import 'package:truetun/src/core/sing_box_outbound_compiler.dart';
import 'package:truetun/src/profiles/hysteria2_profile_parser.dart';
import 'package:truetun/src/profiles/proxy_node.dart';

void main() {
  const parser = Hysteria2ProfileParser();

  test('parses Hysteria2 URI including port hopping and obfs', () {
    final node = parser.parse(
      'hysteria2://user%3Apassword@example.com:443,5000-5002/'
      '?sni=cdn.example.com&insecure=1&obfs=salamander&obfs-password=secret'
      '#Fast%20HY2',
    );

    expect(node.name, 'Fast HY2');
    expect(node.server, 'example.com');
    expect(node.port, 443);
    expect(node.serverPorts, ['443', '5000:5002']);
    expect(node.password, 'user:password');
    expect(node.tls.serverName, 'cdn.example.com');
    expect(node.tls.insecure, isTrue);
    expect(node.obfs?.type, 'salamander');
    expect(node.obfs?.password, 'secret');
  });

  test('parses official Hysteria2 YAML config', () {
    final node = parser.parse('''
server: vpn.example.com:8443
auth: super-secret
tls:
  sni: edge.example.com
  insecure: false
obfs:
  type: salamander
  salamander:
    password: obfs-secret
bandwidth:
  up: 50 mbps
  down: 200 mbps
''');

    expect(node.server, 'vpn.example.com');
    expect(node.port, 8443);
    expect(node.password, 'super-secret');
    expect(node.upMbps, 50);
    expect(node.downMbps, 200);
    expect(node.obfs?.password, 'obfs-secret');
  });

  test('compiles Hysteria2 to sing-box outbound', () {
    final node = parser.parse(
      'hy2://password@example.com:443/?sni=example.com'
      '&obfs=gecko&obfs-password=obfs&obfs-min-packet-size=600'
      '&obfs-max-packet-size=1100',
    );
    final outbound =
        const SingBoxOutboundCompiler().compile(node, tag: 'proxy');

    expect(outbound['type'], 'hysteria2');
    expect(outbound['server'], 'example.com');
    expect(outbound['server_port'], 443);
    expect(outbound['password'], 'password');
    final tls = outbound['tls']! as Map<String, Object>;
    expect(tls['server_name'], 'example.com');
    final obfs = outbound['obfs']! as Map<String, Object>;
    expect(obfs['type'], 'gecko');
    expect(obfs['min_packet_size'], 600);
    expect(obfs['max_packet_size'], 1100);
  });

  test('rejects Hysteria2 pinSHA256 instead of silently weakening TLS', () {
    expect(
      () => parser.parse(
        'hy2://password@example.com:443/?pinSHA256=AA%3ABB%3ACC',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('parses Mihomo Hysteria2 proxy entry', () {
    final nodes = parser.parseMany('''
proxies:
  - name: mihomo-hy2
    type: hysteria2
    server: hy.example.com
    port: 443
    password: pass
    sni: hy.example.com
    skip-cert-verify: false
    obfs: salamander
    obfs-password: mask
    up: 30
    down: 100
''');

    expect(nodes, hasLength(1));
    expect(nodes.single.name, 'mihomo-hy2');
    expect(nodes.single.protocol, ProxyProtocol.hysteria2);
    expect(nodes.single.obfs?.password, 'mask');
  });
}
