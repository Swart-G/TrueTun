import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:truetun/src/application/app_state.dart';
import 'package:truetun/src/core/core_adapter.dart';
import 'package:truetun/src/core/core_preferences.dart';
import 'package:truetun/src/profiles/profile_group.dart';
import 'package:truetun/src/routing/routing_rule.dart';

class TrueTunLinuxApp extends StatelessWidget {
  const TrueTunLinuxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrueTun',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF625BFF)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8D87FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const _LinuxShell(),
    );
  }
}

class _LinuxShell extends StatefulWidget {
  const _LinuxShell();

  @override
  State<_LinuxShell> createState() => _LinuxShellState();
}

class _LinuxShellState extends State<_LinuxShell> {
  int _index = 0;

  static const _pages = <Widget>[
    _HomePage(),
    _ProfilesPage(),
    _RoutingPage(),
    _ProcessesPage(),
    _LogsPage(),
    _SettingsPage(),
  ];

  static const _destinations = <NavigationDestination>[
    NavigationDestination(icon: Icon(Icons.shield_outlined), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.dns_outlined), label: 'Profiles'),
    NavigationDestination(icon: Icon(Icons.alt_route), label: 'Routing'),
    NavigationDestination(icon: Icon(Icons.memory_outlined), label: 'Processes'),
    NavigationDestination(icon: Icon(Icons.article_outlined), label: 'Logs'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Scaffold(
            body: SafeArea(child: _pages[_index]),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              destinations: _destinations,
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
              onDestinationSelected: (value) => setState(() => _index = value),
            ),
          );
        }
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.shield_outlined),
                    ),
                  ),
                  destinations: _destinations
                      .map(
                        (item) => NavigationRailDestination(
                          icon: item.icon,
                          selectedIcon: item.selectedIcon,
                          label: Text(item.label),
                        ),
                      )
                      .toList(growable: false),
                  onDestinationSelected: (value) => setState(() => _index = value),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _pages[_index]),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomePage extends ConsumerWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(
      appControllerProvider.select(
        (state) => (
          node: state.node,
          coreState: state.coreState,
          error: state.error,
          latency: state.latency,
          upload: state.upload,
          download: state.download,
          trafficHistory: state.trafficHistory,
          testing: state.testing,
        ),
      ),
    );
    final controller = ref.read(appControllerProvider.notifier);
    final running = data.coreState == ProxyCoreState.running;
    final busy = data.coreState == ProxyCoreState.starting ||
        data.coreState == ProxyCoreState.stopping;
    final sample = data.trafficHistory.isEmpty ? null : data.trafficHistory.last;

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Row(
          children: [
            Text('TrueTun', style: Theme.of(context).textTheme.headlineLarge),
            const Spacer(),
            _StatusChip(state: data.coreState),
          ],
        ),
        const SizedBox(height: 30),
        Center(
          child: FilledButton(
            style: FilledButton.styleFrom(
              fixedSize: const Size(178, 178),
              shape: const CircleBorder(),
              backgroundColor: running ? Colors.green.shade700 : null,
            ),
            onPressed: data.node == null || busy
                ? null
                : running
                    ? controller.disconnect
                    : controller.connect,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  running ? Icons.shield : Icons.power_settings_new,
                  size: 48,
                ),
                const SizedBox(height: 10),
                Text(
                  data.node == null
                      ? 'NO PROFILE'
                      : running
                          ? 'PROXY ON'
                          : busy
                              ? data.coreState.name.toUpperCase()
                              : 'PROXY OFF',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          data.node?.name ?? 'Choose a profile to connect',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (data.node != null)
          Text(
            '${data.node!.protocol.name.toUpperCase()} · ${data.node!.server}:${data.node!.port}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (data.error != null) ...[
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(data.error!),
            ),
          ),
        ],
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = <Widget>[
              _MetricCard(
                icon: Icons.download,
                title: 'Download',
                value: _formatRate(sample?.downloadPerSecond ?? 0),
                detail: _formatBytes(data.download),
              ),
              _MetricCard(
                icon: Icons.upload,
                title: 'Upload',
                value: _formatRate(sample?.uploadPerSecond ?? 0),
                detail: _formatBytes(data.upload),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.network_check),
                  title: const Text('Connection test'),
                  subtitle: Text(
                    data.latency == null
                        ? 'Not measured'
                        : '${data.latency!.inMilliseconds} ms',
                  ),
                  trailing: data.testing
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: running && !data.testing ? controller.testConnection : null,
                ),
              ),
            ];
            if (constraints.maxWidth >= 850) {
              return Row(
                children: [
                  for (var index = 0; index < cards.length; index++) ...[
                    Expanded(child: cards[index]),
                    if (index != cards.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            }
            return Column(
              children: [
                for (final card in cards) ...[
                  SizedBox(width: double.infinity, child: card),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Live traffic', style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    Text(
                      '↓ ${_formatRate(sample?.downloadPerSecond ?? 0)}  '
                      '↑ ${_formatRate(sample?.uploadPerSecond ?? 0)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RepaintBoundary(
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: _TrafficChart(samples: data.trafficHistory),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.state});

  final ProxyCoreState state;

  @override
  Widget build(BuildContext context) {
    final running = state == ProxyCoreState.running;
    return Chip(
      avatar: Icon(
        running ? Icons.check_circle : Icons.circle_outlined,
        size: 18,
      ),
      label: Text(state.name),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                  Text(value, style: Theme.of(context).textTheme.titleMedium),
                  Text(detail, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrafficChart extends StatelessWidget {
  const _TrafficChart({required this.samples});

  final List<TrafficSample> samples;

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) {
      return const Center(child: Text('Traffic samples will appear after connection'));
    }
    final visible = samples.length <= 120
        ? samples
        : samples.sublist(samples.length - 120);
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _TrafficChartPainter(
        samples: visible,
        downloadColor: scheme.primary,
        uploadColor: scheme.tertiary,
        gridColor: scheme.outlineVariant.withValues(alpha: 0.55),
      ),
    );
  }
}

class _TrafficChartPainter extends CustomPainter {
  const _TrafficChartPainter({
    required this.samples,
    required this.downloadColor,
    required this.uploadColor,
    required this.gridColor,
  });

  final List<TrafficSample> samples;
  final Color downloadColor;
  final Color uploadColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || samples.isEmpty) return;
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var index = 1; index < 4; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    var maximum = 1;
    for (final sample in samples) {
      maximum = math.max(maximum, sample.downloadPerSecond);
      maximum = math.max(maximum, sample.uploadPerSecond);
    }
    final download = Path();
    final upload = Path();
    final denominator = math.max(1, samples.length - 1);
    for (var index = 0; index < samples.length; index++) {
      final x = size.width * index / denominator;
      final dy = size.height * (1 - samples[index].downloadPerSecond / maximum);
      final uy = size.height * (1 - samples[index].uploadPerSecond / maximum);
      if (index == 0) {
        download.moveTo(x, dy);
        upload.moveTo(x, uy);
      } else {
        download.lineTo(x, dy);
        upload.lineTo(x, uy);
      }
    }
    canvas.drawPath(
      download,
      Paint()
        ..color = downloadColor
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      upload,
      Paint()
        ..color = uploadColor
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _TrafficChartPainter oldDelegate) =>
      oldDelegate.samples != samples ||
      oldDelegate.downloadColor != downloadColor ||
      oldDelegate.uploadColor != uploadColor ||
      oldDelegate.gridColor != gridColor;
}

class _ProfilesPage extends ConsumerWidget {
  const _ProfilesPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(
      appControllerProvider.select(
        (state) => (
          groups: state.groups,
          selectedGroupId: state.selectedGroupId,
          selectedProfileId: state.selectedProfileId,
          profilePings: state.profilePings,
          pingingProfiles: state.pingingProfiles,
        ),
      ),
    );
    final controller = ref.read(appControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
        actions: [
          FilledButton.icon(
            onPressed: () => _showAddProfileMenu(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: data.groups.isEmpty
          ? const Center(child: Text('Add a proxy link or subscription'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.groups.length,
              itemBuilder: (context, index) {
                final group = data.groups[index];
                return Card(
                  child: ExpansionTile(
                    initiallyExpanded: group.id == data.selectedGroupId,
                    title: Text(group.name),
                    subtitle: Text(
                      group.updating
                          ? 'Updating…'
                          : '${group.profiles.length} profiles',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'refresh') {
                          controller.refreshGroup(group.id);
                        } else if (action == 'test') {
                          controller.testGroup(group.id);
                        } else if (action == 'delete') {
                          controller.deleteGroup(group.id);
                        }
                      },
                      itemBuilder: (context) => [
                        if (group.isSubscription)
                          const PopupMenuItem(
                            value: 'refresh',
                            child: Text('Refresh'),
                          ),
                        const PopupMenuItem(value: 'test', child: Text('Test all')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    children: [
                      if (group.error != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            group.error!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      for (final profile in group.profiles)
                        ListTile(
                          selected: data.selectedProfileId == profile.id,
                          leading: Icon(
                            data.selectedProfileId == profile.id
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                          ),
                          title: Text(profile.node.name),
                          subtitle: Text(
                            '${profile.node.protocol.name.toUpperCase()} · '
                            '${profile.node.server}:${profile.node.port}',
                          ),
                          trailing: TextButton(
                            onPressed: data.pingingProfiles.contains(profile.id)
                                ? null
                                : () => controller.testProfile(profile.id),
                            child: data.pingingProfiles.contains(profile.id)
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(_pingLabel(data.profilePings[profile.id])),
                          ),
                          onTap: () => controller.selectProfile(group.id, profile.id),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

Future<void> _showAddProfileMenu(BuildContext context, WidgetRef ref) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Import proxy link / config'),
            onTap: () => Navigator.pop(sheetContext, 'profile'),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('Add subscription'),
            onTap: () => Navigator.pop(sheetContext, 'subscription'),
          ),
          ListTile(
            leading: const Icon(Icons.create_new_folder_outlined),
            title: const Text('Create empty group'),
            onTap: () => Navigator.pop(sheetContext, 'group'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted || action == null) return;

  if (action == 'profile') {
    final input = await showDialog<String>(
      context: context,
      builder: (_) => const _PromptDialog(
        title: 'Import proxy',
        label: 'VLESS / Hysteria2 link or config',
        maxLines: 6,
      ),
    );
    if (input != null && input.trim().isNotEmpty) {
      ref.read(appControllerProvider.notifier).importProfile(input);
    }
  } else if (action == 'group') {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _PromptDialog(title: 'Create group', label: 'Name'),
    );
    if (name != null) ref.read(appControllerProvider.notifier).createGroup(name);
  } else if (action == 'subscription') {
    final subscription = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _SubscriptionDialog(),
    );
    if (subscription != null) {
      await ref.read(appControllerProvider.notifier).addSubscription(
            subscription.$1,
            subscription.$2,
          );
    }
  }
}

class _PromptDialog extends StatefulWidget {
  const _PromptDialog({
    required this.title,
    required this.label,
    this.initialValue,
    this.maxLines = 1,
  });

  final String title;
  final String label;
  final String? initialValue;
  final int maxLines;

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
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
      content: SizedBox(
        width: 520,
        child: TextField(
          controller: _controller,
          autofocus: true,
          minLines: widget.maxLines > 1 ? 2 : 1,
          maxLines: widget.maxLines,
          decoration: InputDecoration(labelText: widget.label),
        ),
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
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _url,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'URL'),
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
          onPressed: () => Navigator.pop(context, (_name.text, _url.text)),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _RoutingPage extends ConsumerWidget {
  const _RoutingPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(
      appControllerProvider.select((state) => state.routingRules),
    );
    final controller = ref.read(appControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routing'),
        actions: [
          FilledButton.icon(
            onPressed: () async {
              final rule = await showDialog<RoutingRule>(
                context: context,
                builder: (_) => const _RoutingRuleDialog(),
              );
              if (rule != null) await controller.addRoutingRule(rule);
            },
            icon: const Icon(Icons.add),
            label: const Text('Rule'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: rules.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'Rules are evaluated from top to bottom. Without custom rules, traffic uses the selected proxy.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
                return Card(
                  child: ListTile(
                    enabled: rule.enabled,
                    leading: Icon(_actionIcon(rule.action.type)),
                    title: Text(rule.name),
                    subtitle: Text('${_ruleSummary(rule)} → ${_actionLabel(rule.action)}'),
                    onTap: () async {
                      final updated = await showDialog<RoutingRule>(
                        context: context,
                        builder: (_) => _RoutingRuleDialog(existing: rule),
                      );
                      if (updated != null) await controller.updateRoutingRule(updated);
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'up' && index > 0) {
                          await controller.reorderRoutingRule(index, index - 1);
                        } else if (action == 'down' && index < rules.length - 1) {
                          await controller.reorderRoutingRule(index, index + 2);
                        } else if (action == 'toggle') {
                          await controller.updateRoutingRule(
                            RoutingRule(
                              id: rule.id,
                              name: rule.name,
                              matcher: rule.matcher,
                              action: rule.action,
                              enabled: !rule.enabled,
                            ),
                          );
                        } else if (action == 'delete') {
                          await controller.deleteRoutingRule(rule.id);
                        }
                      },
                      itemBuilder: (context) => [
                        if (index > 0)
                          const PopupMenuItem(value: 'up', child: Text('Move up')),
                        if (index < rules.length - 1)
                          const PopupMenuItem(value: 'down', child: Text('Move down')),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(rule.enabled ? 'Disable' : 'Enable'),
                        ),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
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
  late final TextEditingController _keywords;
  late final TextEditingController _regexes;
  late final TextEditingController _cidrs;
  late final TextEditingController _ports;
  late final TextEditingController _protocols;
  late final TextEditingController _networks;
  late final TextEditingController _processNames;
  late final TextEditingController _processPaths;
  late final TextEditingController _processRegexes;
  late RouteActionType _action;
  late bool _invert;
  String? _error;

  @override
  void initState() {
    super.initState();
    final matcher = widget.existing?.matcher ?? const RuleMatcher();
    _name = TextEditingController(text: widget.existing?.name ?? 'New rule');
    _domains = TextEditingController(text: matcher.domains.join('\n'));
    _suffixes = TextEditingController(text: matcher.domainSuffixes.join('\n'));
    _keywords = TextEditingController(text: matcher.domainKeywords.join('\n'));
    _regexes = TextEditingController(text: matcher.domainRegexes.join('\n'));
    _cidrs = TextEditingController(text: matcher.ipCidrs.join('\n'));
    _ports = TextEditingController(text: matcher.ports.join(','));
    _protocols = TextEditingController(text: matcher.protocols.join(','));
    _networks = TextEditingController(text: matcher.networks.join(','));
    _processNames = TextEditingController(text: matcher.processNames.join('\n'));
    _processPaths = TextEditingController(text: matcher.processPaths.join('\n'));
    _processRegexes = TextEditingController(text: matcher.processPathRegexes.join('\n'));
    _action = widget.existing?.action.type ?? RouteActionType.proxy;
    _invert = matcher.invert;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _domains,
      _suffixes,
      _keywords,
      _regexes,
      _cidrs,
      _ports,
      _protocols,
      _networks,
      _processNames,
      _processPaths,
      _processRegexes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add routing rule' : 'Edit routing rule'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              _TwoFields(
                left: TextField(
                  controller: _domains,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Exact domains'),
                ),
                right: TextField(
                  controller: _suffixes,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Domain suffixes'),
                ),
              ),
              const SizedBox(height: 10),
              _TwoFields(
                left: TextField(
                  controller: _keywords,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Domain keywords'),
                ),
                right: TextField(
                  controller: _regexes,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Domain regexes'),
                ),
              ),
              const SizedBox(height: 10),
              _TwoFields(
                left: TextField(
                  controller: _cidrs,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'IP CIDRs'),
                ),
                right: TextField(
                  controller: _ports,
                  decoration: const InputDecoration(labelText: 'Ports, comma separated'),
                ),
              ),
              const SizedBox(height: 10),
              _TwoFields(
                left: TextField(
                  controller: _protocols,
                  decoration: const InputDecoration(labelText: 'Protocols'),
                ),
                right: TextField(
                  controller: _networks,
                  decoration: const InputDecoration(labelText: 'Networks: tcp, udp'),
                ),
              ),
              const Divider(height: 28),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Linux process matchers', style: Theme.of(context).textTheme.titleSmall),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _processNames,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Process names',
                  hintText: 'firefox\ntelegram-desktop',
                ),
              ),
              const SizedBox(height: 10),
              _TwoFields(
                left: TextField(
                  controller: _processPaths,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Exact process paths'),
                ),
                right: TextField(
                  controller: _processRegexes,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Process path regexes'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<RouteActionType>(
                      initialValue: _action,
                      decoration: const InputDecoration(labelText: 'Action'),
                      items: const [
                        DropdownMenuItem(value: RouteActionType.proxy, child: Text('Proxy')),
                        DropdownMenuItem(value: RouteActionType.direct, child: Text('Direct')),
                        DropdownMenuItem(value: RouteActionType.block, child: Text('Block')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _action = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Invert matcher'),
                      value: _invert,
                      onChanged: (value) => setState(() => _invert = value),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  void _save() {
    final ports = <int>[];
    for (final value in _lines(_ports.text)) {
      final port = int.tryParse(value);
      if (port == null || port < 1 || port > 65535) {
        setState(() => _error = 'Ports must be integers between 1 and 65535.');
        return;
      }
      ports.add(port);
    }
    final matcher = RuleMatcher(
      domains: _lines(_domains.text),
      domainSuffixes: _lines(_suffixes.text),
      domainKeywords: _lines(_keywords.text),
      domainRegexes: _lines(_regexes.text),
      ipCidrs: _lines(_cidrs.text),
      ports: ports,
      protocols: _lines(_protocols.text),
      networks: _lines(_networks.text),
      processNames: _lines(_processNames.text),
      processPaths: _lines(_processPaths.text),
      processPathRegexes: _lines(_processRegexes.text),
      invert: _invert,
    );
    if (_name.text.trim().isEmpty || matcher.isEmpty) {
      setState(() => _error = 'Rule name and at least one matcher are required.');
      return;
    }
    final routeAction = switch (_action) {
      RouteActionType.proxy => const RouteAction.proxy('proxy'),
      RouteActionType.direct => const RouteAction.direct(),
      RouteActionType.block => const RouteAction.block(),
    };
    Navigator.pop(
      context,
      RoutingRule(
        id: widget.existing?.id ?? 'rule-${DateTime.now().microsecondsSinceEpoch}',
        name: _name.text.trim(),
        matcher: matcher,
        action: routeAction,
        enabled: widget.existing?.enabled ?? true,
      ),
    );
  }
}

class _TwoFields extends StatelessWidget {
  const _TwoFields({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _ProcessesPage extends ConsumerWidget {
  const _ProcessesPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(
      appControllerProvider.select(
        (state) => state.routingRules
            .where(
              (rule) =>
                  rule.matcher.processNames.isNotEmpty ||
                  rule.matcher.processPaths.isNotEmpty ||
                  rule.matcher.processPathRegexes.isNotEmpty,
            )
            .toList(growable: false),
      ),
    );
    final controller = ref.read(appControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Process routing'),
        actions: [
          FilledButton.icon(
            onPressed: () async {
              final rule = await showDialog<RoutingRule>(
                context: context,
                builder: (_) => const _ProcessRuleDialog(),
              );
              if (rule != null) await controller.addRoutingRule(rule);
            },
            icon: const Icon(Icons.add),
            label: const Text('Process rule'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: rules.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'Route a Linux process by executable name or path. These rules are part of the same ordered routing list and are compiled into sing-box process matchers.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.memory_outlined),
                    title: Text(rule.name),
                    subtitle: Text('${_processSummary(rule.matcher)} → ${_actionLabel(rule.action)}'),
                    trailing: IconButton(
                      tooltip: 'Delete',
                      onPressed: () => controller.deleteRoutingRule(rule.id),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ProcessRuleDialog extends StatefulWidget {
  const _ProcessRuleDialog();

  @override
  State<_ProcessRuleDialog> createState() => _ProcessRuleDialogState();
}

class _ProcessRuleDialogState extends State<_ProcessRuleDialog> {
  final _name = TextEditingController(text: 'Process rule');
  final _process = TextEditingController();
  RouteActionType _action = RouteActionType.proxy;
  String _matchType = 'name';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _process.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add process rule'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Rule name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _matchType,
              decoration: const InputDecoration(labelText: 'Match by'),
              items: const [
                DropdownMenuItem(value: 'name', child: Text('Process name')),
                DropdownMenuItem(value: 'path', child: Text('Exact executable path')),
                DropdownMenuItem(value: 'regex', child: Text('Executable path regex')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _matchType = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _process,
              autofocus: true,
              decoration: InputDecoration(
                labelText: switch (_matchType) {
                  'path' => 'Executable path',
                  'regex' => 'Path regex',
                  _ => 'Process name',
                },
                hintText: _matchType == 'name' ? 'firefox' : '/usr/bin/firefox',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RouteActionType>(
              initialValue: _action,
              decoration: const InputDecoration(labelText: 'Action'),
              items: const [
                DropdownMenuItem(value: RouteActionType.proxy, child: Text('Proxy')),
                DropdownMenuItem(value: RouteActionType.direct, child: Text('Direct')),
                DropdownMenuItem(value: RouteActionType.block, child: Text('Block')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _action = value);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Add')),
      ],
    );
  }

  void _save() {
    final value = _process.text.trim();
    if (_name.text.trim().isEmpty || value.isEmpty) {
      setState(() => _error = 'Name and process matcher are required.');
      return;
    }
    final matcher = switch (_matchType) {
      'path' => RuleMatcher(processPaths: [value]),
      'regex' => RuleMatcher(processPathRegexes: [value]),
      _ => RuleMatcher(processNames: [value]),
    };
    final action = switch (_action) {
      RouteActionType.proxy => const RouteAction.proxy('proxy'),
      RouteActionType.direct => const RouteAction.direct(),
      RouteActionType.block => const RouteAction.block(),
    };
    Navigator.pop(
      context,
      RoutingRule(
        id: 'process-${DateTime.now().microsecondsSinceEpoch}',
        name: _name.text.trim(),
        matcher: matcher,
        action: action,
      ),
    );
  }
}

class _LogsPage extends ConsumerWidget {
  const _LogsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(appControllerProvider.select((state) => state.logs));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            tooltip: 'Clear',
            onPressed: logs.isEmpty
                ? null
                : ref.read(appControllerProvider.notifier).clearLogs,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(child: Text('No logs yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) => SelectableText(
                logs[index],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ),
    );
  }
}

class _SettingsPage extends ConsumerWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(
      appControllerProvider.select(
        (state) => (
          preferences: state.corePreferences,
          autostart: state.autostartEnabled,
          minimize: state.minimizeToTray,
        ),
      ),
    );
    final controller = ref.read(appControllerProvider.notifier);
    final preferences = data.preferences;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.start),
            title: const Text('Start TrueTun with Linux session'),
            value: data.autostart,
            onChanged: controller.setAutostart,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.visibility_off_outlined),
            title: const Text('Keep running in tray when window closes'),
            value: data.minimize,
            onChanged: controller.setMinimizeToTray,
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.alt_route),
            title: const Text('Strict routing'),
            value: preferences.strictRoute,
            onChanged: (value) => controller.updateCorePreferences(
              preferences.copyWith(strictRoute: value),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.language),
            title: const Text('IPv6'),
            value: preferences.ipv6,
            onChanged: (value) => controller.updateCorePreferences(
              preferences.copyWith(ipv6: value),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.layers_outlined),
            title: const Text('TUN stack'),
            subtitle: Text(preferences.stack),
            onTap: () => _selectStack(context, controller, preferences),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('MTU'),
            subtitle: Text('${preferences.mtu}'),
            onTap: () => _editMtu(context, controller, preferences),
          ),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Remote DNS'),
            subtitle: Text(preferences.remoteDns),
            onTap: () => _editDns(context, controller, preferences, remote: true),
          ),
          ListTile(
            leading: const Icon(Icons.dns),
            title: const Text('Bootstrap DNS'),
            subtitle: Text(preferences.directDns),
            onTap: () => _editDns(context, controller, preferences, remote: false),
          ),
          ListTile(
            leading: const Icon(Icons.subject),
            title: const Text('Core log level'),
            subtitle: Text(preferences.logLevel),
            onTap: () => _selectLogLevel(context, controller, preferences),
          ),
        ],
      ),
    );
  }

  Future<void> _editMtu(
    BuildContext context,
    AppController controller,
    CorePreferences preferences,
  ) async {
    final raw = await showDialog<String>(
      context: context,
      builder: (_) => _PromptDialog(
        title: 'MTU',
        label: '1280–65535',
        initialValue: '${preferences.mtu}',
      ),
    );
    final value = int.tryParse(raw?.trim() ?? '');
    if (value != null && value >= 1280 && value <= 65535) {
      await controller.updateCorePreferences(preferences.copyWith(mtu: value));
    }
  }

  Future<void> _editDns(
    BuildContext context,
    AppController controller,
    CorePreferences preferences, {
    required bool remote,
  }) async {
    final raw = await showDialog<String>(
      context: context,
      builder: (_) => _PromptDialog(
        title: remote ? 'Remote DNS' : 'Bootstrap DNS',
        label: remote ? 'DoH URL or DNS address' : 'IP address',
        initialValue: remote ? preferences.remoteDns : preferences.directDns,
      ),
    );
    if (raw == null || raw.trim().isEmpty) return;
    await controller.updateCorePreferences(
      remote
          ? preferences.copyWith(remoteDns: raw.trim())
          : preferences.copyWith(directDns: raw.trim()),
    );
  }

  Future<void> _selectStack(
    BuildContext context,
    AppController controller,
    CorePreferences preferences,
  ) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _ChoiceDialog(
        title: 'TUN stack',
        current: preferences.stack,
        values: const ['mixed', 'system', 'gvisor'],
      ),
    );
    if (value != null) {
      await controller.updateCorePreferences(preferences.copyWith(stack: value));
    }
  }

  Future<void> _selectLogLevel(
    BuildContext context,
    AppController controller,
    CorePreferences preferences,
  ) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _ChoiceDialog(
        title: 'Core log level',
        current: preferences.logLevel,
        values: const ['error', 'warn', 'info', 'debug', 'trace'],
      ),
    );
    if (value != null) {
      await controller.updateCorePreferences(preferences.copyWith(logLevel: value));
    }
  }
}

class _ChoiceDialog extends StatelessWidget {
  const _ChoiceDialog({
    required this.title,
    required this.current,
    required this.values,
  });

  final String title;
  final String current;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(title),
      children: [
        for (final value in values)
          RadioListTile<String>(
            value: value,
            groupValue: current,
            title: Text(value),
            onChanged: (selected) => Navigator.pop(context, selected),
          ),
      ],
    );
  }
}

List<String> _lines(String value) => value
    .split(RegExp(r'[,\n]'))
    .map((entry) => entry.trim())
    .where((entry) => entry.isNotEmpty)
    .toList(growable: false);

String _pingLabel(int? value) {
  if (value == null) return 'Test';
  if (value < 0) return 'Fail';
  return '$value ms';
}

String _formatRate(int bytesPerSecond) => '${_formatBytes(bytesPerSecond)}/s';

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KiB', 'MiB', 'GiB', 'TiB'];
  var value = bytes.toDouble();
  var unit = -1;
  do {
    value /= 1024;
    unit++;
  } while (value >= 1024 && unit < units.length - 1);
  final digits = value >= 100 ? 0 : value >= 10 ? 1 : 2;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

String _ruleSummary(RoutingRule rule) {
  final matcher = rule.matcher;
  final parts = <String>[];
  if (matcher.domains.isNotEmpty) parts.add('${matcher.domains.length} domains');
  if (matcher.domainSuffixes.isNotEmpty) parts.add('${matcher.domainSuffixes.length} suffixes');
  if (matcher.domainKeywords.isNotEmpty) parts.add('${matcher.domainKeywords.length} keywords');
  if (matcher.domainRegexes.isNotEmpty) parts.add('${matcher.domainRegexes.length} regexes');
  if (matcher.ipCidrs.isNotEmpty) parts.add('${matcher.ipCidrs.length} CIDRs');
  if (matcher.ports.isNotEmpty) parts.add('${matcher.ports.length} ports');
  if (matcher.processNames.isNotEmpty || matcher.processPaths.isNotEmpty || matcher.processPathRegexes.isNotEmpty) {
    parts.add('process');
  }
  return parts.isEmpty ? 'custom matcher' : parts.join(' · ');
}

String _processSummary(RuleMatcher matcher) {
  if (matcher.processNames.isNotEmpty) return 'name: ${matcher.processNames.join(', ')}';
  if (matcher.processPaths.isNotEmpty) return 'path: ${matcher.processPaths.join(', ')}';
  return 'regex: ${matcher.processPathRegexes.join(', ')}';
}

String _actionLabel(RouteAction action) => switch (action.type) {
      RouteActionType.proxy => action.outboundTag ?? 'proxy',
      RouteActionType.direct => 'direct',
      RouteActionType.block => 'block',
    };

IconData _actionIcon(RouteActionType type) => switch (type) {
      RouteActionType.proxy => Icons.shield_outlined,
      RouteActionType.direct => Icons.arrow_forward,
      RouteActionType.block => Icons.block,
    };
