import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:truetun/src/core/connection_snapshot.dart';
import 'package:truetun/src/core/core_adapter.dart';
import 'package:truetun/src/core/core_preferences.dart';
import 'package:truetun/src/core/log_redactor.dart';
import 'package:truetun/src/core/process_sing_box_adapter.dart';
import 'package:truetun/src/core/sing_box_config_compiler.dart';
import 'package:truetun/src/profiles/profile_group.dart';
import 'package:truetun/src/profiles/proxy_node.dart';
import 'package:truetun/src/profiles/vless_link_parser.dart';
import 'package:truetun/src/routing/routing_rule.dart';

final appControllerProvider = StateNotifierProvider<AppController, AppState>(
  (ref) => AppController(),
);

class TrafficSample {
  const TrafficSample({
    required this.timestamp,
    required this.downloadPerSecond,
    required this.uploadPerSecond,
  });

  final DateTime timestamp;
  final int downloadPerSecond;
  final int uploadPerSecond;
}

class AppState {
  const AppState({
    this.coreState = ProxyCoreState.stopped,
    this.groups = const [],
    this.selectedGroupId,
    this.selectedProfileId,
    this.error,
    this.logs = const [],
    this.testing = false,
    this.latency,
    this.profilePings = const {},
    this.pingingProfiles = const {},
    this.upload = 0,
    this.download = 0,
    this.trafficHistory = const [],
    this.corePreferences = const CorePreferences(),
    this.autostartEnabled = false,
    this.minimizeToTray = true,
  });

  final ProxyCoreState coreState;
  final List<ProfileGroup> groups;
  final String? selectedGroupId;
  final String? selectedProfileId;
  final String? error;
  final List<String> logs;
  final bool testing;
  final Duration? latency;
  final Map<String, int> profilePings;
  final Set<String> pingingProfiles;
  final int upload;
  final int download;
  final List<TrafficSample> trafficHistory;
  final CorePreferences corePreferences;
  final bool autostartEnabled;
  final bool minimizeToTray;

  VlessNode? get node {
    final profileId = selectedProfileId;
    if (profileId == null) return null;
    for (final group in groups) {
      for (final profile in group.profiles) {
        if (profile.id == profileId) return profile.node;
      }
    }
    return null;
  }

  AppState copyWith({
    ProxyCoreState? coreState,
    List<ProfileGroup>? groups,
    Object? selectedGroupId = _unset,
    Object? selectedProfileId = _unset,
    Object? error = _unset,
    List<String>? logs,
    bool? testing,
    Object? latency = _unset,
    Map<String, int>? profilePings,
    Set<String>? pingingProfiles,
    int? upload,
    int? download,
    List<TrafficSample>? trafficHistory,
    CorePreferences? corePreferences,
    bool? autostartEnabled,
    bool? minimizeToTray,
  }) {
    return AppState(
      coreState: coreState ?? this.coreState,
      groups: groups ?? this.groups,
      selectedGroupId: identical(selectedGroupId, _unset)
          ? this.selectedGroupId
          : selectedGroupId as String?,
      selectedProfileId: identical(selectedProfileId, _unset)
          ? this.selectedProfileId
          : selectedProfileId as String?,
      error: identical(error, _unset) ? this.error : error as String?,
      logs: logs ?? this.logs,
      testing: testing ?? this.testing,
      latency: identical(latency, _unset) ? this.latency : latency as Duration?,
      profilePings: profilePings ?? this.profilePings,
      pingingProfiles: pingingProfiles ?? this.pingingProfiles,
      upload: upload ?? this.upload,
      download: download ?? this.download,
      trafficHistory: trafficHistory ?? this.trafficHistory,
      corePreferences: corePreferences ?? this.corePreferences,
      autostartEnabled: autostartEnabled ?? this.autostartEnabled,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
    );
  }

  static const Object _unset = Object();
}

class AppController extends StateNotifier<AppState> {
  AppController({ProxyCoreAdapter? core})
      : _core = core ?? ProcessSingBoxAdapter(),
        super(
          const AppState(
            groups: [ProfileGroup(id: 'manual', name: 'Manual')],
          ),
        ) {
    _coreEvents = _core.events.listen(_onCoreEvent);
  }

  final ProxyCoreAdapter _core;
  final _parser = const VlessLinkParser();
  final _configCompiler = const SingBoxConfigCompiler();
  final _redactor = const LogRedactor();
  StreamSubscription<CoreEvent>? _coreEvents;
  int _nextId = 0;

  Future<void> connect() async {
    final node = state.node;
    if (node == null || state.coreState == ProxyCoreState.starting) return;

    state = state.copyWith(
      coreState: ProxyCoreState.starting,
      error: null,
      latency: null,
    );
    try {
      final snapshot = ConnectionSnapshot(
        node: node,
        platform: _platform,
        preferences: state.corePreferences,
      );
      final config = _configCompiler.compile(snapshot);
      await _core.start(config);
      if (state.coreState != ProxyCoreState.running) {
        state = state.copyWith(coreState: ProxyCoreState.running);
      }
      unawaited(testConnection());
    } catch (error) {
      final message = _redactor.redact(error.toString());
      _appendLog('Connection failed: $message');
      state = state.copyWith(
        coreState: ProxyCoreState.failed,
        error: message,
      );
    }
  }

  Future<void> disconnect() async {
    if (state.coreState == ProxyCoreState.stopped ||
        state.coreState == ProxyCoreState.stopping) {
      return;
    }
    state = state.copyWith(coreState: ProxyCoreState.stopping, error: null);
    try {
      await _core.stop();
      state = state.copyWith(
        coreState: ProxyCoreState.stopped,
        latency: null,
      );
    } catch (error) {
      final message = _redactor.redact(error.toString());
      state = state.copyWith(
        coreState: ProxyCoreState.failed,
        error: message,
      );
    }
  }

  Future<void> testConnection() async {
    if (state.coreState != ProxyCoreState.running || state.testing) return;
    state = state.copyWith(testing: true, error: null);
    final stopwatch = Stopwatch()..start();
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client
          .getUrl(Uri.parse('https://www.cloudflare.com/cdn-cgi/trace'))
          .timeout(const Duration(seconds: 10));
      request.headers.set(HttpHeaders.userAgentHeader, 'TrueTun/0.1');
      final response = await request.close().timeout(const Duration(seconds: 10));
      await response.drain<void>();
      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      stopwatch.stop();
      state = state.copyWith(
        testing: false,
        latency: stopwatch.elapsed,
        error: null,
      );
      _appendLog('Connection test: ${stopwatch.elapsedMilliseconds} ms');
    } catch (error) {
      stopwatch.stop();
      final message = _redactor.redact(error.toString());
      state = state.copyWith(testing: false, latency: null, error: message);
      _appendLog('Connection test failed: $message');
    } finally {
      client.close(force: true);
    }
  }

  void createGroup(String rawName) {
    final name = rawName.trim();
    if (name.isEmpty) return;
    final group = ProfileGroup(id: _id('group'), name: name);
    state = state.copyWith(groups: [...state.groups, group]);
  }

  void importVless(String rawLink, {String targetGroupId = 'manual'}) {
    try {
      final node = _parser.parse(rawLink);
      final profile = ManagedProfile(id: _id('profile'), node: node);
      var targetFound = false;
      final groups = state.groups.map((group) {
        if (group.id != targetGroupId) return group;
        targetFound = true;
        return group.copyWith(profiles: [...group.profiles, profile]);
      }).toList(growable: false);
      final updatedGroups = targetFound
          ? groups
          : [
              ...groups,
              ProfileGroup(
                id: targetGroupId,
                name: 'Manual',
                profiles: [profile],
              ),
            ];
      state = state.copyWith(
        groups: updatedGroups,
        selectedGroupId: targetGroupId,
        selectedProfileId: profile.id,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(error: _redactor.redact(error.toString()));
    }
  }

  Future<void> addSubscription(String rawName, String rawUrl) async {
    final name = rawName.trim();
    final uri = Uri.tryParse(rawUrl.trim());
    if (name.isEmpty ||
        uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      state = state.copyWith(error: 'Invalid subscription name or URL');
      return;
    }
    final group = ProfileGroup(
      id: _id('subscription'),
      name: name,
      subscriptionUrl: uri,
    );
    state = state.copyWith(groups: [...state.groups, group], error: null);
    await refreshGroup(group.id);
  }

  Future<void> refreshGroup(String groupId) async {
    final group = _groupById(groupId);
    final url = group?.subscriptionUrl;
    if (group == null || url == null || group.updating) return;

    _replaceGroup(group.copyWith(updating: true, clearError: true));
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request =
          await client.getUrl(url).timeout(const Duration(seconds: 12));
      request.headers.set(HttpHeaders.userAgentHeader, 'TrueTun/0.1');
      final response = await request.close().timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Subscription returned HTTP ${response.statusCode}');
      }
      final body = await response.transform(utf8.decoder).join();
      final links = _extractVlessLinks(body);
      if (links.isEmpty) {
        throw const FormatException('Subscription contains no VLESS links');
      }
      final profiles = <ManagedProfile>[];
      for (final link in links) {
        try {
          profiles.add(
            ManagedProfile(id: _id('profile'), node: _parser.parse(link)),
          );
        } on Object catch (error) {
          _appendLog(
            'Skipped subscription entry: ${_redactor.redact(error.toString())}',
          );
        }
      }
      if (profiles.isEmpty) {
        throw const FormatException('No valid VLESS profiles in subscription');
      }

      _replaceGroup(
        group.copyWith(
          profiles: profiles,
          updating: false,
          clearError: true,
        ),
      );
      if (state.selectedProfileId == null ||
          groupId == state.selectedGroupId &&
              !profiles.any((item) => item.id == state.selectedProfileId)) {
        state = state.copyWith(
          selectedGroupId: groupId,
          selectedProfileId: profiles.first.id,
        );
      }
    } catch (error) {
      final message = _redactor.redact(error.toString());
      _replaceGroup(group.copyWith(updating: false, error: message));
      state = state.copyWith(error: message);
    } finally {
      client.close(force: true);
    }
  }

  Future<void> updateGroup({
    required String groupId,
    required String name,
    required Uri? subscriptionUrl,
    required bool autoUpdateEnabled,
    required int autoUpdateMinutes,
  }) async {
    final group = _groupById(groupId);
    if (group == null) return;
    _replaceGroup(
      ProfileGroup(
        id: group.id,
        name: name.trim(),
        subscriptionUrl: subscriptionUrl,
        autoUpdateEnabled: autoUpdateEnabled,
        autoUpdateMinutes: autoUpdateMinutes,
        profiles: group.profiles,
        updating: group.updating,
        error: group.error,
      ),
    );
  }

  Future<void> updateProfile({
    required String groupId,
    required String profileId,
    required VlessNode node,
  }) async {
    final group = _groupById(groupId);
    if (group == null) return;
    final profiles = group.profiles
        .map(
          (profile) => profile.id == profileId
              ? profile.copyWith(node: node)
              : profile,
        )
        .toList(growable: false);
    _replaceGroup(group.copyWith(profiles: profiles));
  }

  void selectProfile(String groupId, String profileId) {
    final group = _groupById(groupId);
    if (group == null || !group.profiles.any((item) => item.id == profileId)) {
      return;
    }
    state = state.copyWith(
      selectedGroupId: groupId,
      selectedProfileId: profileId,
      error: null,
    );
  }

  void deleteGroup(String groupId) {
    final groups = state.groups.where((group) => group.id != groupId).toList();
    var selectedGroupId = state.selectedGroupId;
    var selectedProfileId = state.selectedProfileId;
    if (selectedGroupId == groupId) {
      selectedGroupId = null;
      selectedProfileId = null;
      for (final group in groups) {
        if (group.profiles.isNotEmpty) {
          selectedGroupId = group.id;
          selectedProfileId = group.profiles.first.id;
          break;
        }
      }
    }
    state = state.copyWith(
      groups: groups,
      selectedGroupId: selectedGroupId,
      selectedProfileId: selectedProfileId,
    );
  }

  Future<void> testGroup(String groupId) async {
    final group = _groupById(groupId);
    if (group == null) return;
    for (final profile in group.profiles) {
      await testProfile(profile.id);
    }
  }

  Future<void> testProfile(String profileId) async {
    final profile = _profileById(profileId);
    if (profile == null || state.pingingProfiles.contains(profileId)) return;
    state = state.copyWith(
      pingingProfiles: {...state.pingingProfiles, profileId},
    );
    final stopwatch = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(
        profile.node.server,
        profile.node.port,
        timeout: const Duration(seconds: 5),
      );
      stopwatch.stop();
      state = state.copyWith(
        profilePings: {
          ...state.profilePings,
          profileId: stopwatch.elapsedMilliseconds,
        },
      );
    } catch (_) {
      state = state.copyWith(
        profilePings: {...state.profilePings, profileId: -1},
      );
    } finally {
      socket?.destroy();
      final pinging = {...state.pingingProfiles}..remove(profileId);
      state = state.copyWith(pingingProfiles: pinging);
    }
  }

  Future<void> updateCorePreferences(CorePreferences preferences) async {
    state = state.copyWith(corePreferences: preferences, error: null);
  }

  Future<void> setAutostart(bool enabled) async {
    if (!Platform.isLinux) {
      state = state.copyWith(autostartEnabled: enabled);
      return;
    }

    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      state = state.copyWith(error: 'HOME is not set; cannot configure autostart');
      return;
    }
    final file = File('$home/.config/autostart/truetun.desktop');
    try {
      if (enabled) {
        await file.parent.create(recursive: true);
        final executable = Platform.resolvedExecutable.replaceAll('"', r'\"');
        await file.writeAsString(
          '[Desktop Entry]\n'
          'Type=Application\n'
          'Name=TrueTun\n'
          'Exec="$executable" --hidden\n'
          'Terminal=false\n'
          'X-GNOME-Autostart-enabled=true\n',
        );
      } else if (await file.exists()) {
        await file.delete();
      }
      state = state.copyWith(autostartEnabled: enabled, error: null);
    } catch (error) {
      state = state.copyWith(error: _redactor.redact(error.toString()));
    }
  }

  void setMinimizeToTray(bool enabled) {
    state = state.copyWith(minimizeToTray: enabled);
  }

  void clearLogs() => state = state.copyWith(logs: const []);

  void _onCoreEvent(CoreEvent event) {
    switch (event) {
      case CoreStateChanged(:final state):
        this.state = this.state.copyWith(coreState: state);
      case CoreLogLine(:final line, :final isError):
        _appendLog('${isError ? 'ERR' : 'CORE'} ${_redactor.redact(line)}');
      case CoreFailure(:final message):
        final safe = _redactor.redact(message);
        _appendLog('Core failure: $safe');
        state = state.copyWith(coreState: ProxyCoreState.failed, error: safe);
    }
  }

  void _appendLog(String line) {
    final logs = [...state.logs, line];
    if (logs.length > 1000) logs.removeRange(0, logs.length - 1000);
    state = state.copyWith(logs: logs);
  }

  void _replaceGroup(ProfileGroup replacement) {
    state = state.copyWith(
      groups: state.groups
          .map((group) => group.id == replacement.id ? replacement : group)
          .toList(growable: false),
    );
  }

  ProfileGroup? _groupById(String id) {
    for (final group in state.groups) {
      if (group.id == id) return group;
    }
    return null;
  }

  ManagedProfile? _profileById(String id) {
    for (final group in state.groups) {
      for (final profile in group.profiles) {
        if (profile.id == id) return profile;
      }
    }
    return null;
  }

  List<String> _extractVlessLinks(String body) {
    Iterable<String> linesFrom(String value) => const LineSplitter()
        .convert(value)
        .map((line) => line.trim())
        .where((line) => line.startsWith('vless://'));

    final direct = linesFrom(body).toList(growable: false);
    if (direct.isNotEmpty) return direct;

    final compact = body.replaceAll(RegExp(r'\s+'), '');
    for (final codec in <Base64Codec>[base64, base64Url]) {
      try {
        final normalized = base64.normalize(compact);
        final decoded = utf8.decode(codec.decode(normalized));
        final links = linesFrom(decoded).toList(growable: false);
        if (links.isNotEmpty) return links;
      } on Object {
        // Try the next supported subscription encoding.
      }
    }
    return const [];
  }

  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_nextId++}';

  RoutingPlatform get _platform {
    if (Platform.isAndroid) return RoutingPlatform.android;
    if (Platform.isLinux) return RoutingPlatform.linux;
    return RoutingPlatform.other;
  }

  @override
  void dispose() {
    _coreEvents?.cancel();
    _coreEvents = null;
    super.dispose();
  }
}
