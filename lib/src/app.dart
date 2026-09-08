import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:truetun/src/application/app_state.dart';
import 'package:truetun/src/core/core_adapter.dart';
import 'package:truetun/src/core/core_preferences.dart';
import 'package:truetun/src/profiles/profile_group.dart';
import 'package:truetun/src/profiles/proxy_node.dart';

class TrueTunApp extends StatelessWidget {
  const TrueTunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrueTun',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF625BFF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8D87FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(icon: Icon(Icons.power_settings_new), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.dns_outlined), label: 'Profiles'),
    NavigationDestination(icon: Icon(Icons.alt_route), label: 'Routing'),
    NavigationDestination(icon: Icon(Icons.apps), label: 'Apps'),
    NavigationDestination(icon: Icon(Icons.article_outlined), label: 'Logs'),
    NavigationDestination(
        icon: Icon(Icons.settings_outlined), label: 'Settings'),
  ];

  static const _pages = <Widget>[
    _HomePage(),
    _ProfilesPage(),
    _PlaceholderPage(
      title: 'Routing',
      body: 'Ordered Mihomo-style rules, rule sets and proxy groups live here.',
      icon: Icons.alt_route,
    ),
    _PlaceholderPage(
      title: 'Apps',
      body:
          'Android include/exclude app routing and smart local suggestions live here.',
      icon: Icons.apps,
    ),
    _LogsPage(),
    _SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        if (!desktop) {
          return Scaffold(
            body: SafeArea(child: _pages[_index]),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              destinations: _destinations,
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
                  leading: const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: _BrandMark(),
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
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
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

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'TrueTun',
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.shield_outlined),
      ),
    );
  }
}

class _HomePage extends ConsumerWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final busy = state.coreState == ProxyCoreState.starting ||
        state.coreState == ProxyCoreState.stopping;
    final running = state.coreState == ProxyCoreState.running;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('TrueTun', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 32),
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: running
                  ? Colors.green.withValues(alpha: 0.22)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              boxShadow: running
                  ? [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
            child: FilledButton(
              style: FilledButton.styleFrom(
                fixedSize: const Size(174, 174),
                shape: const CircleBorder(),
                backgroundColor: running
                    ? Colors.green.shade700
                    : Theme.of(context).colorScheme.surfaceContainerHigh,
                foregroundColor: running
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: state.node == null || busy
                  ? null
                  : () => running
                      ? ref.read(appControllerProvider.notifier).disconnect()
                      : ref.read(appControllerProvider.notifier).connect(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    running ? Icons.shield : Icons.power_settings_new,
                    size: 46,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    state.node == null
                        ? 'NO PROFILE'
                        : running
                            ? 'PROXY ON'
                            : busy
                                ? state.coreState.name.toUpperCase()
                                : 'PROXY OFF',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (state.node != null) ...[
          const SizedBox(height: 16),
          Text(state.node!.name, textAlign: TextAlign.center),
        ],
        if (state.error != null) ...[
          const SizedBox(height: 16),
          Text(
            state.error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 32),
        _ConnectionOverview(
          state: state,
          running: running,
          onTest: state.testing
              ? null
              : ref.read(appControllerProvider.notifier).testConnection,
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Profiles',
                  style: Theme.of(context).textTheme.headlineMedium),
            ),
            FilledButton.icon(
              onPressed: () => _showAddMenu(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (state.groups.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.link),
              title: Text('No profile groups'),
              subtitle:
                  Text('Create a group, import a link, or add a subscription.'),
            ),
          )
        else
          for (final group in state.groups)
            _ProfileGroupCard(
              key: ValueKey(group.id),
              group: group,
              selectedProfileId: state.selectedProfileId,
              selected: group.id == state.selectedGroupId,
              profilePings: state.profilePings,
              pingingProfiles: state.pingingProfiles,
              onAddProfile: () => _showImportDialog(
                context,
                ref,
                targetGroupId: group.id,
              ),
              onRefresh: () => ref
                  .read(appControllerProvider.notifier)
                  .refreshGroup(group.id),
              onDelete: () => ref
                  .read(appControllerProvider.notifier)
                  .deleteGroup(group.id),
              onEditGroup: () => _showGroupEditDialog(context, ref, group),
              onTestGroup: () =>
                  ref.read(appControllerProvider.notifier).testGroup(group.id),
              onTestProfile: (profileId) => ref
                  .read(appControllerProvider.notifier)
                  .testProfile(profileId),
              onEditProfile: (profile) =>
                  _showProfileEditDialog(context, ref, group.id, profile),
              onSelectProfile: (profileId) => ref
                  .read(appControllerProvider.notifier)
                  .selectProfile(group.id, profileId),
            ),
      ],
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
              onTap: () => Navigator.pop(context, 'link'),
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
    if (!context.mounted) return;
    switch (action) {
      case 'link':
        await _showImportDialog(context, ref);
      case 'subscription':
        await _showSubscriptionDialog(context, ref);
      case 'group':
        await _showGroupDialog(context, ref);
    }
  }

  Future<void> _showSubscriptionDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final name = TextEditingController();
    final url = TextEditingController();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Group name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: url,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Subscription URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, (name.text, url.text)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    name.dispose();
    url.dispose();
    if (result != null) {
      await ref
          .read(appControllerProvider.notifier)
          .addSubscription(result.$1, result.$2);
    }
  }

  Future<void> _showGroupDialog(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create group'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Group name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, name.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    name.dispose();
    if (result != null) {
      ref.read(appControllerProvider.notifier).createGroup(result);
    }
  }

  Future<void> _showImportDialog(
    BuildContext context,
    WidgetRef ref, {
    String targetGroupId = 'manual',
  }) async {
    final input = TextEditingController();
    final link = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import proxy link / config'),
        content: TextField(
          controller: input,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'vless://… / hysteria2://… / Hysteria2 YAML',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    input.dispose();
    if (link != null && link.trim().isNotEmpty) {
      ref
          .read(appControllerProvider.notifier)
          .importProfile(link, targetGroupId: targetGroupId);
    }
  }

  Future<void> _showGroupEditDialog(
    BuildContext context,
    WidgetRef ref,
    ProfileGroup group,
  ) async {
    final name = TextEditingController(text: group.name);
    final url = TextEditingController(text: group.subscriptionUrl?.toString());
    var autoUpdate = group.autoUpdateEnabled;
    var interval = group.autoUpdateMinutes;
    final result = await showDialog<_GroupEditResult>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit group'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Group name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: url,
                  decoration: const InputDecoration(
                    labelText: 'Subscription URL',
                    hintText: 'https://…',
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Automatic updates'),
                  subtitle: const Text('Refresh subscription in background'),
                  value: autoUpdate,
                  onChanged: (value) =>
                      setDialogState(() => autoUpdate = value),
                ),
                DropdownButtonFormField<int>(
                  initialValue: interval,
                  decoration:
                      const InputDecoration(labelText: 'Update frequency'),
                  items: const [15, 30, 60, 180, 360, 720, 1440]
                      .map(
                        (minutes) => DropdownMenuItem(
                          value: minutes,
                          child: Text(_formatInterval(minutes)),
                        ),
                      )
                      .toList(),
                  onChanged: autoUpdate
                      ? (value) => setDialogState(() => interval = value ?? 60)
                      : null,
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
              onPressed: () {
                final rawUrl = url.text.trim();
                final parsedUrl = rawUrl.isEmpty ? null : Uri.tryParse(rawUrl);
                if (name.text.trim().isEmpty ||
                    (parsedUrl != null &&
                        parsedUrl.scheme != 'https' &&
                        parsedUrl.scheme != 'http')) {
                  return;
                }
                Navigator.pop(
                  context,
                  _GroupEditResult(
                    name.text.trim(),
                    parsedUrl,
                    autoUpdate,
                    interval,
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
    url.dispose();
    if (result == null) return;
    await ref.read(appControllerProvider.notifier).updateGroup(
          groupId: group.id,
          name: result.name,
          subscriptionUrl: result.url,
          autoUpdateEnabled: result.autoUpdate,
          autoUpdateMinutes: result.interval,
        );
  }

  Future<void> _showProfileEditDialog(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    ManagedProfile profile,
  ) async {
    final node = profile.node;
    if (node is! VlessNode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hysteria2 profile editing is not available yet; re-import the profile to change it.',
          ),
        ),
      );
      return;
    }
    final name = TextEditingController(text: node.name);
    final server = TextEditingController(text: node.server);
    final port = TextEditingController(text: node.port.toString());
    final uuid = TextEditingController(text: node.uuid);
    final sni = TextEditingController(text: node.tls.serverName);
    final host = TextEditingController(text: node.transport.host);
    final path = TextEditingController(text: node.transport.path);
    final service = TextEditingController(text: node.transport.serviceName);
    final mode = TextEditingController(text: node.transport.mode);
    final publicKey = TextEditingController(text: node.tls.reality?.publicKey);
    final shortId = TextEditingController(text: node.tls.reality?.shortId);
    var transport = node.transport.type;
    var security = node.tls.reality != null
        ? 'reality'
        : node.tls.enabled
            ? 'tls'
            : 'none';
    var insecure = node.tls.insecure;
    String? validationError;
    final updated = await showDialog<VlessNode>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit connection'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: server,
                          decoration:
                              const InputDecoration(labelText: 'Server'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: port,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Port'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: uuid,
                    decoration: const InputDecoration(labelText: 'UUID'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: security,
                          decoration:
                              const InputDecoration(labelText: 'Security'),
                          items: const [
                            DropdownMenuItem(
                                value: 'none', child: Text('None')),
                            DropdownMenuItem(value: 'tls', child: Text('TLS')),
                            DropdownMenuItem(
                              value: 'reality',
                              child: Text('Reality'),
                            ),
                          ],
                          onChanged: (value) => setDialogState(
                            () => security = value ?? 'none',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<V2RayTransportType>(
                          initialValue: transport,
                          decoration:
                              const InputDecoration(labelText: 'Transport'),
                          items: V2RayTransportType.values
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setDialogState(
                            () => transport = value ?? transport,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (security != 'none') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: sni,
                      decoration: const InputDecoration(labelText: 'SNI'),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Allow insecure TLS'),
                      value: insecure,
                      onChanged: (value) =>
                          setDialogState(() => insecure = value ?? false),
                    ),
                  ],
                  if (security == 'reality') ...[
                    TextField(
                      controller: publicKey,
                      decoration: const InputDecoration(
                          labelText: 'Reality public key'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: shortId,
                      decoration:
                          const InputDecoration(labelText: 'Reality short ID'),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: host,
                    decoration:
                        const InputDecoration(labelText: 'Transport host'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: path,
                    decoration:
                        const InputDecoration(labelText: 'Path / XHTTP path'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: service,
                    decoration:
                        const InputDecoration(labelText: 'gRPC service name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: mode,
                    decoration: const InputDecoration(labelText: 'XHTTP mode'),
                  ),
                  if (validationError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      validationError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsedPort = int.tryParse(port.text.trim());
                final uuidPattern = RegExp(
                  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
                );
                if (name.text.trim().isEmpty ||
                    server.text.trim().isEmpty ||
                    parsedPort == null ||
                    parsedPort < 1 ||
                    parsedPort > 65535 ||
                    !uuidPattern.hasMatch(uuid.text.trim()) ||
                    (security == 'reality' && publicKey.text.trim().isEmpty)) {
                  setDialogState(
                    () => validationError =
                        'Check name, address, port and credentials.',
                  );
                  return;
                }
                String? optional(String value) =>
                    value.trim().isEmpty ? null : value.trim();
                Navigator.pop(
                  context,
                  node.copyWith(
                    name: name.text.trim(),
                    server: server.text.trim(),
                    port: parsedPort,
                    uuid: uuid.text.trim(),
                    tls: TlsOptions(
                      enabled: security != 'none',
                      serverName: optional(sni.text),
                      alpn: node.tls.alpn,
                      insecure: insecure,
                      fingerprint: node.tls.fingerprint,
                      reality: security == 'reality'
                          ? RealityOptions(
                              publicKey: publicKey.text.trim(),
                              shortId: shortId.text.trim(),
                            )
                          : null,
                    ),
                    transport: V2RayTransportOptions(
                      type: transport,
                      host: optional(host.text),
                      path: optional(path.text),
                      serviceName: optional(service.text),
                      mode: optional(mode.text),
                    ),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    for (final controller in [
      name,
      server,
      port,
      uuid,
      sni,
      host,
      path,
      service,
      mode,
      publicKey,
      shortId,
    ]) {
      controller.dispose();
    }
    if (updated != null) {
      await ref.read(appControllerProvider.notifier).updateProfile(
            groupId: groupId,
            profileId: profile.id,
            node: updated,
          );
    }
  }
}

class _ConnectionOverview extends StatelessWidget {
  const _ConnectionOverview({
    required this.state,
    required this.running,
    required this.onTest,
  });

  final AppState state;
  final bool running;
  final VoidCallback? onTest;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final samples = state.trafficHistory;
    final latest = samples.isEmpty ? null : samples.last;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 680;
          final status = _ConnectionStatusPane(
            state: state,
            running: running,
            onTest: onTest,
          );
          final traffic = _TrafficPane(
            samples: samples,
            upload: state.upload,
            download: state.download,
            uploadRate: latest?.uploadPerSecond ?? 0,
            downloadRate: latest?.downloadPerSecond ?? 0,
          );
          if (!wide) {
            return Column(
              children: [
                status,
                Divider(height: 1, color: colors.outlineVariant),
                traffic,
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: status),
                VerticalDivider(width: 1, color: colors.outlineVariant),
                Expanded(flex: 2, child: traffic),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConnectionStatusPane extends StatelessWidget {
  const _ConnectionStatusPane({
    required this.state,
    required this.running,
    required this.onTest,
  });

  final AppState state;
  final bool running;
  final VoidCallback? onTest;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = running ? Colors.green : colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: running
                      ? [BoxShadow(color: statusColor, blurRadius: 8)]
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  running ? 'Connected' : 'Disconnected',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (running)
                IconButton(
                  tooltip: 'Test connection',
                  onPressed: onTest,
                  icon: state.testing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('PING', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 3),
          Text(
            state.latency == null
                ? '— ms'
                : '${state.latency!.inMilliseconds} ms',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: running ? colors.primary : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            state.testing
                ? 'Testing connection…'
                : running
                    ? 'Profile is online'
                    : 'Connect to test this profile',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _TrafficPane extends StatelessWidget {
  const _TrafficPane({
    required this.samples,
    required this.upload,
    required this.download,
    required this.uploadRate,
    required this.downloadRate,
  });

  final List<TrafficSample> samples;
  final int upload;
  final int download;
  final int uploadRate;
  final int downloadRate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Traffic',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TrafficValue(
                  color: colors.primary,
                  label: 'DOWNLOAD',
                  value: _formatBytes(download),
                  rate: '${_formatBytes(downloadRate)}/s',
                ),
              ),
              Expanded(
                child: _TrafficValue(
                  color: colors.tertiary,
                  label: 'UPLOAD',
                  value: _formatBytes(upload),
                  rate: '${_formatBytes(uploadRate)}/s',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 92,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrafficChartPainter(
                samples: samples,
                downloadColor: colors.primary,
                uploadColor: colors.tertiary,
                gridColor: colors.outlineVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrafficValue extends StatelessWidget {
  const _TrafficValue({
    required this.color,
    required this.label,
    required this.value,
    required this.rate,
  });

  final Color color;
  final String label;
  final String value;
  final String rate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            Text(rate, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
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
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var row = 0; row <= 2; row++) {
      final y = size.height * row / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (samples.length < 2) return;
    var maximum = 1;
    for (final sample in samples) {
      if (sample.downloadPerSecond > maximum) {
        maximum = sample.downloadPerSecond;
      }
      if (sample.uploadPerSecond > maximum) {
        maximum = sample.uploadPerSecond;
      }
    }
    void drawSeries(int Function(TrafficSample) value, Color color) {
      final values = <double>[];
      for (final sample in samples) {
        final raw = value(sample).toDouble();
        values.add(values.isEmpty ? raw : values.last * 0.68 + raw * 0.32);
      }
      final path = Path();
      Offset pointAt(int index) => Offset(
            size.width * index / (values.length - 1),
            size.height - (values[index] / maximum) * size.height,
          );
      var previous = pointAt(0);
      path.moveTo(previous.dx, previous.dy);
      for (var index = 1; index < values.length; index++) {
        final current = pointAt(index);
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
        previous = current;
      }
      path.lineTo(previous.dx, previous.dy);
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }

    drawSeries((sample) => sample.downloadPerSecond, downloadColor);
    drawSeries((sample) => sample.uploadPerSecond, uploadColor);
  }

  @override
  bool shouldRepaint(covariant _TrafficChartPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.downloadColor != downloadColor ||
        oldDelegate.uploadColor != uploadColor;
  }
}

class _ProfileGroupCard extends StatefulWidget {
  const _ProfileGroupCard({
    super.key,
    required this.group,
    required this.selectedProfileId,
    required this.selected,
    required this.profilePings,
    required this.pingingProfiles,
    required this.onAddProfile,
    required this.onRefresh,
    required this.onDelete,
    required this.onSelectProfile,
    required this.onEditGroup,
    required this.onTestGroup,
    required this.onTestProfile,
    required this.onEditProfile,
  });

  final ProfileGroup group;
  final String? selectedProfileId;
  final bool selected;
  final Map<String, int> profilePings;
  final Set<String> pingingProfiles;
  final VoidCallback onAddProfile;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;
  final ValueChanged<String> onSelectProfile;
  final VoidCallback onEditGroup;
  final VoidCallback onTestGroup;
  final ValueChanged<String> onTestProfile;
  final ValueChanged<ManagedProfile> onEditProfile;

  @override
  State<_ProfileGroupCard> createState() => _ProfileGroupCardState();
}

class _ProfileGroupCardState extends State<_ProfileGroupCard> {
  late bool _expanded = widget.selected;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: widget.selected
          ? colors.primaryContainer.withValues(alpha: 0.28)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: widget.selected
              ? colors.primary.withValues(alpha: 0.65)
              : colors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            leading: Icon(
              group.isSubscription ? Icons.cloud_sync : Icons.folder_outlined,
              color: widget.selected ? colors.primary : null,
            ),
            title: Text(
              group.name,
              style: TextStyle(
                color: widget.selected ? colors.primary : null,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            subtitle: Text(
              group.updating
                  ? 'Updating…'
                  : group.error ??
                      '${group.profiles.length} profiles'
                          '${group.autoUpdateEnabled ? ' · auto ${_formatInterval(group.autoUpdateMinutes).toLowerCase()}' : ''}',
              style:
                  group.error == null ? null : TextStyle(color: colors.error),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Test group latency',
                  onPressed: group.profiles.isEmpty ? null : widget.onTestGroup,
                  icon: const Icon(Icons.speed),
                ),
                if (!group.isSubscription)
                  IconButton(
                    tooltip: 'Add proxy profile',
                    onPressed: widget.onAddProfile,
                    icon: const Icon(Icons.add_link),
                  ),
                if (group.isSubscription)
                  IconButton(
                    tooltip: 'Refresh subscription',
                    onPressed: group.updating ? null : widget.onRefresh,
                    icon: group.updating
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  ),
                PopupMenuButton<String>(
                  tooltip: 'Group actions',
                  onSelected: (action) {
                    if (action == 'edit') widget.onEditGroup();
                    if (action == 'delete') widget.onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit group')),
                    PopupMenuItem(value: 'delete', child: Text('Delete group')),
                  ],
                ),
                IconButton(
                  tooltip: _expanded ? 'Collapse group' : 'Expand group',
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    children: [
                      Divider(height: 1, color: colors.outlineVariant),
                      if (group.profiles.isEmpty)
                        const ListTile(title: Text('This group is empty')),
                      for (final profile in group.profiles)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            selected: profile.id == widget.selectedProfileId,
                            selectedTileColor:
                                colors.primaryContainer.withValues(alpha: 0.55),
                            leading: Icon(
                              profile.id == widget.selectedProfileId
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                            ),
                            title: Text(profile.node.name),
                            subtitle: Text(
                              '${profile.node.server}:${profile.node.port} · ' +
                                  _profileTypeLabel(profile.node),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ProfilePing(
                                  milliseconds: widget.profilePings[profile.id],
                                  testing: widget.pingingProfiles.contains(
                                    profile.id,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Test latency',
                                  onPressed: () =>
                                      widget.onTestProfile(profile.id),
                                  icon: const Icon(Icons.speed, size: 20),
                                ),
                                IconButton(
                                  tooltip: 'Edit connection',
                                  onPressed: () =>
                                      widget.onEditProfile(profile),
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 20),
                                ),
                              ],
                            ),
                            onTap: () => widget.onSelectProfile(profile.id),
                          ),
                        ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ProfilePing extends StatelessWidget {
  const _ProfilePing({required this.milliseconds, required this.testing});

  final int? milliseconds;
  final bool testing;

  @override
  Widget build(BuildContext context) {
    if (testing) {
      return const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final value = milliseconds;
    if (value == null) {
      return Text('— ms', style: Theme.of(context).textTheme.bodySmall);
    }
    final color = value < 0
        ? Theme.of(context).colorScheme.error
        : value < 150
            ? Colors.green
            : value < 350
                ? Colors.orange
                : Theme.of(context).colorScheme.error;
    return Text(
      value < 0 ? 'timeout' : '$value ms',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _GroupEditResult {
  const _GroupEditResult(
    this.name,
    this.url,
    this.autoUpdate,
    this.interval,
  );

  final String name;
  final Uri? url;
  final bool autoUpdate;
  final int interval;
}

String _profileTypeLabel(ProxyNode node) {
  return switch (node) {
    VlessNode(:final transport) => 'VLESS · ${transport.type.name}',
    Hysteria2Node() => 'Hysteria2',
  };
}

String _formatInterval(int minutes) {
  if (minutes < 60) return 'Every $minutes minutes';
  if (minutes == 60) return 'Every hour';
  if (minutes < 1440) return 'Every ${minutes ~/ 60} hours';
  return 'Every day';
}

class _LogsPage extends ConsumerWidget {
  const _LogsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Logs',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              TextButton.icon(
                onPressed: state.logs.isEmpty
                    ? null
                    : ref.read(appControllerProvider.notifier).clearLogs,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.logs.isEmpty
              ? const Center(child: Text('No log entries'))
              : SelectionArea(
                  child: ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: state.logs.length,
                    itemBuilder: (context, index) {
                      final line = state.logs[state.logs.length - index - 1];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '$line\n',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _SettingsPage extends ConsumerStatefulWidget {
  const _SettingsPage();

  @override
  ConsumerState<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<_SettingsPage> {
  late final TextEditingController _mtu;
  late final TextEditingController _remoteDns;
  late final TextEditingController _directDns;

  @override
  void initState() {
    super.initState();
    final preferences = ref.read(appControllerProvider).corePreferences;
    _mtu = TextEditingController(text: preferences.mtu.toString());
    _remoteDns = TextEditingController(text: preferences.remoteDns);
    _directDns = TextEditingController(text: preferences.directDns);
  }

  Future<void> _save(CorePreferences current) async {
    final mtu = int.tryParse(_mtu.text.trim());
    if (mtu == null || mtu < 1280 || mtu > 65535) return;
    await ref.read(appControllerProvider.notifier).updateCorePreferences(
          current.copyWith(
            mtu: mtu,
            remoteDns: _remoteDns.text.trim(),
            directDns: _directDns.text.trim(),
          ),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Core settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final preferences = state.corePreferences;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Linux', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start TrueTun when you sign in'),
                  subtitle: const Text('Starts hidden in the system tray'),
                  value: state.autostartEnabled,
                  onChanged:
                      ref.read(appControllerProvider.notifier).setAutostart,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Keep running in the system tray'),
                  subtitle: const Text(
                    'Closing the window hides it while the proxy stays active',
                  ),
                  value: state.minimizeToTray,
                  onChanged: ref
                      .read(appControllerProvider.notifier)
                      .setMinimizeToTray,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Core', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                const Text('Changes apply on the next connection.'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: preferences.logLevel,
                        decoration:
                            const InputDecoration(labelText: 'Log level'),
                        items: const ['trace', 'debug', 'info', 'warn', 'error']
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => ref
                            .read(appControllerProvider.notifier)
                            .updateCorePreferences(
                              preferences.copyWith(logLevel: value),
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: preferences.stack,
                        decoration:
                            const InputDecoration(labelText: 'TUN stack'),
                        items: const ['mixed', 'system', 'gvisor']
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => ref
                            .read(appControllerProvider.notifier)
                            .updateCorePreferences(
                              preferences.copyWith(stack: value),
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _mtu,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'MTU',
                    helperText: '1280–65535',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Strict routing'),
                  value: preferences.strictRoute,
                  onChanged: (value) => ref
                      .read(appControllerProvider.notifier)
                      .updateCorePreferences(
                        preferences.copyWith(strictRoute: value),
                      ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('IPv6'),
                  value: preferences.ipv6,
                  onChanged: (value) => ref
                      .read(appControllerProvider.notifier)
                      .updateCorePreferences(
                        preferences.copyWith(ipv6: value),
                      ),
                ),
                TextField(
                  controller: _remoteDns,
                  decoration:
                      const InputDecoration(labelText: 'Remote DNS server'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _directDns,
                  decoration:
                      const InputDecoration(labelText: 'Direct DNS server'),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => _save(preferences),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save core settings'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mtu.dispose();
    _remoteDns.dispose();
    _directDns.dispose();
    super.dispose();
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kib = bytes / 1024;
  if (kib < 1024) return '${kib.toStringAsFixed(1)} KiB';
  final mib = kib / 1024;
  if (mib < 1024) return '${mib.toStringAsFixed(1)} MiB';
  return '${(mib / 1024).toStringAsFixed(2)} GiB';
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56),
              const SizedBox(height: 20),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(body, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
