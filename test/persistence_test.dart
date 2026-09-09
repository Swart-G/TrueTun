import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:truetun/src/persistence/app_database.dart';
import 'package:truetun/src/persistence/profile_repository.dart';
import 'package:truetun/src/persistence/routing_settings_repository.dart';
import 'package:truetun/src/profiles/hysteria2_profile_parser.dart';
import 'package:truetun/src/profiles/profile_group.dart';
import 'package:truetun/src/profiles/proxy_node.dart';
import 'package:truetun/src/profiles/vless_link_parser.dart';
import 'package:truetun/src/routing/routing_rule.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  test('profile groups and selected profile survive reload', () async {
    final repository = ProfileRepository(database: database);
    final node = const VlessLinkParser().parse(
      'vless://00000000-0000-4000-8000-000000000000@example.com:443'
      '?security=tls&type=ws#Saved',
    );
    final group = ProfileGroup(
      id: 'subscription-1',
      name: 'Saved group',
      subscriptionUrl: Uri.parse('https://example.com/private-subscription'),
      autoUpdateEnabled: true,
      autoUpdateMinutes: 30,
      profiles: [ManagedProfile(id: 'node-1', node: node)],
    );
    await repository.saveGroup(group);
    await repository.saveSelection(group.id, 'node-1');

    final restored = await repository.loadGroups();
    final selection = await repository.loadSelection();
    expect(restored, hasLength(1));
    expect(restored.single.profiles.single.node.name, 'Saved');
    expect(restored.single.subscriptionUrl, group.subscriptionUrl);
    expect(restored.single.autoUpdateEnabled, isTrue);
    expect(restored.single.autoUpdateMinutes, 30);
    expect(selection, (group.id, 'node-1'));
  });

  test('Hysteria2 profile survives secure persistence reload', () async {
    final repository = ProfileRepository(database: database);
    final node = const Hysteria2ProfileParser().parse(
      'hy2://password@hy.example.com:443/?sni=hy.example.com'
      '&obfs=salamander&obfs-password=mask#Saved%20HY2',
    );
    final group = ProfileGroup(
      id: 'hy2-group',
      name: 'HY2 group',
      profiles: [ManagedProfile(id: 'hy2-node', node: node)],
    );
    await repository.saveGroup(group);

    final restored = await repository.loadGroups();
    final restoredNode = restored.single.profiles.single.node;
    expect(restoredNode, isA<Hysteria2Node>());
    final hy2 = restoredNode as Hysteria2Node;
    expect(hy2.password, 'password');
    expect(hy2.obfs?.password, 'mask');
  });

  test('routing mode and fallback action survive reload', () async {
    final repository = RoutingSettingsRepository(database: database);
    const settings = RoutingSettings(
      enabled: true,
      fallbackAction: RouteActionType.direct,
    );

    await repository.saveRoutingSettings(settings);
    final restored = await repository.loadRoutingSettings();

    expect(restored.enabled, isTrue);
    expect(restored.fallbackAction, RouteActionType.direct);
  });

  tearDown(() => database.close());

  test('profiles are inserted, updated, and deleted transactionally', () async {
    final now = DateTime.utc(2026);
    await database.saveProfile(
      ProfilesCompanion.insert(
        id: 'profile-1',
        name: 'First name',
        protocol: 'vless',
        payload: '{}',
        secretKey: 'profile.profile-1.uuid',
        updatedAt: now,
      ),
    );
    await database.saveProfile(
      ProfilesCompanion.insert(
        id: 'profile-1',
        name: 'Updated name',
        protocol: 'vless',
        payload: '{}',
        secretKey: 'profile.profile-1.uuid',
        updatedAt: now,
      ),
    );

    final profiles = await database.allProfiles();
    expect(profiles, hasLength(1));
    expect(profiles.single.name, 'Updated name');

    await database.deleteProfile('profile-1');
    expect(await database.allProfiles(), isEmpty);
  });
}
