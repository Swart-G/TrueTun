import 'package:flutter_test/flutter_test.dart';
import 'package:truetun/src/apps/app_routing_policy.dart';
import 'package:truetun/src/core/sing_box_outbound_compiler.dart';
import 'package:truetun/src/profiles/profile_input_detector.dart';
import 'package:truetun/src/profiles/proxy_node.dart';
import 'package:truetun/src/profiles/vless_link_parser.dart';
import 'package:truetun/src/routing/routing_rule.dart';
import 'package:truetun/src/routing/sing_box_routing_compiler.dart';

void main() {
  const compiler = SingBoxRoutingCompiler();

  test('compiles Android package rule to sing-box route rule', () {
    const rule = RoutingRule(
      id: 'telegram',
      name: 'Telegram through proxy',
      matcher: RuleMatcher(packageNames: ['org.telegram.messenger']),
      action: RouteAction.proxy('proxy-main'),
    );

    final result = compiler.compileRule(rule, platform: RoutingPlatform.android);

    expect(result['package_name'], ['org.telegram.messenger']);
    expect(result['action'], 'route');
    expect(result['outbound'], 'proxy-main');
  });

  test('refuses Android-only matcher on Linux', () {
    const rule = RoutingRule(
      id: 'android-only',
      name: 'Android only',
      matcher: RuleMatcher(packageNames: ['com.example.app']),
      action: RouteAction.direct(),
    );

    expect(
      () => compiler.compileRule(rule, platform: RoutingPlatform.linux),
      throwsA(isA<RoutingCompileException>()),
    );
  });

  test('compiles block rule using reject/drop', () {
    const rule = RoutingRule(
      id: 'ads',
      name: 'Block ads',
      matcher: RuleMatcher(domainSuffixes: ['example.invalid']),
      action: RouteAction.block(),
    );

    final result = compiler.compileRule(rule, platform: RoutingPlatform.android);
    expect(result['action'], 'reject');
    expect(result['method'], 'drop');
  });

  test('Android whitelist becomes include_package', () {
    const policy = AppRoutingPolicy(
      mode: AppRoutingMode.proxyOnlySelected,
      selectedPackageNames: {'org.telegram.messenger', 'app.truetun'},
    );

    final result = policy.toAndroidTunPatch(ownPackageName: 'app.truetun');
    expect(result['include_package'], ['org.telegram.messenger']);
  });

  test('detects VLESS share link', () {
    const detector = ProfileInputDetector();
    expect(
      detector.detect('vless://00000000-0000-0000-0000-000000000000@example.com:443'),
      ProfileInputKind.singleShareLink,
    );
  });

  test('parses VLESS Reality and compiles stable sing-box outbound', () {
    const parser = VlessLinkParser();
    const outboundCompiler = SingBoxOutboundCompiler();
    final node = parser.parse(
      'vless://00000000-0000-4000-8000-000000000000@vpn.example.com:443'
      '?security=reality&sni=www.example.com&fp=chrome&pbk=public-key&sid=0123'
      '&flow=xtls-rprx-vision&type=tcp#Reality%20node',
    );

    expect(node.name, 'Reality node');
    expect(node.transport.type, V2RayTransportType.tcp);
    expect(node.tls.reality?.publicKey, 'public-key');

    final outbound = outboundCompiler.compileVless(node, tag: 'node-1');
    expect(outbound['type'], 'vless');
    expect(outbound['flow'], 'xtls-rprx-vision');
    final tls = outbound['tls']! as Map<String, Object>;
    expect(tls['server_name'], 'www.example.com');
    expect(tls['reality'], isA<Map<String, Object>>());
  });

  test('preserves XHTTP import but refuses stable-core compilation', () {
    const parser = VlessLinkParser();
    const outboundCompiler = SingBoxOutboundCompiler();
    final node = parser.parse(
      'vless://00000000-0000-4000-8000-000000000000@vpn.example.com:443'
      '?security=reality&sni=www.example.com&pbk=public-key&type=xhttp&mode=stream-up',
    );

    expect(node.transport.type, V2RayTransportType.xhttp);
    expect(node.transport.mode, 'stream-up');
    expect(
      () => outboundCompiler.compileVless(node, tag: 'node-xhttp'),
      throwsA(isA<OutboundCompileException>()),
    );
  });
}
