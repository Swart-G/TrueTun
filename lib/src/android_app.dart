import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:truetun/src/application/app_state.dart';
import 'package:truetun/src/apps/app_routing_policy.dart';
import 'package:truetun/src/core/core_adapter.dart';
import 'package:truetun/src/platform/android/android_platform_bridge.dart';
import 'package:truetun/src/profiles/profile_group.dart';
import 'package:truetun/src/routing/routing_rule.dart';

class TrueTunAndroidApp extends StatelessWidget {
  const TrueTunAndroidApp({super.key});

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
      home: const _AndroidShell(),
    );
  }
}

class _AndroidShell extends StatefulWidget {
  const _AndroidShell();

  @override
  State<_AndroidShell> createState() => _AndroidShellState();
}

class _AndroidShellState extends State<_AndroidShell> {
  int _index = 0;

  static const _pages = <Widget>[
    _AndroidHomePage(),
    _AndroidProfilesPage(),
    _AndroidRoutingPage(),
    _AndroidAppsPage(),
    _AndroidLogsPage(),
    _AndroidSettingsPage(),
  ];

  static const _destinations = <NavigationDestination>[
    NavigationDestination(icon: Icon(Icons.shield_outlined), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.dns_outlined), label: 'Profiles'),
    NavigationDestination(icon: Icon(Icons.alt_route), label: 'Routing'),
    NavigationDestination(icon: Icon(Icons.apps), label: 'Apps'),
    NavigationDestination(icon: Icon(Icons.article_outlined), label: 'Logs'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: _pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: _destinations,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (value) => setState(() => _index = value),
      ),
    );
  }
}

class _AndroidHomePage extends ConsumerWidget {
  const _AndroidHomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final running = state.coreState == ProxyCoreState.running;
    final busy = state.coreState == ProxyCoreState.starting ||
        state.coreState == ProxyCoreState.stopping;
    final lastSample = state.trafficHistory.isEmpty
        ? null
        : state.trafficHistory.last;

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('TrueTun'),
          actions: [
            IconButton(
              tooltip: 'Test connection',
              onPressed: running && !state.testing ? controller.testConnection : null,
              icon: state.testing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.network_check),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          sliver: SliverList.list(
            children: [
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: running
                        ? Colors.green.withValues(alpha: 0.14)
                        : Theme.of(context).colorScheme.surfaceContainerHigh,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      fixedSize: const Size(180, 180),
                      shape: const CircleBorder(),
                      backgroundColor: running ? Colors.green.shade700 : null,
                    ),
                    onPressed: state.node == null || busy
                        ? null
                        : running
                            ? controller.disconnect
                            : controller.connect,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(running ? Icons.shield : Icons.power_settings_new, size: 50),
                        const SizedBox(height: 10),
                        Text(
                          state.node == null
                              ? 'NO PROFILE'
                              : running
                                  ? 'VPN ON'
                                  : busy
                                      ? state.coreState.name.toUpperCase()
                                      : 'VPN OFF',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                state.node?.name ?? 'Choose a profile to connect',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (state.node != null)
                Text(
                  '${state.node!.protocol.name.toUpperCase()} · ${state.node!.server}:${state.node!.port}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (state.error != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(state.error!),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.upload,
                      label: 'Upload',
                      value: _formatRate(lastSample?.uploadPerSecond ?? 0),
                      secondary: _formatBytes(state.upload),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.download,
                      label: 'Download',
                      value: _formatRate(lastSample?.downloadPerSecond ?? 0),
                      secondary: _formatBytes(state.download),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _MetricCard(
                icon: Icons.speed,
                label: 'Connection latency',
                value: state.latency == null ? '—' : '${state.latency!.inMilliseconds} ms',
                secondary: running ? 'Measured through the active VPN' : 'Connect to test',
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Live traffic', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _TrafficPainter(
                            samples: state.trafficHistory,
                            uploadColor: Theme.of(context).colorScheme.tertiary,
                            downloadColor: Theme.of(context).colorScheme.primary,
                            gridColor: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.download, size: 16),
                          SizedBox(width: 4),
                          Text('Download'),
                          SizedBox(width: 18),
                          Icon(Icons.upload, size: 16),
                          SizedBox(width: 4),
                          Text('Upload'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.secondary,
  });

  final IconData icon;
  final String label;
  final String value;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)]),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(secondary, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _TrafficPainter extends CustomPainter {
  const _TrafficPainter({
    required this.samples,
    required this.uploadColor,
    required this.downloadColor,
    required this.gridColor,
  });

  final List<TrafficSample> samples;
  final Color uploadColor;
  final Color downloadColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = gridColor;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (samples.length < 2) return;
    final maxValue = samples.fold<int>(1, (value, sample) {
      return math.max(value, math.max(sample.uploadPerSecond, sample.downloadPerSecond));
    });

    void draw(bool upload, Color color) {
      final path = Path();
      for (var index = 0; index < samples.length; index++) {
        final sample = samples[index];
        final value = upload ? sample.uploadPerSecond : sample.downloadPerSecond;
        final x = size.width * index / (samples.length - 1);
        final y = size.height - (size.height * value / maxValue);
        if (index == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    draw(false, downloadColor);
    draw(true, uploadColor);
  }

  @override
  bool shouldRepaint(covariant _TrafficPainter oldDelegate) =>
      oldDelegate.samples != samples ||
      oldDelegate.uploadColor != uploadColor ||
      oldDelegate.downloadColor != downloadColor ||
      oldDelegate.gridColor != gridColor;
}

class _AndroidProfilesPage extends ConsumerWidget {
  const _AndroidProfilesPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
        actions: [
          IconButton(
            tooltip: 'Add profile or subscription',
            onPressed: () => _showAddMenu(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: state.groups.isEmpty
          ? const Center(child: Text('Add a proxy link or subscription to begin.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: state.groups.length,
              itemBuilder: (context, index) {
                final group = state.groups[index];
                return Card(
                  child: ExpansionTile(
                    initiallyExpanded: group.id == state.selectedGroupId,
                    title: Text(group.name),
                    subtitle: Text(
                      group.isSubscription
                          ? '${group.profiles.length} profiles · subscription'
                          : '${group.profiles.length} profiles',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'refresh':
                            controller.refreshGroup(group.id);
                          case 'test':
                            controller.testGroup(group.id);
                          case 'delete':
                            controller.deleteGroup(group.id);
                        }
                      },
                      itemBuilder: (context) => [
                        if (group.isSubscription)
                          const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
                        const PopupMenuItem(value: 'test', child: Text('Test all')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete group')),
                      ],
                    ),
                    children: [
                      for (final profile in group.profiles)
                        ListTile(
                          selected: state.selectedProfileId == profile.id,
                          leading: Icon(
                            state.selectedProfileId == profile.id
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                          ),
                          title: Text(profile.node.name),
                          subtitle: Text(
                            '${profile.node.protocol.name.toUpperCase()} · '
                            '${profile.node.server}:${profile.node.port}',
                          ),
                          onTap: () => controller.selectProfile(group.id, profile.id),
                          trailing: _ProfilePingButton(profile: profile),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showAddMenu(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Import proxy link / config'),
              onTap: () => Navigator.pop(context, 'profile'),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: const Text('Add subscription'),
              onTap: () => Navigator.pop(context, 'subscription'),
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('Create empty group'),
              onTap: () => Navigator.pop(context, 'group'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'profile') {
      final input = await _textDialog(
        context,
        title: 'Import proxy',
        label: 'VLESS / Hysteria2 link or config',
        maxLines: 5,
      );
      if (input != null && input.trim().isNotEmpty) {
        ref.read(appControllerProvider.notifier).importProfile(input);
      }
    } else if (action == 'group') {
      final name = await _textDialog(context, title: 'Create group', label: 'Name');
      if (name != null) ref.read(appControllerProvider.notifier).createGroup(name);
    } else if (action == 'subscription') {
      final result = await _subscriptionDialog(context);
      if (result != null) {
        await ref.read(appControllerProvider.notifier).addSubscription(result.$1, result.$2);
      }
    }
  }
}

class _ProfilePingButton extends ConsumerWidget {
  const _ProfilePingButton({required this.profile});

  final ManagedProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final ping = state.profilePings[profile.id];
    final loading = state.pingingProfiles.contains(profile.id);
    return TextButton(
      onPressed: loading
          ? null
          : () => ref.read(appControllerProvider.notifier).testProfile(profile.id),
      child: loading
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(ping == null ? 'Test' : ping < 0 ? 'Fail' : '$ping ms'),
    );
  }
}

class _AndroidRoutingPage extends ConsumerWidget {
  const _AndroidRoutingPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routing'),
        actions: [
          IconButton(
            tooltip: 'Add rule',
            onPressed: () async {
              final rule = await _showRoutingRuleEditor(context);
              if (rule != null) await controller.addRoutingRule(rule);
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: state.routingRules.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No custom rules. Traffic uses the selected proxy by default. '
                  'Rules are evaluated from top to bottom.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: state.routingRules.length,
              onReorder: controller.reorderRoutingRule,
              itemBuilder: (context, index) {
                final rule = state.routingRules[index];
                return Card(
                  key: ValueKey(rule.id),
                  child: ListTile(
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                    title: Text(rule.name),
                    subtitle: Text('${_ruleSummary(rule)} → ${_actionLabel(rule.action)}'),
                    onTap: () async {
                      final updated = await _showRoutingRuleEditor(context, existing: rule);
                      if (updated != null) await controller.updateRoutingRule(updated);
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: rule.enabled,
                          onChanged: (enabled) => controller.updateRoutingRule(
                            RoutingRule(
                              id: rule.id,
                              name: rule.name,
                              matcher: rule.matcher,
                              action: rule.action,
                              enabled: enabled,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: () => controller.deleteRoutingRule(rule.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _AndroidAppsPage extends ConsumerStatefulWidget {
  const _AndroidAppsPage();

  @override
  ConsumerState<_AndroidAppsPage> createState() => _AndroidAppsPageState();
}

class _AndroidAppsPageState extends ConsumerState<_AndroidAppsPage> {
  final _search = TextEditingController();
  bool _showSystem = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final policy = state.appRoutingPolicy;
    final query = _search.text.trim().toLowerCase();
    final apps = state.installedApps.where((app) {
      if (!_showSystem && app.isSystem) return false;
      if (query.isEmpty) return true;
      return app.label.toLowerCase().contains(query) ||
          app.packageName.toLowerCase().contains(query);
    }).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apps'),
        actions: [
          IconButton(
            tooltip: 'Smart selection',
            onPressed: state.installedApps.isEmpty ? null : _applySmartSelection,
            icon: const Icon(Icons.auto_awesome),
          ),
          IconButton(
            tooltip: 'Refresh apps',
            onPressed: state.loadingInstalledApps ? null : controller.loadInstalledApps,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SegmentedButton<AppRoutingMode>(
              segments: const [
                ButtonSegment(
                  value: AppRoutingMode.proxyAllExceptSelected,
                  label: Text('Blacklist'),
                  icon: Icon(Icons.remove_circle_outline),
                ),
                ButtonSegment(
                  value: AppRoutingMode.proxyOnlySelected,
                  label: Text('Whitelist'),
                  icon: Icon(Icons.check_circle_outline),
                ),
              ],
              selected: {policy.mode},
              onSelectionChanged: (values) => controller.setAppRoutingMode(values.single),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              policy.mode == AppRoutingMode.proxyAllExceptSelected
                  ? 'Checked apps bypass the VPN. Everything else is proxied.'
                  : 'Only checked apps use the VPN. TrueTun diagnostics are included automatically.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search installed apps',
                suffixIcon: IconButton(
                  tooltip: _showSystem ? 'Hide system apps' : 'Show system apps',
                  onPressed: () => setState(() => _showSystem = !_showSystem),
                  icon: Icon(_showSystem ? Icons.android : Icons.android_outlined),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (state.loadingInstalledApps) const LinearProgressIndicator(),
          Expanded(
            child: apps.isEmpty
                ? const Center(child: Text('No matching apps'))
                : ListView.builder(
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      final selected = policy.selectedPackageNames.contains(app.packageName);
                      final suggestion = const SmartAppSuggestionEngine().suggest(
                        app,
                        ownPackageName: 'app.truetun',
                      );
                      return CheckboxListTile(
                        value: selected,
                        onChanged: app.packageName == 'app.truetun'
                            ? null
                            : (value) => controller.setAppSelected(app.packageName, value ?? false),
                        title: Text(app.label),
                        subtitle: Text(
                          '${app.packageName}\n${_recommendationLabel(suggestion)}',
                          maxLines: 2,
                        ),
                        secondary: Icon(_categoryIcon(app.category)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _applySmartSelection() async {
    final state = ref.read(appControllerProvider);
    final engine = const SmartAppSuggestionEngine();
    final selected = <String>{};
    for (final app in state.installedApps) {
      final suggestion = engine.suggest(app, ownPackageName: 'app.truetun');
      final shouldSelect = switch (state.appRoutingPolicy.mode) {
        AppRoutingMode.proxyAllExceptSelected =>
          suggestion.recommendation == AppRoutingRecommendation.bypass,
        AppRoutingMode.proxyOnlySelected =>
          suggestion.recommendation == AppRoutingRecommendation.proxy,
      };
      if (shouldSelect && app.packageName != 'app.truetun') {
        selected.add(app.packageName);
      }
    }
    await ref.read(appControllerProvider.notifier).updateAppRoutingPolicy(
          AppRoutingPolicy(mode: state.appRoutingPolicy.mode, selectedPackageNames: selected),
        );
  }
}

class _AndroidLogsPage extends ConsumerWidget {
  const _AndroidLogsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            tooltip: 'Clear logs',
            onPressed: state.logs.isEmpty
                ? null
                : ref.read(appControllerProvider.notifier).clearLogs,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: state.logs.isEmpty
          ? const Center(child: Text('No logs yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.logs.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: SelectableText(
                  state.logs[index],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ),
            ),
    );
  }
}

class _AndroidSettingsPage extends ConsumerStatefulWidget {
  const _AndroidSettingsPage();

  @override
  ConsumerState<_AndroidSettingsPage> createState() => _AndroidSettingsPageState();
}

class _AndroidSettingsPageState extends ConsumerState<_AndroidSettingsPage> {
  Map<String, Object?>? _diagnostics;
  bool _loadingDiagnostics = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final preferences = state.corePreferences;
    final controller = ref.read(appControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionTitle('VPN'),
          ListTile(
            leading: const Icon(Icons.vpn_key_outlined),
            title: const Text('Android VPN settings'),
            subtitle: const Text('Always-on VPN and Block connections without VPN'),
            trailing: const Icon(Icons.open_in_new),
            onTap: const AndroidPlatformBridge().openVpnSettings,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.route_outlined),
            title: const Text('Strict routing'),
            subtitle: const Text('Prefer deterministic TUN routing'),
            value: preferences.strictRoute,
            onChanged: (value) => controller.updateCorePreferences(
              preferences.copyWith(strictRoute: value),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.language),
            title: const Text('IPv6'),
            subtitle: const Text('Advertise IPv6 inside the tunnel'),
            value: preferences.ipv6,
            onChanged: (value) => controller.updateCorePreferences(
              preferences.copyWith(ipv6: value),
            ),
          ),
          const _SectionTitle('Core'),
          ListTile(
            title: const Text('TUN stack'),
            subtitle: Text(preferences.stack),
            onTap: () async {
              final value = await showDialog<String>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('TUN stack'),
                  children: [
                    for (final stack in const ['mixed', 'system', 'gvisor'])
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, stack),
                        child: Text(stack),
                      ),
                  ],
                ),
              );
              if (value != null) {
                await controller.updateCorePreferences(preferences.copyWith(stack: value));
              }
            },
          ),
          ListTile(
            title: const Text('MTU'),
            subtitle: Text('${preferences.mtu}'),
            onTap: () => _editMtu(context, preferences.mtu),
          ),
          ListTile(
            title: const Text('Remote DNS'),
            subtitle: Text(preferences.remoteDns),
            onTap: () => _editDns(context, remote: true),
          ),
          ListTile(
            title: const Text('Direct bootstrap DNS'),
            subtitle: Text(preferences.directDns),
            onTap: () => _editDns(context, remote: false),
          ),
          const _SectionTitle('Diagnostics'),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Native runtime diagnostics'),
            subtitle: Text(
              _diagnostics == null
                  ? 'Read Android, app and embedded core information'
                  : _diagnostics!.entries.map((entry) => '${entry.key}: ${entry.value}').join('\n'),
              maxLines: _diagnostics == null ? 2 : 8,
            ),
            trailing: _loadingDiagnostics
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onTap: _loadingDiagnostics ? null : _loadDiagnostics,
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Future<void> _editMtu(BuildContext context, int current) async {
    final raw = await _textDialog(
      context,
      title: 'MTU',
      label: '1280–65535',
      initialValue: '$current',
    );
    final value = int.tryParse(raw?.trim() ?? '');
    if (value == null || value < 1280 || value > 65535) return;
    final currentPreferences = ref.read(appControllerProvider).corePreferences;
    await ref.read(appControllerProvider.notifier).updateCorePreferences(
          currentPreferences.copyWith(mtu: value),
        );
  }

  Future<void> _editDns(BuildContext context, {required bool remote}) async {
    final preferences = ref.read(appControllerProvider).corePreferences;
    final value = await _textDialog(
      context,
      title: remote ? 'Remote DNS' : 'Direct bootstrap DNS',
      label: remote ? 'DoH URL or DNS address' : 'IP address',
      initialValue: remote ? preferences.remoteDns : preferences.directDns,
    );
    if (value == null || value.trim().isEmpty) return;
    await ref.read(appControllerProvider.notifier).updateCorePreferences(
          remote
              ? preferences.copyWith(remoteDns: value.trim())
              : preferences.copyWith(directDns: value.trim()),
        );
  }

  Future<void> _loadDiagnostics() async {
    setState(() => _loadingDiagnostics = true);
    try {
      final data = await const AndroidPlatformBridge().getDiagnostics();
      if (mounted) setState(() => _diagnostics = data);
    } finally {
      if (mounted) setState(() => _loadingDiagnostics = false);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

Future<RoutingRule?> _showRoutingRuleEditor(
  BuildContext context, {
  RoutingRule? existing,
}) async {
  final name = TextEditingController(text: existing?.name ?? 'New rule');
  final domains = TextEditingController(text: existing?.matcher.domains.join('\n') ?? '');
  final suffixes = TextEditingController(
    text: existing?.matcher.domainSuffixes.join('\n') ?? '',
  );
  final cidrs = TextEditingController(text: existing?.matcher.ipCidrs.join('\n') ?? '');
  var action = existing?.action.type ?? RouteActionType.proxy;

  final result = await showDialog<RoutingRule>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Add routing rule' : 'Edit routing rule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              TextField(
                controller: domains,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Exact domains, one per line'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: suffixes,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Domain suffixes'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cidrs,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'IP CIDRs'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RouteActionType>(
                initialValue: action,
                decoration: const InputDecoration(labelText: 'Action'),
                items: const [
                  DropdownMenuItem(value: RouteActionType.proxy, child: Text('Proxy')),
                  DropdownMenuItem(value: RouteActionType.direct, child: Text('Direct')),
                  DropdownMenuItem(value: RouteActionType.block, child: Text('Block')),
                ],
                onChanged: (value) => setDialogState(() => action = value ?? action),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final matcher = RuleMatcher(
                domains: _lines(domains.text),
                domainSuffixes: _lines(suffixes.text),
                ipCidrs: _lines(cidrs.text),
              );
              if (name.text.trim().isEmpty || matcher.isEmpty) return;
              final routeAction = switch (action) {
                RouteActionType.proxy => const RouteAction.proxy('proxy'),
                RouteActionType.direct => const RouteAction.direct(),
                RouteActionType.block => const RouteAction.block(),
              };
              Navigator.pop(
                context,
                RoutingRule(
                  id: existing?.id ?? 'rule-${DateTime.now().microsecondsSinceEpoch}',
                  name: name.text.trim(),
                  matcher: matcher,
                  action: routeAction,
                  enabled: existing?.enabled ?? true,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );

  name.dispose();
  domains.dispose();
  suffixes.dispose();
  cidrs.dispose();
  return result;
}

Future<String?> _textDialog(
  BuildContext context, {
  required String title,
  required String label,
  String? initialValue,
  int maxLines = 1,
}) async {
  final controller = TextEditingController(text: initialValue);
  final value = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: maxLines > 1 ? 2 : 1,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  return value;
}

Future<(String, String)?> _subscriptionDialog(BuildContext context) async {
  final name = TextEditingController();
  final url = TextEditingController();
  final value = await showDialog<(String, String)>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add subscription'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 10),
          TextField(
            controller: url,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'URL'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, (name.text, url.text)),
          child: const Text('Add'),
        ),
      ],
    ),
  );
  name.dispose();
  url.dispose();
  return value;
}

List<String> _lines(String value) => value
    .split(RegExp(r'[,\n]'))
    .map((entry) => entry.trim())
    .where((entry) => entry.isNotEmpty)
    .toList(growable: false);

String _ruleSummary(RoutingRule rule) {
  final matcher = rule.matcher;
  final parts = <String>[];
  if (matcher.domains.isNotEmpty) parts.add('${matcher.domains.length} domains');
  if (matcher.domainSuffixes.isNotEmpty) {
    parts.add('${matcher.domainSuffixes.length} suffixes');
  }
  if (matcher.ipCidrs.isNotEmpty) parts.add('${matcher.ipCidrs.length} CIDRs');
  if (matcher.ruleSets.isNotEmpty) parts.add('${matcher.ruleSets.length} rule sets');
  if (matcher.packageNames.isNotEmpty) parts.add('${matcher.packageNames.length} apps');
  return parts.isEmpty ? 'custom matcher' : parts.join(' · ');
}

String _actionLabel(RouteAction action) => switch (action.type) {
      RouteActionType.proxy => action.outboundTag ?? 'proxy',
      RouteActionType.direct => 'direct',
      RouteActionType.block => 'block',
    };

String _recommendationLabel(AppRoutingSuggestion suggestion) {
  final label = switch (suggestion.recommendation) {
    AppRoutingRecommendation.proxy => 'suggest proxy',
    AppRoutingRecommendation.bypass => 'suggest bypass',
    AppRoutingRecommendation.neutral => 'no automatic choice',
  };
  return '$label · ${(suggestion.confidence * 100).round()}%';
}

IconData _categoryIcon(AppCategory category) => switch (category) {
      AppCategory.browser => Icons.public,
      AppCategory.messaging => Icons.chat_bubble_outline,
      AppCategory.social => Icons.people_outline,
      AppCategory.streaming => Icons.play_circle_outline,
      AppCategory.game => Icons.sports_esports_outlined,
      AppCategory.banking => Icons.account_balance_outlined,
      AppCategory.system => Icons.settings_applications_outlined,
      AppCategory.vpnOrProxy => Icons.vpn_key_outlined,
      AppCategory.other => Icons.apps,
    };

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
  return '${value.toStringAsFixed(value >= 100 ? 0 : value >= 10 ? 1 : 2)} ${units[unit]}';
}
