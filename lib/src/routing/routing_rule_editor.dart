import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:truetun/src/routing/routing_rule.dart';

Future<RoutingRule?> showRoutingRuleEditor(
  BuildContext context, {
  required RoutingPlatform platform,
  RoutingRule? existing,
}) {
  return showDialog<RoutingRule>(
    context: context,
    builder: (_) => _RoutingRuleEditor(
      platform: platform,
      existing: existing,
    ),
  );
}

enum _MatcherKind {
  domain('Exact domain', 'example.com'),
  domainSuffix('Domain suffix', '.ru or .example.com'),
  domainKeyword('Domain keyword', 'example'),
  domainRegex('Domain regex', r'^.+\.example\.com$'),
  ipCidr('Destination IP / CIDR', '1.1.1.1/32'),
  sourceIpCidr('Source IP / CIDR', '192.168.1.0/24'),
  port('Destination port', '443'),
  portRange('Destination port range', '8000:9000'),
  sourcePort('Source port', '5353'),
  sourcePortRange('Source port range', '5000:6000'),
  protocol('Protocol', 'dns'),
  network('Network', 'tcp or udp'),
  ruleSet('Rule set', 'geoip-private'),
  packageName('Android package', 'org.example.app'),
  packageNameRegex('Android package regex', r'^org\.example\.'),
  processName('Process name', 'firefox'),
  processPath('Process path', '/usr/bin/firefox'),
  processPathRegex('Process path regex', r'^/opt/.+/app$');

  const _MatcherKind(this.label, this.hint);

  final String label;
  final String hint;

  bool supports(RoutingPlatform platform) => switch (this) {
        _MatcherKind.packageName ||
        _MatcherKind.packageNameRegex =>
          platform == RoutingPlatform.android,
        _MatcherKind.processName ||
        _MatcherKind.processPath ||
        _MatcherKind.processPathRegex =>
          platform == RoutingPlatform.linux,
        _ => true,
      };
}

class _Condition {
  const _Condition(this.kind, this.value);

  final _MatcherKind kind;
  final String value;
}

class _RoutingRuleEditor extends StatefulWidget {
  const _RoutingRuleEditor({
    required this.platform,
    this.existing,
  });

  final RoutingPlatform platform;
  final RoutingRule? existing;

  @override
  State<_RoutingRuleEditor> createState() => _RoutingRuleEditorState();
}

class _RoutingRuleEditorState extends State<_RoutingRuleEditor> {
  late final TextEditingController _name;
  late final TextEditingController _parameter;
  late final List<_Condition> _conditions;
  late _MatcherKind _kind;
  late RouteActionType _action;
  late bool _invert;
  String? _error;

  List<_MatcherKind> get _availableKinds => _MatcherKind.values
      .where((kind) => kind.supports(widget.platform))
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _parameter = TextEditingController();
    _conditions = _conditionsFrom(widget.existing?.matcher);
    _kind = _availableKinds.first;
    _action = widget.existing?.action.type ?? RouteActionType.proxy;
    _invert = widget.existing?.matcher.invert ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _parameter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add routing rule' : 'Edit routing rule',
      ),
      content: SizedBox(
        width: 660,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Rule name (optional)',
                  hintText: 'Generated from the first condition',
                ),
              ),
              const SizedBox(height: 16),
              Text('Conditions', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 520;
                  final type = DropdownButtonFormField<_MatcherKind>(
                    initialValue: _kind,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Rule type'),
                    items: [
                      for (final kind in _availableKinds)
                        DropdownMenuItem(
                          value: kind,
                          child: Text(kind.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _kind = value;
                        _error = null;
                      });
                    },
                  );
                  final parameter = TextField(
                    controller: _parameter,
                    autofocus: widget.existing == null,
                    inputFormatters: _kind == _MatcherKind.port ||
                            _kind == _MatcherKind.sourcePort
                        ? [FilteringTextInputFormatter.digitsOnly]
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Parameter',
                      hintText: _kind.hint,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addCondition(),
                  );
                  final add = FilledButton.icon(
                    onPressed: _addCondition,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  );
                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        type,
                        const SizedBox(height: 10),
                        parameter,
                        const SizedBox(height: 10),
                        add,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(flex: 4, child: type),
                      const SizedBox(width: 10),
                      Expanded(flex: 5, child: parameter),
                      const SizedBox(width: 10),
                      SizedBox(height: 48, child: add),
                    ],
                  );
                },
              ),
              if (_conditions.isNotEmpty) ...[
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      for (var index = 0; index < _conditions.length; index++)
                        ListTile(
                          dense: true,
                          title: Text(_conditions[index].value),
                          subtitle: Text(_conditions[index].kind.label),
                          trailing: IconButton(
                            tooltip: 'Remove condition',
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(
                              () => _conditions.removeAt(index),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<RouteActionType>(
                initialValue: _action,
                decoration: const InputDecoration(labelText: 'Action'),
                items: const [
                  DropdownMenuItem(
                    value: RouteActionType.proxy,
                    child: Text('Proxy'),
                  ),
                  DropdownMenuItem(
                    value: RouteActionType.direct,
                    child: Text('Direct'),
                  ),
                  DropdownMenuItem(
                    value: RouteActionType.block,
                    child: Text('Block'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _action = value);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Invert conditions'),
                value: _invert,
                onChanged: (value) => setState(() => _invert = value),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  void _addCondition() {
    final value = _parameter.text.trim();
    final validationError = _validate(_kind, value);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() {
      _conditions.add(_Condition(_kind, value));
      _parameter.clear();
      _error = null;
    });
  }

  String? _validate(_MatcherKind kind, String value) {
    if (value.isEmpty) return 'Enter a parameter before adding it.';
    if (kind == _MatcherKind.port || kind == _MatcherKind.sourcePort) {
      final port = int.tryParse(value);
      if (port == null || port < 1 || port > 65535) {
        return 'Port must be an integer between 1 and 65535.';
      }
    }
    if (kind == _MatcherKind.network && value != 'tcp' && value != 'udp') {
      return 'Network must be tcp or udp.';
    }
    return null;
  }

  void _save() {
    if (_conditions.isEmpty) {
      setState(() => _error = 'Add at least one condition.');
      return;
    }
    final matcher = _matcherFrom(_conditions, invert: _invert);
    final action = switch (_action) {
      RouteActionType.proxy => const RouteAction.proxy('proxy'),
      RouteActionType.direct => const RouteAction.direct(),
      RouteActionType.block => const RouteAction.block(),
    };
    final enteredName = _name.text.trim();
    final first = _conditions.first;
    Navigator.pop(
      context,
      RoutingRule(
        id: widget.existing?.id ??
            'rule-${DateTime.now().microsecondsSinceEpoch}',
        name: enteredName.isEmpty
            ? '${first.kind.label}: ${first.value}'
            : enteredName,
        matcher: matcher,
        action: action,
        enabled: widget.existing?.enabled ?? true,
      ),
    );
  }
}

List<_Condition> _conditionsFrom(RuleMatcher? matcher) {
  if (matcher == null) return [];
  final result = <_Condition>[];
  void add(_MatcherKind kind, Iterable<Object> values) {
    result.addAll(values.map((value) => _Condition(kind, value.toString())));
  }

  add(_MatcherKind.domain, matcher.domains);
  add(_MatcherKind.domainSuffix, matcher.domainSuffixes);
  add(_MatcherKind.domainKeyword, matcher.domainKeywords);
  add(_MatcherKind.domainRegex, matcher.domainRegexes);
  add(_MatcherKind.ipCidr, matcher.ipCidrs);
  add(_MatcherKind.sourceIpCidr, matcher.sourceIpCidrs);
  add(_MatcherKind.port, matcher.ports);
  add(_MatcherKind.portRange, matcher.portRanges);
  add(_MatcherKind.sourcePort, matcher.sourcePorts);
  add(_MatcherKind.sourcePortRange, matcher.sourcePortRanges);
  add(_MatcherKind.protocol, matcher.protocols);
  add(_MatcherKind.network, matcher.networks);
  add(_MatcherKind.ruleSet, matcher.ruleSets);
  add(_MatcherKind.packageName, matcher.packageNames);
  add(_MatcherKind.packageNameRegex, matcher.packageNameRegexes);
  add(_MatcherKind.processName, matcher.processNames);
  add(_MatcherKind.processPath, matcher.processPaths);
  add(_MatcherKind.processPathRegex, matcher.processPathRegexes);
  return result;
}

RuleMatcher _matcherFrom(
  List<_Condition> conditions, {
  required bool invert,
}) {
  List<String> strings(_MatcherKind kind) => conditions
      .where((condition) => condition.kind == kind)
      .map((condition) => condition.value)
      .toList(growable: false);
  List<int> ints(_MatcherKind kind) =>
      strings(kind).map(int.parse).toList(growable: false);

  return RuleMatcher(
    domains: strings(_MatcherKind.domain),
    domainSuffixes: strings(_MatcherKind.domainSuffix),
    domainKeywords: strings(_MatcherKind.domainKeyword),
    domainRegexes: strings(_MatcherKind.domainRegex),
    ipCidrs: strings(_MatcherKind.ipCidr),
    sourceIpCidrs: strings(_MatcherKind.sourceIpCidr),
    ports: ints(_MatcherKind.port),
    portRanges: strings(_MatcherKind.portRange),
    sourcePorts: ints(_MatcherKind.sourcePort),
    sourcePortRanges: strings(_MatcherKind.sourcePortRange),
    protocols: strings(_MatcherKind.protocol),
    networks: strings(_MatcherKind.network),
    ruleSets: strings(_MatcherKind.ruleSet),
    packageNames: strings(_MatcherKind.packageName),
    packageNameRegexes: strings(_MatcherKind.packageNameRegex),
    processNames: strings(_MatcherKind.processName),
    processPaths: strings(_MatcherKind.processPath),
    processPathRegexes: strings(_MatcherKind.processPathRegex),
    invert: invert,
  );
}
