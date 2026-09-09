import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:truetun/src/apps/app_routing_policy.dart';
import 'package:truetun/src/core/sing_box_outbound_compiler.dart';
import 'package:truetun/src/core/connection_snapshot.dart';
import 'package:truetun/src/core/log_redactor.dart';
import 'package:truetun/src/core/sing_box_config_compiler.dart';
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

    final result =
        compiler.compileRule(rule, platform: RoutingPlatform.android);

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

    final result =
        compiler.compileRule(rule, platform: RoutingPlatform.android);
    expect(result['action'], 'reject');
    expect(result['method'], 'drop');
  });

  test('normalizes a bare top-level suffix for sing-box', () {
    const rule = RoutingRule(
      id: 'ru-direct',
      name: 'Russian domains direct',
      matcher: RuleMatcher(domainSuffixes: ['ru']),
      action: RouteAction.direct(),
    );

    final result =
        compiler.compileRule(rule, platform: RoutingPlatform.android);

    expect(result['domain_suffix'], ['.ru']);
  });

  test('Android whitelist includes selected app and TrueTun diagnostics', () {
    const policy = AppRoutingPolicy(
      mode: AppRoutingMode.proxyOnlySelected,
      selectedPackageNames: {'org.telegram.messenger', 'app.truetun'},
    );

    final result = policy.toAndroidTunPatch(ownPackageName: 'app.truetun');
    expect(
      result['include_package'],
      ['app.truetun', 'org.telegram.messenger'],
    );
  });

  test('detects VLESS share link', () {
    const detector = ProfileInputDetector();
    expect(
      detector.detect(
          'vless://00000000-0000-0000-0000-000000000000@example.com:443'),
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

  test('preserves and compiles XHTTP for the extended core', () {
    const parser = VlessLinkParser();
    const outboundCompiler = SingBoxOutboundCompiler();
    final node = parser.parse(
      'vless://00000000-0000-4000-8000-000000000000@vpn.example.com:443'
      '?security=reality&sni=www.example.com&pbk=public-key&type=xhttp&mode=stream-up',
    );

    expect(node.transport.type, V2RayTransportType.xhttp);
    expect(node.transport.mode, 'stream-up');
    final outbound = outboundCompiler.compileVless(node, tag: 'node-xhttp');
    final transport = outbound['transport']! as Map<String, Object>;
    expect(transport['type'], 'xhttp');
    expect(transport['mode'], 'stream-up');
  });

  test('preserves unknown VLESS query parameters', () {
    const parser = VlessLinkParser();
    final node = parser.parse(
      'vless://00000000-0000-4000-8000-000000000000@vpn.example.com:443'
      '?security=tls&type=ws&futureOption=value',
    );
    expect(node.extensions, {'futureOption': 'value'});
  });

  test('compiles a complete TUN configuration', () {
    const parser = VlessLinkParser();
    const configCompiler = SingBoxConfigCompiler();
    final node = parser.parse(
      'vless://00000000-0000-4000-8000-000000000000@vpn.example.com:443'
      '?security=tls&sni=vpn.example.com&type=ws&path=%2Fws',
    );
    final config = configCompiler.compileMap(
      ConnectionSnapshot(node: node, platform: RoutingPlatform.linux),
    );
    expect(config['inbounds'], isNotEmpty);
    expect(config['outbounds'], isNotEmpty);
    final route = config['route']! as Map<String, Object>;
    expect(route['final'], 'proxy');
    final rules = route['rules']! as List<Map<String, Object>>;
    expect(rules.first['action'], 'sniff');
    expect(rules.first['sniffer'], ['http', 'tls', 'quic', 'dns']);
    expect(rules[1]['port'], [53]);
    expect(rules[1]['action'], 'hijack-dns');
  });

  test('custom rules are omitted while routing mode is disabled', () {
    const parser = VlessLinkParser();
    const configCompiler = SingBoxConfigCompiler();
    final node = parser.parse(
      'vless://00000000-0000-4000-8000-000000000000@vpn.example.com:443'
      '?security=tls&type=tcp',
    );
    final config = configCompiler.compileMap(
      ConnectionSnapshot(
        node: node,
        platform: RoutingPlatform.linux,
        routingRules: const [
          RoutingRule(
            id: 'direct-example',
            name: 'Direct example',
            matcher: RuleMatcher(domains: ['example.com']),
            action: RouteAction.direct(),
          ),
        ],
      ),
    );

    final route = config['route']! as Map<String, Object>;
    final rules = route['rules']! as List<Map<String, Object>>;
    expect(rules, hasLength(3));
    expect(route['final'], 'proxy');
  });

  test('routing mode compiles rules and direct fallback', () {
    const parser = VlessLinkParser();
    const configCompiler = SingBoxConfigCompiler();
    final node = parser.parse(
      'vless://00000000-0000-4000-8000-000000000000@vpn.example.com:443'
      '?security=tls&type=tcp',
    );
    final config = configCompiler.compileMap(
      ConnectionSnapshot(
        node: node,
        platform: RoutingPlatform.linux,
        routingSettings: const RoutingSettings(
          enabled: true,
          fallbackAction: RouteActionType.direct,
        ),
        routingRules: const [
          RoutingRule(
            id: 'proxy-example',
            name: 'Proxy example',
            matcher: RuleMatcher(domains: ['example.com']),
            action: RouteAction.proxy('proxy'),
          ),
        ],
      ),
    );

    final route = config['route']! as Map<String, Object>;
    final rules = route['rules']! as List<Map<String, Object>>;
    expect(rules, hasLength(4));
    expect(rules.last['domain'], ['example.com']);
    expect(route['final'], 'direct');
  });

  test('block fallback is emitted as a valid final catch-all rule', () async {
    const parser = VlessLinkParser();
    const configCompiler = SingBoxConfigCompiler();
    final node = parser.parse(
      'vless://00000000-0000-4000-8000-000000000000@vpn.example.com:443'
      '?security=tls&type=tcp',
    );
    final config = configCompiler.compileMap(
      ConnectionSnapshot(
        node: node,
        platform: RoutingPlatform.linux,
        routingSettings: const RoutingSettings(
          enabled: true,
          fallbackAction: RouteActionType.block,
        ),
      ),
    );

    final route = config['route']! as Map<String, Object>;
    final rules = route['rules']! as List<Map<String, Object>>;
    expect(rules.last['action'], 'reject');
    expect(rules.last['method'], 'drop');

    final executable = Platform.environment['SING_BOX_BIN'];
    if (executable == null) return;
    final directory = await Directory.systemTemp.createTemp('truetun-block-');
    try {
      final file = File('${directory.path}/config.json');
      await file.writeAsString(jsonEncode(config));
      final result = await Process.run(executable, ['check', '-c', file.path]);
      expect(result.exitCode, 0, reason: result.stderr.toString());
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('pinned sing-box accepts a compiled TUN configuration', () async {
    final executable = Platform.environment['SING_BOX_BIN'];
    if (executable == null) return;

    const parser = VlessLinkParser();
    const configCompiler = SingBoxConfigCompiler();
    final node = parser.parse(
      'vless://00000000-0000-4000-8000-000000000000@vpn.example.com:443'
      '?security=tls&sni=vpn.example.com&type=ws&path=%2Fws',
    );
    final config = configCompiler.compileMap(
      ConnectionSnapshot(node: node, platform: RoutingPlatform.linux),
    );
    final directory = await Directory.systemTemp.createTemp('truetun-test-');
    try {
      final file = File('${directory.path}/config.json');
      await file.writeAsString(jsonEncode(config));
      final result = await Process.run(executable, ['check', '-c', file.path]);
      expect(result.exitCode, 0, reason: result.stderr.toString());
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('extended sing-box accepts a compiled XHTTP configuration', () async {
    final executable = Platform.environment['SING_BOX_BIN'];
    if (executable == null) return;

    const parser = VlessLinkParser();
    const configCompiler = SingBoxConfigCompiler();
    final node = parser.parse(
      'vless://00000000-0000-4000-8000-000000000000@vpn.example.com:443'
      '?security=tls&sni=vpn.example.com&type=xhttp&mode=stream-up'
      '&host=vpn.example.com&path=%2Fxhttp',
    );
    final config = configCompiler.compileMap(
      ConnectionSnapshot(node: node, platform: RoutingPlatform.linux),
    );
    final directory = await Directory.systemTemp.createTemp('truetun-xhttp-');
    try {
      final file = File('${directory.path}/config.json');
      await file.writeAsString(jsonEncode(config));
      final result = await Process.run(executable, ['check', '-c', file.path]);
      expect(result.exitCode, 0, reason: result.stderr.toString());
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('redacts credentials and sensitive query values', () {
    const redactor = LogRedactor();
    final output = redactor.redact(
      'vless://00000000-0000-4000-8000-000000000000@example.com?token=secret',
    );
    expect(output, isNot(contains('00000000-0000-4000-8000-000000000000')));
    expect(output, isNot(contains('secret')));
    expect(const LogRedactor().redact('\x1b[36mINFO\x1b[0m'), 'INFO');
  });
}
