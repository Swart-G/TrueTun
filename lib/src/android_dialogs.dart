import 'package:flutter/material.dart';
import 'package:truetun/src/routing/routing_rule.dart';
import 'package:truetun/src/routing/routing_rule_editor.dart';

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
  return showRoutingRuleEditor(
    context,
    platform: RoutingPlatform.android,
    existing: existing,
  );
}
