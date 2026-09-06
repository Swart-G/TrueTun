import 'package:flutter_test/flutter_test.dart';
import 'package:truetun/src/apps/app_routing_policy.dart';
import 'package:truetun/src/profiles/profile_input_detector.dart';
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
}
