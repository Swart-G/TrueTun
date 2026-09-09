import 'package:flutter_test/flutter_test.dart';
import 'package:truetun/src/apps/app_routing_policy.dart';
import 'package:truetun/src/core/connection_snapshot.dart';
import 'package:truetun/src/core/sing_box_config_compiler.dart';
import 'package:truetun/src/profiles/vless_link_parser.dart';
import 'package:truetun/src/routing/routing_rule.dart';

void main() {
  const ownPackage = 'app.truetun';

  test('Android include mode includes TrueTun diagnostics in VPN', () {
    const policy = AppRoutingPolicy(
      mode: AppRoutingMode.proxyOnlySelected,
      selectedPackageNames: {'org.telegram.messenger'},
    );
    final patch = policy.toAndroidTunPatch(ownPackageName: ownPackage);
    expect(
      patch['include_package'],
      ['app.truetun', 'org.telegram.messenger'],
    );
  });

  test('Android exclude mode never excludes TrueTun itself', () {
    const policy = AppRoutingPolicy(
      mode: AppRoutingMode.proxyAllExceptSelected,
      selectedPackageNames: {'app.truetun', 'com.example.bank'},
    );
    final patch = policy.toAndroidTunPatch(ownPackageName: ownPackage);
    expect(patch['exclude_package'], ['com.example.bank']);
  });

  test('Android config enables interface detection and native package filter', () {
    final node = const VlessLinkParser().parse(
      'vless://00000000-0000-4000-8000-000000000000@vpn.example.com:443'
      '?security=tls&sni=vpn.example.com&type=ws&path=%2Fws',
    );
    final config = const SingBoxConfigCompiler().compileMap(
      ConnectionSnapshot(
        node: node,
        platform: RoutingPlatform.android,
        androidTunPatch: {
          'include_package': ['app.truetun', 'org.telegram.messenger'],
          'include_android_user': [0],
        },
      ),
    );

    final tun = (config['inbounds']! as List<Map<String, Object>>).single;
    expect(tun.containsKey('interface_name'), isFalse);
    expect(tun.containsKey('strict_route'), isFalse);
    expect(tun['include_package'], ['app.truetun', 'org.telegram.messenger']);
    expect(tun.containsKey('include_android_user'), isFalse);

    final route = config['route']! as Map<String, Object>;
    expect(route['auto_detect_interface'], isTrue);
    expect(config.containsKey('experimental'), isFalse);
  });
}
