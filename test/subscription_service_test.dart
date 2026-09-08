import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:truetun/src/profiles/subscription_service.dart';

void main() {
  const link = 'vless://00000000-0000-4000-8000-000000000000@example.com:443'
      '?security=tls&type=ws#Subscription%20node';

  test('parses base64 subscription and removes duplicate nodes', () {
    const service = SubscriptionService();
    final body = base64.encode(utf8.encode('$link\n$link\n'));
    final profiles = service.parse(body);
    expect(profiles, hasLength(1));
    expect(profiles.single.node.name, 'Subscription node');
  });

  test('parses mixed VLESS and Hysteria2 share-link subscription', () {
    const service = SubscriptionService();
    const hy2 = 'hy2://password@hy.example.com:443/?sni=hy.example.com#HY2';
    final profiles = service.parse('$link\n$hy2\n');
    expect(profiles, hasLength(2));
    expect(profiles.last.node.protocol.name, 'hysteria2');
  });

  test('parses Mihomo Hysteria2 YAML subscription', () {
    const service = SubscriptionService();
    final profiles = service.parse('''
proxies:
  - name: HY2 YAML
    type: hysteria2
    server: hy.example.com
    port: 443
    password: secret
    sni: hy.example.com
''');
    expect(profiles, hasLength(1));
    expect(profiles.single.node.name, 'HY2 YAML');
  });

  test('downloads a plain subscription', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final serving = server.first.then((request) async {
      request.response.write(link);
      await request.response.close();
    });
    final profiles = await const SubscriptionService().fetch(
      Uri.parse('http://127.0.0.1:${server.port}/subscription'),
    );
    await serving;
    await server.close(force: true);
    expect(profiles, hasLength(1));
  });
}
