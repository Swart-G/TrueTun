import 'package:truetun/src/core/core_preferences.dart';
import 'package:truetun/src/profiles/proxy_node.dart';
import 'package:truetun/src/routing/routing_rule.dart';

class ConnectionSnapshot {
  const ConnectionSnapshot({
    required this.node,
    required this.platform,
    this.preferences = const CorePreferences(),
    this.routingRules = const [],
    this.routingSettings = const RoutingSettings(),
    this.androidTunPatch = const {},
  });

  final ProxyNode node;
  final RoutingPlatform platform;
  final CorePreferences preferences;
  final List<RoutingRule> routingRules;
  final RoutingSettings routingSettings;
  final Map<String, Object> androidTunPatch;
}
