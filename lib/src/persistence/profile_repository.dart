import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:truetun/src/core/core_preferences.dart';
import 'package:truetun/src/persistence/app_database.dart';
import 'package:truetun/src/profiles/profile_group.dart';
import 'package:truetun/src/profiles/proxy_node.dart';
import 'package:truetun/src/profiles/vless_link_parser.dart';

class ProfileRepository {
  ProfileRepository({
    required this.database,
    FlutterSecureStorage? secureStorage,
  }) : secureStorage = secureStorage ?? const FlutterSecureStorage();

  final AppDatabase database;
  final FlutterSecureStorage secureStorage;

  Future<void> saveProfileNode({
    required String id,
    required String groupId,
    required ProxyNode node,
  }) async {
    switch (node) {
      case VlessNode():
        await saveVless(id: id, groupId: groupId, node: node);
      case Hysteria2Node():
        await saveHysteria2(id: id, groupId: groupId, node: node);
    }
  }

  Future<void> saveVless({
    required String id,
    required String groupId,
    required VlessNode node,
  }) async {
    final secretKey = 'profile.$id.uuid';
    await secureStorage.write(key: secretKey, value: node.uuid);
    final payload = jsonEncode({
      'server': node.server,
      'port': node.port,
      'flow': node.flow,
      'packetEncoding': node.packetEncoding,
      'tls': _tlsToJson(node.tls),
      'transport': {
        'type': node.transport.type.name,
        'host': node.transport.host,
        'path': node.transport.path,
        'serviceName': node.transport.serviceName,
        'mode': node.transport.mode,
      },
      'extensions': node.extensions,
    });
    await database.saveProfile(
      ProfilesCompanion.insert(
        id: id,
        name: node.name,
        protocol: ProxyProtocol.vless.name,
        payload: payload,
        secretKey: secretKey,
        updatedAt: DateTime.now(),
        groupId: Value(groupId),
      ),
    );
  }

  Future<void> saveHysteria2({
    required String id,
    required String groupId,
    required Hysteria2Node node,
  }) async {
    final secretKey = 'profile.$id.hysteria2';
    await secureStorage.write(
      key: secretKey,
      value: jsonEncode({
        'password': node.password,
        'obfsPassword': node.obfs?.password,
      }),
    );
    final payload = jsonEncode({
      'server': node.server,
      'port': node.port,
      'serverPorts': node.serverPorts,
      'hopInterval': node.hopInterval,
      'hopIntervalMax': node.hopIntervalMax,
      'upMbps': node.upMbps,
      'downMbps': node.downMbps,
      'tls': _tlsToJson(node.tls),
      'obfs': node.obfs == null
          ? null
          : {
              'type': node.obfs!.type,
              'minPacketSize': node.obfs!.minPacketSize,
              'maxPacketSize': node.obfs!.maxPacketSize,
            },
      'extensions': node.extensions,
    });
    await database.saveProfile(
      ProfilesCompanion.insert(
        id: id,
        name: node.name,
        protocol: ProxyProtocol.hysteria2.name,
        payload: payload,
        secretKey: secretKey,
        updatedAt: DateTime.now(),
        groupId: Value(groupId),
      ),
    );
  }

  Future<void> saveGroup(ProfileGroup group) async {
    final subscriptionKey = group.subscriptionUrl == null
        ? null
        : 'group.${group.id}.subscription-url';
    if (subscriptionKey != null) {
      await secureStorage.write(
        key: subscriptionKey,
        value: group.subscriptionUrl.toString(),
      );
    } else {
      await secureStorage.delete(key: 'group.${group.id}.subscription-url');
    }
    await database.transaction(() async {
      await database.saveGroup(
        ProfileGroupsCompanion.insert(
          id: group.id,
          name: group.name,
          subscriptionSecretKey: Value(subscriptionKey),
          updatedAt: Value(group.updatedAt),
          autoUpdateEnabled: Value(group.autoUpdateEnabled),
          autoUpdateMinutes: Value(group.autoUpdateMinutes),
        ),
      );
      await (database.delete(database.profiles)
            ..where((row) => row.groupId.equals(group.id)))
          .go();
      for (final profile in group.profiles) {
        await saveProfileNode(
          id: profile.id,
          groupId: group.id,
          node: profile.node,
        );
      }
    });
  }

  Future<List<ProfileGroup>> loadGroups() async {
    final storedGroups = await database.allGroups();
    final storedProfiles = await database.allProfiles();
    final result = <ProfileGroup>[];
    for (final group in storedGroups) {
      Uri? subscriptionUrl;
      if (group.subscriptionSecretKey case final key?) {
        final value = await secureStorage.read(key: key);
        subscriptionUrl = value == null ? null : Uri.tryParse(value);
      }
      final profiles = <ManagedProfile>[];
      for (final profile
          in storedProfiles.where((row) => row.groupId == group.id)) {
        try {
          profiles.add(
            ManagedProfile(id: profile.id, node: await loadProfile(profile)),
          );
        } on ProfileParseException {
          // Keep loading the rest when one secure-storage entry is missing.
        }
      }
      result.add(
        ProfileGroup(
          id: group.id,
          name: group.name,
          subscriptionUrl: subscriptionUrl,
          profiles: profiles,
          updatedAt: group.updatedAt,
          autoUpdateEnabled: group.autoUpdateEnabled,
          autoUpdateMinutes: group.autoUpdateMinutes,
        ),
      );
    }
    return result;
  }

  Future<void> deleteGroup(ProfileGroup group) async {
    for (final profile in group.profiles) {
      await secureStorage.delete(key: _secretKey(profile.id, profile.node));
    }
    final subscriptionKey = group.subscriptionUrl == null
        ? null
        : 'group.${group.id}.subscription-url';
    if (subscriptionKey != null) {
      await secureStorage.delete(key: subscriptionKey);
    }
    await database.deleteGroup(group.id);
  }

  Future<void> saveSelection(String groupId, String profileId) async {
    await database.saveSetting('selected_group_id', groupId);
    await database.saveSetting('selected_profile_id', profileId);
  }

  Future<(String?, String?)> loadSelection() async {
    return (
      await database.readSetting('selected_group_id'),
      await database.readSetting('selected_profile_id'),
    );
  }

  Future<void> saveCorePreferences(CorePreferences preferences) => database
      .saveSetting('core_preferences', jsonEncode(preferences.toJson()));

  Future<CorePreferences> loadCorePreferences() async {
    final value = await database.readSetting('core_preferences');
    if (value == null) return const CorePreferences();
    return CorePreferences.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  Future<void> saveMinimizeToTray(bool value) =>
      database.saveSetting('minimize_to_tray', value.toString());

  Future<bool> loadMinimizeToTray() async =>
      await database.readSetting('minimize_to_tray') != 'false';

  Future<ProxyNode> loadProfile(Profile profile) {
    return switch (profile.protocol) {
      'vless' => loadVless(profile),
      'hysteria2' => loadHysteria2(profile),
      _ => throw ProfileParseException(
          'Unsupported stored protocol: ${profile.protocol}',
        ),
    };
  }

  Future<VlessNode> loadVless(Profile profile) async {
    final uuid = await secureStorage.read(key: profile.secretKey);
    if (uuid == null) {
      throw const ProfileParseException('Profile credentials are unavailable');
    }
    final payload = jsonDecode(profile.payload) as Map<String, dynamic>;
    final tls = payload['tls'] as Map<String, dynamic>;
    final transport = payload['transport'] as Map<String, dynamic>;
    final publicKey = tls['realityPublicKey'] as String?;
    return VlessNode(
      name: profile.name,
      server: payload['server'] as String,
      port: payload['port'] as int,
      uuid: uuid,
      flow: payload['flow'] as String?,
      packetEncoding: payload['packetEncoding'] as String?,
      tls: TlsOptions(
        enabled: tls['enabled'] as bool,
        serverName: tls['serverName'] as String?,
        alpn: (tls['alpn'] as List<dynamic>).cast<String>(),
        insecure: tls['insecure'] as bool,
        fingerprint: tls['fingerprint'] as String?,
        reality: publicKey == null
            ? null
            : RealityOptions(
                publicKey: publicKey,
                shortId: tls['realityShortId'] as String? ?? '',
              ),
      ),
      transport: V2RayTransportOptions(
        type: V2RayTransportType.values.byName(transport['type'] as String),
        host: transport['host'] as String?,
        path: transport['path'] as String?,
        serviceName: transport['serviceName'] as String?,
        mode: transport['mode'] as String?,
      ),
      extensions: Map<String, String>.from(
        payload['extensions'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Future<Hysteria2Node> loadHysteria2(Profile profile) async {
    final rawSecret = await secureStorage.read(key: profile.secretKey);
    if (rawSecret == null) {
      throw const ProfileParseException('Profile credentials are unavailable');
    }
    final secret = jsonDecode(rawSecret) as Map<String, dynamic>;
    final password = secret['password'] as String?;
    if (password == null || password.isEmpty) {
      throw const ProfileParseException('Hysteria2 password is unavailable');
    }

    final payload = jsonDecode(profile.payload) as Map<String, dynamic>;
    final tls = payload['tls'] as Map<String, dynamic>;
    final rawObfs = payload['obfs'];
    Hysteria2ObfsOptions? obfs;
    if (rawObfs is Map<String, dynamic>) {
      final obfsPassword = secret['obfsPassword'] as String?;
      if (obfsPassword == null || obfsPassword.isEmpty) {
        throw const ProfileParseException(
          'Hysteria2 obfs password is unavailable',
        );
      }
      obfs = Hysteria2ObfsOptions(
        type: rawObfs['type'] as String,
        password: obfsPassword,
        minPacketSize: rawObfs['minPacketSize'] as int?,
        maxPacketSize: rawObfs['maxPacketSize'] as int?,
      );
    }

    return Hysteria2Node(
      name: profile.name,
      server: payload['server'] as String,
      port: payload['port'] as int,
      serverPorts:
          (payload['serverPorts'] as List<dynamic>? ?? const []).cast<String>(),
      password: password,
      tls: TlsOptions(
        enabled: tls['enabled'] as bool,
        serverName: tls['serverName'] as String?,
        alpn: (tls['alpn'] as List<dynamic>).cast<String>(),
        insecure: tls['insecure'] as bool,
      ),
      hopInterval: payload['hopInterval'] as String?,
      hopIntervalMax: payload['hopIntervalMax'] as String?,
      upMbps: payload['upMbps'] as int?,
      downMbps: payload['downMbps'] as int?,
      obfs: obfs,
      extensions: Map<String, String>.from(
        payload['extensions'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Map<String, Object?> _tlsToJson(TlsOptions tls) => {
        'enabled': tls.enabled,
        'serverName': tls.serverName,
        'alpn': tls.alpn,
        'insecure': tls.insecure,
        'fingerprint': tls.fingerprint,
        'realityPublicKey': tls.reality?.publicKey,
        'realityShortId': tls.reality?.shortId,
      };

  String _secretKey(String id, ProxyNode node) {
    return switch (node) {
      VlessNode() => 'profile.$id.uuid',
      Hysteria2Node() => 'profile.$id.hysteria2',
    };
  }
}
