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

class _HomePage extends ConsumerWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final running = state.coreState == ProxyCoreState.running;
    final busy = state.coreState == ProxyCoreState.starting ||
        state.coreState == ProxyCoreState.stopping;
    final sample = state.trafficHistory.isEmpty ? null : state.trafficHistory.last;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text('TrueTun', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 28),
        Center(
          child: FilledButton(
            style: FilledButton.styleFrom(
              fixedSize: const Size(176, 176),
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
                Icon(running ? Icons.shield : Icons.power_settings_new, size: 48),
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
        const SizedBox(height: 16),
        Text(
          state.node?.name ?? 'Choose a profile to connect',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (state.node != null)
          Text(
            '${state.node!.protocol.name.toUpperCase()} · '
            '${state.node!.server}:${state.node!.port}',
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
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.upload,
                title: 'Upload',
                value: _formatRate(sample?.uploadPerSecond ?? 0),
                detail: _formatBytes(state.upload),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.download,
                title: 'Download',
                value: _formatRate(sample?.downloadPerSecond ?? 0),
                detail: _formatBytes(state.download),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.network_check),
            title: const Text('Connection test'),
            subtitle: Text(
              state.latency == null ? 'Not measured' : '${state.latency!.inMilliseconds} ms',
            ),
            trailing: state.testing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: running && !state.testing ? controller.testConnection : null,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live traffic', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: _TrafficBars(samples: state.trafficHistory),
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
            Row(children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(title)]),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            Text(detail, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _TrafficBars extends StatelessWidget {
  const _TrafficBars({required this.samples});

  final List<TrafficSample> samples;

  @override
  Widget build(BuildContext context) {
    final visible = samples.length <= 40 ? samples : samples.sublist(samples.length - 40);
    var maximum = 1;
    for (final sample in visible) {
      if (sample.uploadPerSecond > maximum) maximum = sample.uploadPerSecond;
      if (sample.downloadPerSecond > maximum) maximum = sample.downloadPerSecond;
    }
    if (visible.isEmpty) {
      return const Center(child: Text('Traffic samples will appear after connection'));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final sample in visible)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: sample.downloadPerSecond / maximum,
                      alignment: Alignment.bottomCenter,
                      child: Container(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: sample.uploadPerSecond / maximum,
                      alignment: Alignment.bottomCenter,
                      child: Container(color: Theme.of(context).colorScheme.tertiary),
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

class _ProfilesPage extends ConsumerWidget {
  const _ProfilesPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
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
      body: state.groups.isEmpty
          ? const Center(child: Text('Add a proxy link or subscription'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              children: [
                for (final group in state.groups)
                  Card(
                    child: ExpansionTile(
                      initiallyExpanded: group.id == state.selectedGroupId,
                      title: Text(group.name),
                      subtitle: Text('${group.profiles.length} profiles'),
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
                            const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
                          const PopupMenuItem(value: 'test', child: Text('Test all')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
                            trailing: _PingButton(profile: profile),
                            onTap: () => controller.selectProfile(group.id, profile.id),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PingButton extends ConsumerWidget {
  const _PingButton({required this.profile});

  final ManagedProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final value = state.profilePings[profile.id];
    final pending = state.pingingProfiles.contains(profile.id);
    return TextButton(
      onPressed: pending
          ? null
          : () => ref.read(appControllerProvider.notifier).testProfile(profile.id),
      child: pending
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(value == null ? 'Test' : value < 0 ? 'Fail' : '$value ms'),
    );
  }
}

class _RoutingPage extends ConsumerWidget {
  const _RoutingPage();

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
              final rule = await _editRule(context);
              if (rule != null) {
                await controller.addRoutingRule(rule);
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: state.routingRules.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'Rules are evaluated from top to bottom. Without custom rules, '
                  'traffic uses the selected proxy.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: state.routingRules.length,
              itemBuilder: (context, index) {
                final rule = state.routingRules[index];
                return Card(
                  child: ListTile(
                    title: Text(rule.name),
                    subtitle: Text('${_ruleSummary(rule)} → ${_actionLabel(rule.action)}'),
                    onTap: () async {
                      final updated = await _editRule(context, existing: rule);
                      if (updated != null) {
                        await controller.updateRoutingRule(updated);
                      }
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Move up',
                          onPressed: index == 0
                              ? null
                              : () => controller.reorderRoutingRule(index, index - 1),
                          icon: const Icon(Icons.arrow_upward),
                        ),
                        IconButton(
                          tooltip: 'Move down',
                          onPressed: index == state.routingRules.length - 1
                              ? null
                              : () => controller.reorderRoutingRule(index, index + 2),
                          icon: const Icon(Icons.arrow_downward),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'toggle') {
                              controller.updateRoutingRule(
                                RoutingRule(
                                  id: rule.id,
                                  name: rule.name,
                                  matcher: rule.matcher,
                                  action: rule.action,
                                  enabled: !rule.enabled,
                                ),
                              );
                            } else if (action == 'delete') {
                              controller.deleteRoutingRule(rule.id);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(rule.enabled ? 'Disable' : 'Enable'),
                            ),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
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
            tooltip: 'Refresh',
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
                ),
                ButtonSegment(
                  value: AppRoutingMode.proxyOnlySelected,
                  label: Text('Whitelist'),
                ),
              ],
              selected: {policy.mode},
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
                  tooltip: _showSystem ? 'Hide system apps' : 'Show system apps',
                  onPressed: () => setState(() => _showSystem = !_showSystem),
                  icon: Icon(_showSystem ? Icons.android : Icons.android_outlined),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (state.loadingInstalledApps) const LinearProgressIndicator(),
          Expanded(
            child: apps.isEmpty
                ? const Center(child: Text('No matching apps'))
                : ListView.builder(
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      final checked = policy.selectedPackageNames.contains(app.packageName);
                      final suggestion = const SmartAppSuggestionEngine().suggest(
                        app,
                        ownPackageName: 'app.truetun',
                      );
                      return CheckboxListTile(
                        value: checked,
                        onChanged: app.packageName == 'app.truetun'
                            ? null
                            : (value) {
                                controller.setAppSelected(app.packageName, value ?? false);
                              },
                        title: Text(app.label),
                        subtitle: Text(
                          '${app.packageName}\n${_suggestionLabel(suggestion)}',
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
    final selected = <String>{};
    const engine = SmartAppSuggestionEngine();
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
    final state = ref.watch(appControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            tooltip: 'Clear',
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
    final state = ref.watch(appControllerProvider);
    final preferences = state.corePreferences;
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
            onChanged: (value) {
              controller.updateCorePreferences(
                preferences.copyWith(strictRoute: value),
              );
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.language),
            title: const Text('IPv6'),
            value: preferences.ipv6,
            onChanged: (value) {
              controller.updateCorePreferences(preferences.copyWith(ipv6: value));
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('MTU'),
            subtitle: Text('${preferences.mtu}'),
            onTap: () => _editMtu(context),
          ),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Remote DNS'),
            subtitle: Text(preferences.remoteDns),
            onTap: () => _editDns(context, remote: true),
          ),
          ListTile(
            leading: const Icon(Icons.dns),
            title: const Text('Bootstrap DNS'),
            subtitle: Text(preferences.directDns),
            onTap: () => _editDns(context, remote: false),
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
              maxLines: _diagnostics == null ? 2 : 8,
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

  Future<void> _editMtu(BuildContext context) async {
    final preferences = ref.read(appControllerProvider).corePreferences;
    final raw = await _textDialog(
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

  Future<void> _editDns(BuildContext context, {required bool remote}) async {
    final preferences = ref.read(appControllerProvider).corePreferences;
    final value = await _textDialog(
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
      if (mounted) {
        setState(() => _diagnostics = value);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

Future<void> _showAddProfileMenu(BuildContext context, WidgetRef ref) async {
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
    if (name != null) {
      ref.read(appControllerProvider.notifier).createGroup(name);
    }
  } else if (action == 'subscription') {
    final subscription = await _subscriptionDialog(context);
    if (subscription != null) {
      await ref.read(appControllerProvider.notifier).addSubscription(
            subscription.$1,
            subscription.$2,
          );
    }
  }
}

Future<RoutingRule?> _editRule(
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
              TextField(
                controller: domains,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Exact domains'),
              ),
              TextField(
                controller: suffixes,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Domain suffixes'),
              ),
              TextField(
                controller: cidrs,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'IP CIDRs'),
              ),
              DropdownButtonFormField<RouteActionType>(
                initialValue: action,
                decoration: const InputDecoration(labelText: 'Action'),
                items: const [
                  DropdownMenuItem(value: RouteActionType.proxy, child: Text('Proxy')),
                  DropdownMenuItem(value: RouteActionType.direct, child: Text('Direct')),
                  DropdownMenuItem(value: RouteActionType.block, child: Text('Block')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => action = value);
                  }
                },
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
  final result = await showDialog<String>(
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
  return result;
}

Future<(String, String)?> _subscriptionDialog(BuildContext context) async {
  final name = TextEditingController();
  final url = TextEditingController();
  final result = await showDialog<(String, String)>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add subscription'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: url, decoration: const InputDecoration(labelText: 'URL')),
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
  return result;
}

List<String> _lines(String value) => value
    .split(RegExp(r'[,\n]'))
    .map((entry) => entry.trim())
    .where((entry) => entry.isNotEmpty)
    .toList(growable: false);

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

String _suggestionLabel(AppRoutingSuggestion suggestion) =>
    switch (suggestion.recommendation) {
      AppRoutingRecommendation.proxy => 'Suggested: proxy',
      AppRoutingRecommendation.bypass => 'Suggested: bypass',
      AppRoutingRecommendation.neutral => 'No automatic recommendation',
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
