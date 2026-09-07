import 'package:truetun/src/profiles/proxy_node.dart';
import 'package:truetun/src/routing/routing_rule.dart';

class DnsPolicy {
  const DnsPolicy({
    this.remoteServer = 'https://1.1.1.1/dns-query',
    this.directServer = 'local',
  });

  final String remoteServer;
  final String directServer;
}

class TunOptions {
  const TunOptions({
    this.interfaceName = 'truetun0',
    this.mtu = 9000,
    this.autoRoute = true,
    this.strictRoute = true,
    this.stack = 'mixed',
    this.ipv6 = true,
  });

  final String interfaceName;
  final int mtu;
  final bool autoRoute;
  final bool strictRoute;
  final String stack;
  final bool ipv6;
}

class ConnectionSnapshot {
  const ConnectionSnapshot({
    required this.node,
    required this.platform,
    this.nodeTag = 'proxy',
    this.rules = const [],
    this.finalAction = const RouteAction.proxy('proxy'),
    this.dns = const DnsPolicy(),
    this.tun = const TunOptions(),
    this.logLevel = 'info',
  });

  final ProxyNode node;
  final String nodeTag;
  final RoutingPlatform platform;
  final List<RoutingRule> rules;
  final RouteAction finalAction;
  final DnsPolicy dns;
  final TunOptions tun;
  final String logLevel;
}
