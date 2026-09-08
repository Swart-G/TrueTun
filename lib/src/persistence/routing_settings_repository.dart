import 'dart:convert';

import 'package:truetun/src/apps/app_routing_policy.dart';
import 'package:truetun/src/persistence/app_database.dart';
import 'package:truetun/src/routing/routing_rule.dart';

class RoutingSettingsRepository {
  const RoutingSettingsRepository({required this.database});

  final AppDatabase database;

  Future<AppRoutingPolicy> loadAppRoutingPolicy() async {
    final raw = await database.readSetting('android_app_routing_policy');
    if (raw == null || raw.isEmpty) {
      return const AppRoutingPolicy(
        mode: AppRoutingMode.proxyAllExceptSelected,
      );
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final modeName = json['mode'] as String?;
    final mode = AppRoutingMode.values
        .where((value) => value.name == modeName)
        .firstOrNull;
    return AppRoutingPolicy(
      mode: mode ?? AppRoutingMode.proxyAllExceptSelected,
      selectedPackageNames:
          (json['packages'] as List<dynamic>? ?? const []).cast<String>().toSet(),
    );
  }

  Future<void> saveAppRoutingPolicy(AppRoutingPolicy policy) =>
      database.saveSetting(
        'android_app_routing_policy',
        jsonEncode({
          'mode': policy.mode.name,
          'packages': policy.selectedPackageNames.toList()..sort(),
        }),
      );

  Future<List<RoutingRule>> loadRoutingRules() async {
    final raw = await database.readSetting('routing_rules');
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map(_ruleFromJson)
        .toList(growable: false);
  }

  Future<void> saveRoutingRules(List<RoutingRule> rules) => database.saveSetting(
        'routing_rules',
        jsonEncode(rules.map(_ruleToJson).toList(growable: false)),
      );

  Map<String, Object?> _ruleToJson(RoutingRule rule) => {
        'id': rule.id,
        'name': rule.name,
        'enabled': rule.enabled,
        'action': rule.action.type.name,
        'outboundTag': rule.action.outboundTag,
        'matcher': {
          'domains': rule.matcher.domains,
          'domainSuffixes': rule.matcher.domainSuffixes,
          'domainKeywords': rule.matcher.domainKeywords,
          'domainRegexes': rule.matcher.domainRegexes,
          'ipCidrs': rule.matcher.ipCidrs,
          'sourceIpCidrs': rule.matcher.sourceIpCidrs,
          'ports': rule.matcher.ports,
          'portRanges': rule.matcher.portRanges,
          'sourcePorts': rule.matcher.sourcePorts,
          'sourcePortRanges': rule.matcher.sourcePortRanges,
          'protocols': rule.matcher.protocols,
          'networks': rule.matcher.networks,
          'ruleSets': rule.matcher.ruleSets,
          'packageNames': rule.matcher.packageNames,
          'packageNameRegexes': rule.matcher.packageNameRegexes,
          'processNames': rule.matcher.processNames,
          'processPaths': rule.matcher.processPaths,
          'processPathRegexes': rule.matcher.processPathRegexes,
          'invert': rule.matcher.invert,
        },
      };

  RoutingRule _ruleFromJson(Map<String, dynamic> json) {
    final matcher = json['matcher'] as Map<String, dynamic>? ?? const {};
    final actionType = RouteActionType.values
        .where((value) => value.name == json['action'])
        .firstOrNull;
    final action = switch (actionType) {
      RouteActionType.direct => const RouteAction.direct(),
      RouteActionType.block => const RouteAction.block(),
      _ => RouteAction.proxy((json['outboundTag'] as String?) ?? 'proxy'),
    };
    return RoutingRule(
      id: json['id'] as String? ?? 'rule-${DateTime.now().microsecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Rule',
      enabled: json['enabled'] != false,
      action: action,
      matcher: RuleMatcher(
        domains: _strings(matcher['domains']),
        domainSuffixes: _strings(matcher['domainSuffixes']),
        domainKeywords: _strings(matcher['domainKeywords']),
        domainRegexes: _strings(matcher['domainRegexes']),
        ipCidrs: _strings(matcher['ipCidrs']),
        sourceIpCidrs: _strings(matcher['sourceIpCidrs']),
        ports: _ints(matcher['ports']),
        portRanges: _strings(matcher['portRanges']),
        sourcePorts: _ints(matcher['sourcePorts']),
        sourcePortRanges: _strings(matcher['sourcePortRanges']),
        protocols: _strings(matcher['protocols']),
        networks: _strings(matcher['networks']),
        ruleSets: _strings(matcher['ruleSets']),
        packageNames: _strings(matcher['packageNames']),
        packageNameRegexes: _strings(matcher['packageNameRegexes']),
        processNames: _strings(matcher['processNames']),
        processPaths: _strings(matcher['processPaths']),
        processPathRegexes: _strings(matcher['processPathRegexes']),
        invert: matcher['invert'] == true,
      ),
    );
  }

  List<String> _strings(Object? raw) =>
      raw is List ? raw.map((value) => value.toString()).toList() : const [];

  List<int> _ints(Object? raw) => raw is List
      ? raw.whereType<num>().map((value) => value.toInt()).toList()
      : const [];
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
