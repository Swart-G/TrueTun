import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:truetun/src/core/connection_controller.dart';
import 'package:truetun/src/core/connection_diagnostics.dart';
import 'package:truetun/src/core/connection_snapshot.dart';
import 'package:truetun/src/core/core_adapter.dart';
import 'package:truetun/src/core/core_preferences.dart';
import 'package:truetun/src/core/process_sing_box_adapter.dart';
import 'package:truetun/src/profiles/proxy_node.dart';
import 'package:truetun/src/profiles/profile_group.dart';
import 'package:truetun/src/profiles/subscription_service.dart';
import 'package:truetun/src/profiles/proxy_profile_parser.dart';
import 'package:truetun/src/persistence/app_database.dart';
import 'package:truetun/src/persistence/profile_repository.dart';
import 'package:truetun/src/routing/routing_rule.dart';
import 'package:truetun/src/application/linux_desktop_settings.dart';

class AppState {
  const AppState({
    this.node,
    this.coreState = ProxyCoreState.stopped,
    this.error,
    this.logs = const [],
    this.latency,
    this.upload = 0,
    this.download = 0,
    this.trafficHistory = const [],
    this.testing = false,
    this.groups = const [],
    this.selectedGroupId,
    this.selectedProfileId,
    this.profilePings = const {},
    this.pingingProfiles = const {},
    this.corePreferences = const CorePreferences(),
    this.autostartEnabled = false,
    this.minimizeToTray = true,
  });

  final ProxyNode? node;
  final ProxyCoreState coreState;
  final String? error;
  final List<String> logs;
  final Duration? latency;
  final int upload;
  final int download;
  final List<TrafficSample> trafficHistory;
  final bool testing;
  final List<ProfileGroup> groups;
  final String? selectedGroupId;
  final String? selectedProfileId;
  final Map<String, int> profilePings;
  final Set<String> pingingProfiles;
  final CorePreferences corePreferences;
  final bool autostartEnabled;
  final bool minimizeToTray;

  AppState copyWith({
    ProxyNode? node,
    bool clearNode = false,
    ProxyCoreState? coreState,
    String? error,
    bool clearError = false,
    List<String>? logs,
    Duration? latency,
    bool clearLatency = false,
    int? upload,
    int? download,
    List<TrafficSample>? trafficHistory,
    bool? testing,
    List<ProfileGroup>? groups,
    String? selectedGroupId,
    String? selectedProfileId,
    bool clearSelection = false,
    Map<String, int>? profilePings,
    Set<String>? pingingProfiles,
    CorePreferences? corePreferences,
    bool? autostartEnabled,
    bool? minimizeToTray,
  }) {
    return AppState(
      node: clearNode ? null : node ?? this.node,
      coreState: coreState ?? this.coreState,
      error: clearError ? null : error ?? this.error,
      logs: logs ?? this.logs,
      latency: clearLatency ? null : latency ?? this.latency,
      upload: upload ?? this.upload,
      download: download ?? this.download,
      trafficHistory: trafficHistory ?? this.trafficHistory,
      testing: testing ?? this.testing,
      groups: groups ?? this.groups,
      selectedGroupId:
          clearSelection ? null : selectedGroupId ?? this.selectedGroupId,
      selectedProfileId:
          clearSelection ? null : selectedProfileId ?? this.selectedProfileId,
      profilePings: profilePings ?? this.profilePings,
      pingingProfiles: pingingProfiles ?? this.pingingProfiles,
      corePreferences: corePreferences ?? this.corePreferences,
      autostartEnabled: autostartEnabled ?? this.autostartEnabled,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
    );
  }
}

class TrafficSample {
  const TrafficSample(
      {required this.uploadPerSecond, required this.downloadPerSecond});

  final int uploadPerSecond;
  final int downloadPerSecond;
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(database: ref.watch(databaseProvider));
});

final appControllerProvider =
    StateNotifierProvider<AppController, AppState>((ref) {
  return AppController(repository: ref.watch(profileRepositoryProvider));
});

class AppController extends StateNotifier<AppState> {
  AppController({
    ProxyProfileParser parser = const ProxyProfileParser(),
    ConnectionController? connection,
    ConnectionDiagnostics diagnostics = const ConnectionDiagnostics(),
    SubscriptionService subscriptions = const SubscriptionService(),
    ProfileRepository? repository,
    LinuxDesktopSettings desktopSettings = const LinuxDesktopSettings(),
  })  : _parser = parser,
        _connection = connection ??
            ConnectionController(adapter: ProcessSingBoxAdapter()),
        _diagnostics = diagnostics,
        _subscriptions = subscriptions,
        _repository = repository,
        _desktopSettings = desktopSettings,
        super(const AppState()) {
    _subscription = _connection.events.listen(_onCoreEvent);
    if (_repository != null) unawaited(_restoreProfiles());
    if (Platform.isLinux) unawaited(_restoreDesktopSettings());
  }

  final ProxyProfileParser _parser;
  final ConnectionController _connection;
  final ConnectionDiagnostics _diagnostics;
  final SubscriptionService _subscriptions;
  final ProfileRepository? _repository;
  final LinuxDesktopSettings _desktopSettings;
  late final StreamSubscription<CoreEvent> _subscription;
  Timer? _metricsTimer;
  DateTime? _lastMetricsAt;
  bool _metricsReadInProgress = false;
  final Map<String, Timer> _autoUpdateTimers = {};

  void importProfile(String link, {String targetGroupId = 'manual'}) {
    try {
      final node = _parser.parse(link);
      final profile = ManagedProfile(
        id: 'manual-${DateTime.now().microsecondsSinceEpoch}',
        node: node,
      );
      final groups = [...state.groups];
      final targetIndex =
          groups.indexWhere((group) => group.id == targetGroupId);
      if (targetIndex == -1) {
        targetGroupId = 'manual';
        groups.insert(
          0,
          ProfileGroup(id: 'manual', name: 'Manual', profiles: [profile]),
        );
      } else {
        final target = groups[targetIndex];
        groups[targetIndex] = target.copyWith(
          profiles: [...target.profiles, profile],
        );
      }
      state = state.copyWith(
        node: node,
        groups: groups,
        selectedGroupId: targetGroupId,
        selectedProfileId: profile.id,
        clearError: true,
      );
      unawaited(_saveGroup(targetGroupId));
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  @Deprecated('Use importProfile for protocol-neutral imports')
  void importVless(String link, {String targetGroupId = 'manual'}) {
    importProfile(link, targetGroupId: targetGroupId);
  }

  void createGroup(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) return;
    final group = ProfileGroup(
      id: 'group-${DateTime.now().microsecondsSinceEpoch}',
      name: normalized,
    );
    state = state.copyWith(groups: [...state.groups, group]);
    unawaited(_repository?.saveGroup(group));
  }

  Future<void> updateGroup({
    required String groupId,
    required String name,
    Uri? subscriptionUrl,
    required bool autoUpdateEnabled,
    required int autoUpdateMinutes,
  }) async {
    final group = state.groups.where((item) => item.id == groupId).firstOrNull;
    if (group == null || name.trim().isEmpty) return;
    final updated = group.copyWith(
      name: name.trim(),
      subscriptionUrl: subscriptionUrl,
      clearSubscriptionUrl: subscriptionUrl == null,
      autoUpdateEnabled: autoUpdateEnabled && subscriptionUrl != null,
      autoUpdateMinutes: autoUpdateMinutes,
    );
    _replaceGroup(updated);
    await _repository?.saveGroup(updated);
    _scheduleAutoUpdate(updated);
  }

  Future<void> updateCorePreferences(CorePreferences preferences) async {
    state = state.copyWith(corePreferences: preferences);
    await _repository?.saveCorePreferences(preferences);
  }

  Future<void> setAutostart(bool enabled) async {
    await _desktopSettings.setAutostart(enabled);
    state = state.copyWith(autostartEnabled: enabled);
  }

  Future<void> setMinimizeToTray(bool enabled) async {
    state = state.copyWith(minimizeToTray: enabled);
    await _repository?.saveMinimizeToTray(enabled);
  }

  Future<void> updateProfile({
    required String groupId,
    required String profileId,
    required ProxyNode node,
  }) async {
    final group = state.groups.where((item) => item.id == groupId).firstOrNull;
    if (group == null) return;
    final updated = group.copyWith(
      profiles: [
        for (final profile in group.profiles)
          if (profile.id == profileId)
            ManagedProfile(id: profile.id, node: node)
          else
            profile,
      ],
    );
    _replaceGroup(updated);
    if (state.selectedProfileId == profileId) {
      state = state.copyWith(node: node);
    }
    await _repository?.saveGroup(updated);
  }

  Future<void> testProfile(String profileId) async {
    ManagedProfile? profile;
    for (final group in state.groups) {
      profile =
          group.profiles.where((item) => item.id == profileId).firstOrNull;
      if (profile != null) break;
    }
    if (profile == null || state.pingingProfiles.contains(profileId)) return;
    state = state.copyWith(
      pingingProfiles: {...state.pingingProfiles, profileId},
    );
    try {
      final latency = await _diagnostics.testProfile(profile.node);
      state = state.copyWith(
        profilePings: {
          ...state.profilePings,
          profileId: latency.inMilliseconds,
        },
      );
    } catch (_) {
      state = state.copyWith(
        profilePings: {...state.profilePings, profileId: -1},
      );
    } finally {
      state = state.copyWith(
        pingingProfiles: {...state.pingingProfiles}..remove(profileId),
      );
    }
  }

  Future<void> testGroup(String groupId) async {
    final group = state.groups.where((item) => item.id == groupId).firstOrNull;
    if (group == null) return;
    for (var index = 0; index < group.profiles.length; index += 2) {
      final end = (index + 2).clamp(0, group.profiles.length);
      await Future.wait([
        for (final profile in group.profiles.sublist(index, end))
          testProfile(profile.id),
      ]);
    }
  }

  Future<void> addSubscription(String name, String rawUrl) async {
    final url = Uri.tryParse(rawUrl.trim());
    if (url == null || (url.scheme != 'https' && url.scheme != 'http')) {
      state = state.copyWith(error: 'Enter a valid subscription URL');
      return;
    }
    final group = ProfileGroup(
      id: 'subscription-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim().isEmpty ? url.host : name.trim(),
      subscriptionUrl: url,
      updating: true,
    );
    state = state.copyWith(groups: [...state.groups, group], clearError: true);
    await refreshGroup(group.id);
  }

  Future<void> refreshGroup(String groupId) async {
    final index = state.groups.indexWhere((group) => group.id == groupId);
    if (index == -1) return;
    final group = state.groups[index];
    final url = group.subscriptionUrl;
    if (url == null) return;
    _replaceGroup(group.copyWith(updating: true, clearError: true));
    try {
      final profiles = await _subscriptions.fetch(url);
      final updated = group.copyWith(
        profiles: profiles,
        updatedAt: DateTime.now(),
        updating: false,
        clearError: true,
      );
      _replaceGroup(updated);
      await _repository?.saveGroup(updated);
      _addLog(
          'Updated subscription ${group.name}: ${profiles.length} profiles');
      if (state.node == null && profiles.isNotEmpty) {
        selectProfile(group.id, profiles.first.id);
      }
    } catch (error) {
      _replaceGroup(group.copyWith(updating: false, error: error.toString()));
      _addLog('Subscription ${group.name} update failed: $error');
    }
  }

  void selectProfile(String groupId, String profileId) {
    final group =
        state.groups.where((value) => value.id == groupId).firstOrNull;
    final profile =
        group?.profiles.where((value) => value.id == profileId).firstOrNull;
    if (profile == null) return;
    state = state.copyWith(
      node: profile.node,
      selectedGroupId: groupId,
      selectedProfileId: profileId,
      clearError: true,
    );
    unawaited(_repository?.saveSelection(groupId, profileId));
  }

  Future<void> deleteGroup(String groupId) async {
    final removed =
        state.groups.where((group) => group.id == groupId).firstOrNull;
    final groups = state.groups.where((group) => group.id != groupId).toList();
    if (state.selectedGroupId == groupId) {
      state = state.copyWith(
        groups: groups,
        clearNode: true,
        clearSelection: true,
      );
    } else {
      state = state.copyWith(groups: groups);
    }
    if (removed != null) await _repository?.deleteGroup(removed);
    _autoUpdateTimers.remove(groupId)?.cancel();
  }

  void _replaceGroup(ProfileGroup replacement) {
    state = state.copyWith(
      groups: [
        for (final group in state.groups)
          if (group.id == replacement.id) replacement else group,
      ],
    );
  }

  Future<void> _saveGroup(String groupId) async {
    final group =
        state.groups.where((value) => value.id == groupId).firstOrNull;
    if (group != null) await _repository?.saveGroup(group);
  }

  Future<void> _restoreProfiles() async {
    try {
      final groups = await _repository!.loadGroups();
      final selection = await _repository.loadSelection();
      final corePreferences = await _repository.loadCorePreferences();
      final minimizeToTray = await _repository.loadMinimizeToTray();
      if (!mounted) return;
      if (state.groups.isNotEmpty) return;
      ProxyNode? selectedNode;
      if (selection.$1 != null && selection.$2 != null) {
        final group =
            groups.where((value) => value.id == selection.$1).firstOrNull;
        selectedNode = group?.profiles
            .where((value) => value.id == selection.$2)
            .firstOrNull
            ?.node;
      }
      state = state.copyWith(
        groups: groups,
        node: selectedNode,
        clearNode: selectedNode == null,
        selectedGroupId: selection.$1,
        selectedProfileId: selection.$2,
        clearSelection: selectedNode == null,
        corePreferences: corePreferences,
        minimizeToTray: minimizeToTray,
      );
      for (final group in groups) {
        _scheduleAutoUpdate(group);
      }
    } catch (error) {
      if (mounted) _addLog('Unable to restore saved profiles: $error');
    }
  }

  Future<void> _restoreDesktopSettings() async {
    final enabled = await _desktopSettings.isAutostartEnabled();
    if (mounted) state = state.copyWith(autostartEnabled: enabled);
  }

  Future<void> connect() async {
    final node = state.node;
    if (node == null) return;
    if (!Platform.isLinux) {
      state = state.copyWith(
        error: 'The Android VPN bridge is not available in this build yet.',
      );
      return;
    }
    try {
      state = state.copyWith(
        clearError: true,
        clearLatency: true,
        upload: 0,
        download: 0,
        trafficHistory: const [],
      );
      _addLog('Starting connection to ${node.name}');
      await _connection.connect(
        ConnectionSnapshot(
          node: node,
          platform: RoutingPlatform.linux,
          preferences: state.corePreferences,
        ),
      );
      _startMetrics();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted && state.coreState == ProxyCoreState.running) {
        await testConnection();
      }
    } catch (error) {
      _addLog('Connection failed: $error');
      state = state.copyWith(error: error.toString());
    }
  }

  Future<void> disconnect() async {
    _metricsTimer?.cancel();
    _metricsTimer = null;
    _addLog('Stopping connection');
    await _connection.disconnect();
  }

  Future<void> testConnection() async {
    if (state.coreState != ProxyCoreState.running || state.testing) return;
    state = state.copyWith(testing: true, clearError: true);
    try {
      final result = await _diagnostics.testConnection();
      if (!mounted) return;
      state = state.copyWith(latency: result.latency, testing: false);
      _addLog(
        'Connection test passed: HTTP ${result.statusCode}, '
        '${result.latency.inMilliseconds} ms',
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
          testing: false, error: 'Connection test failed: $error');
      _addLog('Connection test failed: $error');
    }
  }

  void clearLogs() => state = state.copyWith(logs: const []);

  void _startMetrics() {
    _metricsTimer?.cancel();
    _lastMetricsAt = DateTime.now();
    _metricsTimer =
        Timer.periodic(const Duration(milliseconds: 250), (_) async {
      if (_metricsReadInProgress) return;
      _metricsReadInProgress = true;
      try {
        final traffic = await _diagnostics.readTraffic();
        if (!mounted || state.coreState != ProxyCoreState.running) return;
        final now = DateTime.now();
        final elapsed =
            now.difference(_lastMetricsAt!).inMilliseconds.clamp(1, 5000);
        _lastMetricsAt = now;
        final uploadRate = traffic.upload >= state.upload
            ? ((traffic.upload - state.upload) * 1000 / elapsed).round()
            : 0;
        final downloadRate = traffic.download >= state.download
            ? ((traffic.download - state.download) * 1000 / elapsed).round()
            : 0;
        final history = [
          ...state.trafficHistory,
          TrafficSample(
            uploadPerSecond: uploadRate,
            downloadPerSecond: downloadRate,
          ),
        ];
        state = state.copyWith(
          upload: traffic.upload,
          download: traffic.download,
          trafficHistory: history.length > 120
              ? history.sublist(history.length - 120)
              : history,
        );
      } catch (_) {
        // The metrics API can take a moment to become available after startup.
      } finally {
        _metricsReadInProgress = false;
      }
    });
  }

  void _scheduleAutoUpdate(ProfileGroup group) {
    _autoUpdateTimers.remove(group.id)?.cancel();
    if (!group.isSubscription || !group.autoUpdateEnabled) return;
    _autoUpdateTimers[group.id] = Timer.periodic(
      Duration(minutes: group.autoUpdateMinutes),
      (_) => unawaited(refreshGroup(group.id)),
    );
  }

  void _addLog(String line) {
    final logs = [...state.logs, '${DateTime.now().toIso8601String()} $line'];
    state = state.copyWith(
      logs: logs.length > 500 ? logs.sublist(logs.length - 500) : logs,
    );
  }

  void _onCoreEvent(CoreEvent event) {
    switch (event) {
      case CoreStateChanged(state: final coreState):
        state = state.copyWith(coreState: coreState);
        if (coreState == ProxyCoreState.failed ||
            coreState == ProxyCoreState.stopped) {
          _metricsTimer?.cancel();
          _metricsTimer = null;
        }
      case CoreLogLine(:final line):
        final logs = [...state.logs, line];
        state = state.copyWith(
          logs: logs.length > 200 ? logs.sublist(logs.length - 200) : logs,
        );
      case CoreFailure(:final message):
        state = state.copyWith(error: message);
    }
  }

  @override
  void dispose() {
    _metricsTimer?.cancel();
    for (final timer in _autoUpdateTimers.values) {
      timer.cancel();
    }
    unawaited(_subscription.cancel());
    unawaited(_connection.dispose());
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
