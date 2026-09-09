enum RoutingPlatform {
  android,
  linux,
  other,
}

enum RouteActionType {
  proxy,
  direct,
  block,
}

class RoutingSettings {
  const RoutingSettings({
    this.enabled = false,
    this.fallbackAction = RouteActionType.proxy,
  });

  final bool enabled;
  final RouteActionType fallbackAction;

  RoutingSettings copyWith({
    bool? enabled,
    RouteActionType? fallbackAction,
  }) {
    return RoutingSettings(
      enabled: enabled ?? this.enabled,
      fallbackAction: fallbackAction ?? this.fallbackAction,
    );
  }
}

class RouteAction {
  const RouteAction._(this.type, this.outboundTag);

  const RouteAction.proxy(String outboundTag)
      : this._(RouteActionType.proxy, outboundTag);

  const RouteAction.direct() : this._(RouteActionType.direct, null);

  const RouteAction.block() : this._(RouteActionType.block, null);

  final RouteActionType type;
  final String? outboundTag;
}

class RuleMatcher {
  const RuleMatcher({
    this.domains = const [],
    this.domainSuffixes = const [],
    this.domainKeywords = const [],
    this.domainRegexes = const [],
    this.ipCidrs = const [],
    this.sourceIpCidrs = const [],
    this.ports = const [],
    this.portRanges = const [],
    this.sourcePorts = const [],
    this.sourcePortRanges = const [],
    this.protocols = const [],
    this.networks = const [],
    this.ruleSets = const [],
    this.packageNames = const [],
    this.packageNameRegexes = const [],
    this.processNames = const [],
    this.processPaths = const [],
    this.processPathRegexes = const [],
    this.invert = false,
  });

  final List<String> domains;
  final List<String> domainSuffixes;
  final List<String> domainKeywords;
  final List<String> domainRegexes;
  final List<String> ipCidrs;
  final List<String> sourceIpCidrs;
  final List<int> ports;
  final List<String> portRanges;
  final List<int> sourcePorts;
  final List<String> sourcePortRanges;
  final List<String> protocols;
  final List<String> networks;
  final List<String> ruleSets;

  /// Android-only route rule field.
  final List<String> packageNames;
  final List<String> packageNameRegexes;

  /// Desktop-only route rule fields.
  final List<String> processNames;
  final List<String> processPaths;
  final List<String> processPathRegexes;

  final bool invert;

  bool get isEmpty =>
      domains.isEmpty &&
      domainSuffixes.isEmpty &&
      domainKeywords.isEmpty &&
      domainRegexes.isEmpty &&
      ipCidrs.isEmpty &&
      sourceIpCidrs.isEmpty &&
      ports.isEmpty &&
      portRanges.isEmpty &&
      sourcePorts.isEmpty &&
      sourcePortRanges.isEmpty &&
      protocols.isEmpty &&
      networks.isEmpty &&
      ruleSets.isEmpty &&
      packageNames.isEmpty &&
      packageNameRegexes.isEmpty &&
      processNames.isEmpty &&
      processPaths.isEmpty &&
      processPathRegexes.isEmpty;
}

class RoutingRule {
  const RoutingRule({
    required this.id,
    required this.name,
    required this.matcher,
    required this.action,
    this.enabled = true,
  });

  final String id;
  final String name;
  final RuleMatcher matcher;
  final RouteAction action;
  final bool enabled;
}
