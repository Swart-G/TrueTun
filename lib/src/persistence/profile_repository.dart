import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:truetun/src/persistence/app_database.dart';
import 'package:truetun/src/core/core_preferences.dart';
import 'package:truetun/src/profiles/proxy_node.dart';
import 'package:truetun/src/profiles/profile_group.dart';
import 'package:truetun/src/profiles/vless_link_parser.dart';

class ProfileRepository {
  ProfileRepository({
    required this.database,
    FlutterSecureStorage? secureStorage,
  }) : secureStorage = secureStorage ?? const FlutterSecureStorage();

  final AppDatabase database;
  final FlutterSecureStorage secureStorage;

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
      'tls': {
        'enabled': node.tls.enabled,
        'serverName': node.tls.serverName,
        'alpn': node.tls.alpn,
        'insecure': node.tls.insecure,
        'fingerprint': node.tls.fingerprint,
        'realityPublicKey': node.tls.reality?.publicKey,
        'realityShortId': node.tls.reality?.shortId,
      },
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
        await saveVless(
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
            ManagedProfile(id: profile.id, node: await loadVless(profile)),
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
      await secureStorage.delete(key: 'profile.${profile.id}.uuid');
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
}
