import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:truetun/src/android_dialogs.dart';
import 'package:truetun/src/application/app_state.dart';
import 'package:truetun/src/apps/app_routing_policy.dart';
import 'package:truetun/src/core/core_adapter.dart';
import 'package:truetun/src/core/core_preferences.dart';
import 'package:truetun/src/platform/android/android_platform_bridge.dart';
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
    _HomePage(),
    _ProfilesPage(),
    _RoutingPage(),
    _AppsPage(),
    _LogsPage(),
    _SettingsPage(),
  ];

  static const _destinations = <NavigationDestination>[
    NavigationDestination(icon: Icon(Icons.shield_outlined), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.dns_outlined), label: 'Profiles'),
    NavigationDestination(icon: Icon(Icons.alt_route), label: 'Routing'),
    NavigationDestination(icon: Icon(Icons.apps), label: 'Apps'),
    NavigationDestination(icon: Icon(Icons.article_outlined), label: 'Logs'),
    NavigationDestination(
        icon: Icon(Icons.settings_outlined), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: _destinations,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (value) => setState(() => _index = value),
      ),
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
          speedTestResult: state.speedTestResult,
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
    final sample =
        data.trafficHistory.isEmpty ? null : data.trafficHistory.last;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text('TrueTun', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 24),
        Center(
          child: FilledButton(
            style: FilledButton.styleFrom(
              fixedSize: const Size(164, 164),
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
                  size: 46,
                ),
                const SizedBox(height: 8),
                Text(
                  data.node == null
                      ? 'NO PROFILE'
                      : running
                          ? 'VPN ON'
                          : busy
                              ? data.coreState.name.toUpperCase()
                              : 'VPN OFF',
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
            '${data.node!.protocol.name.toUpperCase()} · '
            '${data.node!.server}:${data.node!.port}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (data.error != null) ...[
          const SizedBox(height: 14),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(data.error!),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.upload,
                title: 'Upload',
                value: _formatRate(sample?.uploadPerSecond ?? 0),
                detail: _formatBytes(data.upload),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.download,
                title: 'Download',
                value: _formatRate(sample?.downloadPerSecond ?? 0),
                detail: _formatBytes(data.download),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Speed test'),
            subtitle: Text(
              data.testing
                  ? 'Measuring download and upload…'
                  : data.speedTestResult == null
                      ? 'Download + upload, about 10 MiB'
                      : '↓ ${_formatMbps(data.speedTestResult!.downloadBytesPerSecond)}  '
                          '↑ ${_formatMbps(data.speedTestResult!.uploadBytesPerSecond)}  '
                          '• ${data.speedTestResult!.latency.inMilliseconds} ms',
            ),
            trailing: data.testing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: running && !data.testing ? controller.testSpeed : null,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Live traffic',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      '↓ ${_formatRate(sample?.downloadPerSecond ?? 0)}  '
                      '↑ ${_formatRate(sample?.uploadPerSecond ?? 0)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                RepaintBoundary(
                  child: SizedBox(
                    height: 132,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Text(title),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            Text(detail, style: Theme.of(context).textTheme.bodySmall),
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
      return const Center(
        child: Text('Traffic samples will appear after connection'),
      );
    }
    final visible =
        samples.length <= 60 ? samples : samples.sublist(samples.length - 60);
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _TrafficChartPainter(
        samples: visible,
        downloadColor: scheme.primary,
        uploadColor: scheme.tertiary,
      ),
    );
  }
}

class _TrafficChartPainter extends CustomPainter {
  const _TrafficChartPainter({
    required this.samples,
    required this.downloadColor,
    required this.uploadColor,
  });

  final List<TrafficSample> samples;
  final Color downloadColor;
  final Color uploadColor;

  static const _visibleSlots = 60;
  static const _maxBytesPerSecond = 16 * 1024 * 1024;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || samples.isEmpty) return;

    final downloadPoints = <Offset>[];
    final uploadPoints = <Offset>[];
    final firstSlot = _visibleSlots - samples.length;
    for (var index = 0; index < samples.length; index++) {
      final x = size.width * (firstSlot + index) / (_visibleSlots - 1);
      double yFor(int value) =>
          size.height * (1 - (value / _maxBytesPerSecond).clamp(0.0, 1.0));
      downloadPoints.add(
        Offset(x, yFor(samples[index].downloadPerSecond)),
      );
      uploadPoints.add(Offset(x, yFor(samples[index].uploadPerSecond)));
    }

    final downloadPath = _smoothPath(downloadPoints);
    final uploadPath = _smoothPath(uploadPoints);

    canvas.drawPath(
      downloadPath,
      Paint()
        ..color = downloadColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      uploadPath,
      Paint()
        ..color = uploadColor
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _TrafficChartPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.downloadColor != downloadColor ||
        oldDelegate.uploadColor != uploadColor;
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final midpoint = Offset(
        (previous.dx + current.dx) / 2,
        (previous.dy + current.dy) / 2,
      );
      path.quadraticBezierTo(
        previous.dx,
        previous.dy,
        midpoint.dx,
        midpoint.dy,
      );
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }
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
          IconButton(
            tooltip: 'Add',
            onPressed: () => _showAddProfileMenu(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: data.groups.isEmpty
          ? const Center(child: Text('Add a proxy link or subscription'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
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
                        const PopupMenuItem(
                          value: 'test',
                          child: Text('Test all'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                    children: [
                      if (group.error != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            group.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _pingLabel(data.profilePings[profile.id]),
                                  ),
                          ),
                          onTap: () => controller.selectProfile(
                            group.id,
                            profile.id,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _RoutingPage extends ConsumerWidget {
  const _RoutingPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(
      appControllerProvider.select(
        (state) => (
          rules: state.routingRules,
          settings: state.routingSettings,
        ),
      ),
    );
    final rules = data.rules;
    final controller = ref.read(appControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routing'),
        actions: [
          IconButton(
            tooltip: 'Add rule',
            onPressed: () async {
              final rule = await showTrueTunRoutingRuleDialog(context);
              if (rule != null) await controller.addRoutingRule(rule);
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: rules.length + 2,
        itemBuilder: (context, listIndex) {
          if (listIndex == 0) {
            return Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.alt_route),
                    title: const Text('Routing mode'),
                    subtitle: Text(
                      data.settings.enabled
                          ? 'Apply the rules below'
                          : 'Disabled — rules below are not applied',
                    ),
                    value: data.settings.enabled,
                    onChanged: (enabled) => controller.updateRoutingSettings(
                      data.settings.copyWith(enabled: enabled),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    enabled: data.settings.enabled,
                    title: const Text('All other traffic'),
                    subtitle: const Text('When no rule matches'),
                    trailing: DropdownButton<RouteActionType>(
                      value: data.settings.fallbackAction,
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
                      onChanged: data.settings.enabled
                          ? (action) {
                              if (action != null) {
                                controller.updateRoutingSettings(
                                  data.settings.copyWith(
                                    fallbackAction: action,
                                  ),
                                );
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            );
          }
          if (listIndex == 1) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
              child: Text(
                rules.isEmpty
                    ? 'No rules yet'
                    : 'Rules are applied from top to bottom',
              ),
            );
          }
          final index = listIndex - 2;
          final rule = rules[index];
          return Card(
            child: ListTile(
              enabled: rule.enabled,
              title: Text(rule.name),
              subtitle: Text(
                '${_ruleSummary(rule)} → ${_actionLabel(rule.action)}',
              ),
              onTap: () async {
                final updated = await showTrueTunRoutingRuleDialog(
                  context,
                  existing: rule,
                );
                if (updated != null) {
                  await controller.updateRoutingRule(updated);
                }
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
                    const PopupMenuItem(
                      value: 'up',
                      child: Text('Move up'),
                    ),
                  if (index < rules.length - 1)
                    const PopupMenuItem(
                      value: 'down',
                      child: Text('Move down'),
                    ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(rule.enabled ? 'Disable' : 'Enable'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
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

class _AppsPage extends ConsumerStatefulWidget {
  const _AppsPage();

  @override
  ConsumerState<_AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends ConsumerState<_AppsPage> {
  final _search = TextEditingController();
  bool _showSystem = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(
      appControllerProvider.select(
        (state) => (
          policy: state.appRoutingPolicy,
          installedApps: state.installedApps,
          loading: state.loadingInstalledApps,
        ),
      ),
    );
    final controller = ref.read(appControllerProvider.notifier);
    final query = _search.text.trim().toLowerCase();
    final apps = data.installedApps.where((app) {
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
            onPressed: data.installedApps.isEmpty ? null : _applySmartSelection,
            icon: const Icon(Icons.auto_awesome),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: data.loading ? null : controller.loadInstalledApps,
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
                ),
                ButtonSegment(
                  value: AppRoutingMode.proxyOnlySelected,
                  label: Text('Whitelist'),
                ),
              ],
              selected: {data.policy.mode},
              onSelectionChanged: (selection) {
                controller.setAppRoutingMode(selection.single);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search apps',
                suffixIcon: IconButton(
                  tooltip:
                      _showSystem ? 'Hide system apps' : 'Show system apps',
                  onPressed: () => setState(() => _showSystem = !_showSystem),
                  icon: Icon(
                    _showSystem ? Icons.android : Icons.android_outlined,
                  ),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (data.loading) const LinearProgressIndicator(),
          Expanded(
            child: apps.isEmpty
                ? const Center(child: Text('No matching apps'))
                : ListView.builder(
                    itemCount: apps.length,
                    itemExtent: 72,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      final checked = data.policy.selectedPackageNames
                          .contains(app.packageName);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: app.packageName == 'app.truetun'
                            ? null
                            : (value) => controller.setAppSelected(
                                  app.packageName,
                                  value ?? false,
                                ),
                        title: Text(app.label),
                        subtitle: Text(
                          app.packageName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    final selected = <String>{};
    const engine = SmartAppSuggestionEngine();
    for (final app in state.installedApps) {
      final suggestion = engine.suggest(
        app,
        ownPackageName: 'app.truetun',
      );
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
          AppRoutingPolicy(
            mode: state.appRoutingPolicy.mode,
            selectedPackageNames: selected,
          ),
        );
  }
}

class _LogsPage extends ConsumerWidget {
  const _LogsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(
      appControllerProvider.select((state) => state.logs),
    );
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
              padding: const EdgeInsets.all(12),
              itemCount: logs.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  logs[index],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ),
            ),
    );
  }
}

class _SettingsPage extends ConsumerStatefulWidget {
  const _SettingsPage();

  @override
  ConsumerState<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<_SettingsPage> {
  Map<String, Object?>? _diagnostics;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(
      appControllerProvider.select((state) => state.corePreferences),
    );
    final controller = ref.read(appControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.vpn_key_outlined),
            title: const Text('Android VPN settings'),
            subtitle: const Text('Always-on VPN and block without VPN'),
            trailing: const Icon(Icons.open_in_new),
            onTap: const AndroidPlatformBridge().openVpnSettings,
          ),
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
            leading: const Icon(Icons.tune),
            title: const Text('MTU'),
            subtitle: Text('${preferences.mtu}'),
            onTap: () => _editMtu(context, preferences),
          ),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Remote DNS'),
            subtitle: Text(preferences.remoteDns),
            onTap: () => _editDns(context, preferences, remote: true),
          ),
          ListTile(
            leading: const Icon(Icons.dns),
            title: const Text('Bootstrap DNS'),
            subtitle: Text(preferences.directDns),
            onTap: () => _editDns(context, preferences, remote: false),
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Native diagnostics'),
            subtitle: Text(
              _diagnostics == null
                  ? 'Android and embedded core information'
                  : _diagnostics!.entries
                      .map((entry) => '${entry.key}: ${entry.value}')
                      .join('\n'),
              maxLines: _diagnostics == null ? 2 : 10,
            ),
            trailing: _loading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onTap: _loading ? null : _loadDiagnostics,
          ),
        ],
      ),
    );
  }

  Future<void> _editMtu(
    BuildContext context,
    CorePreferences preferences,
  ) async {
    final raw = await showTrueTunTextDialog(
      context,
      title: 'MTU',
      label: '1280–65535',
      initialValue: '${preferences.mtu}',
    );
    final mtu = int.tryParse(raw?.trim() ?? '');
    if (mtu != null && mtu >= 1280 && mtu <= 65535) {
      await ref.read(appControllerProvider.notifier).updateCorePreferences(
            preferences.copyWith(mtu: mtu),
          );
    }
  }

  Future<void> _editDns(
    BuildContext context,
    CorePreferences preferences, {
    required bool remote,
  }) async {
    final value = await showTrueTunTextDialog(
      context,
      title: remote ? 'Remote DNS' : 'Bootstrap DNS',
      label: remote ? 'DoH URL or DNS address' : 'IP address',
      initialValue: remote ? preferences.remoteDns : preferences.directDns,
    );
    if (value != null && value.trim().isNotEmpty) {
      await ref.read(appControllerProvider.notifier).updateCorePreferences(
            remote
                ? preferences.copyWith(remoteDns: value.trim())
                : preferences.copyWith(directDns: value.trim()),
          );
    }
  }

  Future<void> _loadDiagnostics() async {
    setState(() => _loading = true);
    try {
      final value = await const AndroidPlatformBridge().getDiagnostics();
      if (mounted) setState(() => _diagnostics = value);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    final input = await showTrueTunTextDialog(
      context,
      title: 'Import proxy',
      label: 'VLESS / Hysteria2 link or config',
      maxLines: 5,
    );
    if (input != null && input.trim().isNotEmpty) {
      ref.read(appControllerProvider.notifier).importProfile(input);
    }
  } else if (action == 'group') {
    final name = await showTrueTunTextDialog(
      context,
      title: 'Create group',
      label: 'Name',
    );
    if (name != null) {
      ref.read(appControllerProvider.notifier).createGroup(name);
    }
  } else if (action == 'subscription') {
    final subscription = await showTrueTunSubscriptionDialog(context);
    if (subscription != null) {
      await ref.read(appControllerProvider.notifier).addSubscription(
            subscription.$1,
            subscription.$2,
          );
    }
  }
}

String _pingLabel(int? value) {
  if (value == null) return 'Test';
  if (value < 0) return 'Fail';
  return '$value ms';
}

String _ruleSummary(RoutingRule rule) {
  final parts = <String>[];
  if (rule.matcher.domains.isNotEmpty) {
    parts.add('${rule.matcher.domains.length} domains');
  }
  if (rule.matcher.domainSuffixes.isNotEmpty) {
    parts.add('${rule.matcher.domainSuffixes.length} suffixes');
  }
  if (rule.matcher.ipCidrs.isNotEmpty) {
    parts.add('${rule.matcher.ipCidrs.length} CIDRs');
  }
  return parts.isEmpty ? 'custom matcher' : parts.join(' · ');
}

String _actionLabel(RouteAction action) => switch (action.type) {
      RouteActionType.proxy => action.outboundTag ?? 'proxy',
      RouteActionType.direct => 'direct',
      RouteActionType.block => 'block',
    };

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

String _formatMbps(int bytesPerSecond) =>
    '${(bytesPerSecond * 8 / 1000000).toStringAsFixed(1)} Mbps';

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KiB', 'MiB', 'GiB', 'TiB'];
  var value = bytes.toDouble();
  var unit = -1;
  do {
    value /= 1024;
    unit++;
  } while (value >= 1024 && unit < units.length - 1);
  final digits = value >= 100
      ? 0
      : value >= 10
          ? 1
          : 2;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}
