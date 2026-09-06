import 'package:truetun/src/routing/routing_rule.dart';

class RoutingCompileException implements Exception {
  const RoutingCompileException(this.message);

  final String message;

  @override
  String toString() => 'RoutingCompileException: $message';
}

class SingBoxRoutingCompiler {
  const SingBoxRoutingCompiler();

  List<Map<String, Object>> compileRules(
    Iterable<RoutingRule> rules, {
    required RoutingPlatform platform,
  }) {
    return rules
        .where((rule) => rule.enabled)
        .map((rule) => compileRule(rule, platform: platform))
        .toList(growable: false);
  }

  Map<String, Object> compileRule(
    RoutingRule rule, {
    required RoutingPlatform platform,
  }) {
    if (rule.matcher.isEmpty) {
      throw RoutingCompileException(
          'Rule "${rule.name}" has no match conditions');
    }

    _verifyPlatformFields(rule, platform);

    final matcher = rule.matcher;
    final result = <String, Object>{};

    _putStrings(result, 'domain', matcher.domains);
    _putStrings(result, 'domain_suffix', matcher.domainSuffixes);
    _putStrings(result, 'domain_keyword', matcher.domainKeywords);
    _putStrings(result, 'domain_regex', matcher.domainRegexes);
    _putStrings(result, 'ip_cidr', matcher.ipCidrs);
    _putStrings(result, 'source_ip_cidr', matcher.sourceIpCidrs);
    _putInts(result, 'port', matcher.ports);
    _putStrings(result, 'port_range', matcher.portRanges);
    _putInts(result, 'source_port', matcher.sourcePorts);
    _putStrings(result, 'source_port_range', matcher.sourcePortRanges);
    _putStrings(result, 'protocol', matcher.protocols);
    _putStrings(result, 'network', matcher.networks);
    _putStrings(result, 'rule_set', matcher.ruleSets);

    if (platform == RoutingPlatform.android) {
      _putStrings(result, 'package_name', matcher.packageNames);
      _putStrings(result, 'package_name_regex', matcher.packageNameRegexes);
    }

    if (platform == RoutingPlatform.linux) {
      _putStrings(result, 'process_name', matcher.processNames);
      _putStrings(result, 'process_path', matcher.processPaths);
      _putStrings(result, 'process_path_regex', matcher.processPathRegexes);
    }

    if (matcher.invert) result['invert'] = true;

    switch (rule.action.type) {
      case RouteActionType.proxy:
        final tag = rule.action.outboundTag?.trim();
        if (tag == null || tag.isEmpty) {
          throw RoutingCompileException(
            'Proxy rule "${rule.name}" has no outbound tag',
          );
        }
        result['action'] = 'route';
        result['outbound'] = tag;
        break;
      case RouteActionType.direct:
        result['action'] = 'route';
        result['outbound'] = 'direct';
        break;
      case RouteActionType.block:
        result['action'] = 'reject';
        result['method'] = 'drop';
        break;
    }

    return result;
  }

  void _verifyPlatformFields(RoutingRule rule, RoutingPlatform platform) {
    final matcher = rule.matcher;
    final hasAndroidFields = matcher.packageNames.isNotEmpty ||
        matcher.packageNameRegexes.isNotEmpty;
    final hasLinuxFields = matcher.processNames.isNotEmpty ||
        matcher.processPaths.isNotEmpty ||
        matcher.processPathRegexes.isNotEmpty;

    if (hasAndroidFields && platform != RoutingPlatform.android) {
      throw RoutingCompileException(
        'Rule "${rule.name}" contains Android package matching but target is $platform',
      );
    }
    if (hasLinuxFields && platform != RoutingPlatform.linux) {
      throw RoutingCompileException(
        'Rule "${rule.name}" contains Linux process matching but target is $platform',
      );
    }
  }

  void _putStrings(
    Map<String, Object> target,
    String key,
    List<String> values,
  ) {
    if (values.isNotEmpty) target[key] = values;
  }

  void _putInts(Map<String, Object> target, String key, List<int> values) {
    if (values.isNotEmpty) target[key] = values;
  }
}
