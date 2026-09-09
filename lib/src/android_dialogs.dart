import 'package:flutter/material.dart';
import 'package:truetun/src/routing/routing_rule.dart';

Future<String?> showTrueTunTextDialog(
  BuildContext context, {
  required String title,
  required String label,
  String? initialValue,
  int maxLines = 1,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextInputDialog(
      title: title,
      label: label,
      initialValue: initialValue,
      maxLines: maxLines,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.maxLines,
  });

  final String title;
  final String label;
  final String? initialValue;
  final int maxLines;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: widget.maxLines > 1 ? 2 : 1,
        maxLines: widget.maxLines,
        decoration: InputDecoration(labelText: widget.label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

Future<(String, String)?> showTrueTunSubscriptionDialog(BuildContext context) {
  return showDialog<(String, String)>(
    context: context,
    builder: (_) => const _SubscriptionDialog(),
  );
}

class _SubscriptionDialog extends StatefulWidget {
  const _SubscriptionDialog();

  @override
  State<_SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<_SubscriptionDialog> {
  final _name = TextEditingController();
  final _url = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add subscription'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'URL'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (_name.text, _url.text)),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

Future<RoutingRule?> showTrueTunRoutingRuleDialog(
  BuildContext context, {
  RoutingRule? existing,
}) {
  return showDialog<RoutingRule>(
    context: context,
    builder: (_) => _RoutingRuleDialog(existing: existing),
  );
}

class _RoutingRuleDialog extends StatefulWidget {
  const _RoutingRuleDialog({this.existing});

  final RoutingRule? existing;

  @override
  State<_RoutingRuleDialog> createState() => _RoutingRuleDialogState();
}

class _RoutingRuleDialogState extends State<_RoutingRuleDialog> {
  late final TextEditingController _name;
  late final TextEditingController _domains;
  late final TextEditingController _suffixes;
  late final TextEditingController _cidrs;
  late RouteActionType _action;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? 'New rule');
    _domains = TextEditingController(
      text: existing?.matcher.domains.join('\n') ?? '',
    );
    _suffixes = TextEditingController(
      text: existing?.matcher.domainSuffixes.join('\n') ?? '',
    );
    _cidrs = TextEditingController(
      text: existing?.matcher.ipCidrs.join('\n') ?? '',
    );
    _action = existing?.action.type ?? RouteActionType.proxy;
  }

  @override
  void dispose() {
    _name.dispose();
    _domains.dispose();
    _suffixes.dispose();
    _cidrs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add routing rule' : 'Edit routing rule',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _domains,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Exact domains'),
            ),
            TextField(
              controller: _suffixes,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Domain suffixes'),
            ),
            TextField(
              controller: _cidrs,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'IP CIDRs'),
            ),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _save() {
    final matcher = RuleMatcher(
      domains: _lines(_domains.text),
      domainSuffixes: _lines(_suffixes.text),
      ipCidrs: _lines(_cidrs.text),
    );
    if (_name.text.trim().isEmpty || matcher.isEmpty) return;

    final routeAction = switch (_action) {
      RouteActionType.proxy => const RouteAction.proxy('proxy'),
      RouteActionType.direct => const RouteAction.direct(),
      RouteActionType.block => const RouteAction.block(),
    };
    Navigator.pop(
      context,
      RoutingRule(
        id: widget.existing?.id ??
            'rule-${DateTime.now().microsecondsSinceEpoch}',
        name: _name.text.trim(),
        matcher: matcher,
        action: routeAction,
        enabled: widget.existing?.enabled ?? true,
      ),
    );
  }
}

List<String> _lines(String value) => value
    .split(RegExp(r'[,\n]'))
    .map((entry) => entry.trim())
    .where((entry) => entry.isNotEmpty)
    .toList(growable: false);
