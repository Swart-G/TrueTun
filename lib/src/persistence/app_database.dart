import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get protocol => text()();
  TextColumn get payload => text()();
  TextColumn get secretKey => text()();
  TextColumn get groupId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('StoredProfileGroup')
class ProfileGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get subscriptionSecretKey => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get autoUpdateEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get autoUpdateMinutes =>
      integer().withDefault(const Constant(60))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class RoutingPolicies extends Table {
  TextColumn get id => text()();
  TextColumn get payload => text()();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [Profiles, ProfileGroups, RoutingPolicies, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) => migrator.createAll(),
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.createTable(profileGroups);
            await migrator.addColumn(profiles, profiles.groupId);
          }
          if (from < 3) {
            await migrator.addColumn(
              profileGroups,
              profileGroups.autoUpdateEnabled,
            );
            await migrator.addColumn(
              profileGroups,
              profileGroups.autoUpdateMinutes,
            );
          }
        },
      );

  Future<List<Profile>> allProfiles() => select(profiles).get();

  Stream<List<Profile>> watchProfiles() => select(profiles).watch();

  Future<List<StoredProfileGroup>> allGroups() => select(profileGroups).get();

  Future<void> saveGroup(ProfileGroupsCompanion group) =>
      into(profileGroups).insertOnConflictUpdate(group);

  Future<void> saveProfile(ProfilesCompanion profile) =>
      into(profiles).insertOnConflictUpdate(profile);

  Future<void> deleteProfile(String id) async {
    await (delete(profiles)..where((row) => row.id.equals(id))).go();
  }

  Future<void> deleteGroup(String id) async {
    await transaction(() async {
      await (delete(profiles)..where((row) => row.groupId.equals(id))).go();
      await (delete(profileGroups)..where((row) => row.id.equals(id))).go();
    });
  }

  Future<void> saveSetting(String key, String value) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion.insert(key: key, value: value),
      );

  Future<String?> readSetting(String key) async {
    final row = await (select(settings)..where((item) => item.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'truetun'));
    await directory.create(recursive: true);
    return NativeDatabase.createInBackground(
      File(p.join(directory.path, 'truetun.sqlite')),
    );
  });
}
