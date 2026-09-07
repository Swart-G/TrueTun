// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _protocolMeta =
      const VerificationMeta('protocol');
  @override
  late final GeneratedColumn<String> protocol = GeneratedColumn<String>(
      'protocol', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _secretKeyMeta =
      const VerificationMeta('secretKey');
  @override
  late final GeneratedColumn<String> secretKey = GeneratedColumn<String>(
      'secret_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, protocol, payload, secretKey, groupId, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(Insertable<Profile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('protocol')) {
      context.handle(_protocolMeta,
          protocol.isAcceptableOrUnknown(data['protocol']!, _protocolMeta));
    } else if (isInserting) {
      context.missing(_protocolMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('secret_key')) {
      context.handle(_secretKeyMeta,
          secretKey.isAcceptableOrUnknown(data['secret_key']!, _secretKeyMeta));
    } else if (isInserting) {
      context.missing(_secretKeyMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      protocol: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}protocol'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      secretKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}secret_key'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final String id;
  final String name;
  final String protocol;
  final String payload;
  final String secretKey;
  final String? groupId;
  final DateTime updatedAt;
  const Profile(
      {required this.id,
      required this.name,
      required this.protocol,
      required this.payload,
      required this.secretKey,
      this.groupId,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['protocol'] = Variable<String>(protocol);
    map['payload'] = Variable<String>(payload);
    map['secret_key'] = Variable<String>(secretKey);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      protocol: Value(protocol),
      payload: Value(payload),
      secretKey: Value(secretKey),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      updatedAt: Value(updatedAt),
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      protocol: serializer.fromJson<String>(json['protocol']),
      payload: serializer.fromJson<String>(json['payload']),
      secretKey: serializer.fromJson<String>(json['secretKey']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'protocol': serializer.toJson<String>(protocol),
      'payload': serializer.toJson<String>(payload),
      'secretKey': serializer.toJson<String>(secretKey),
      'groupId': serializer.toJson<String?>(groupId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Profile copyWith(
          {String? id,
          String? name,
          String? protocol,
          String? payload,
          String? secretKey,
          Value<String?> groupId = const Value.absent(),
          DateTime? updatedAt}) =>
      Profile(
        id: id ?? this.id,
        name: name ?? this.name,
        protocol: protocol ?? this.protocol,
        payload: payload ?? this.payload,
        secretKey: secretKey ?? this.secretKey,
        groupId: groupId.present ? groupId.value : this.groupId,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      protocol: data.protocol.present ? data.protocol.value : this.protocol,
      payload: data.payload.present ? data.payload.value : this.payload,
      secretKey: data.secretKey.present ? data.secretKey.value : this.secretKey,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('protocol: $protocol, ')
          ..write('payload: $payload, ')
          ..write('secretKey: $secretKey, ')
          ..write('groupId: $groupId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, protocol, payload, secretKey, groupId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.protocol == this.protocol &&
          other.payload == this.payload &&
          other.secretKey == this.secretKey &&
          other.groupId == this.groupId &&
          other.updatedAt == this.updatedAt);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> protocol;
  final Value<String> payload;
  final Value<String> secretKey;
  final Value<String?> groupId;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.protocol = const Value.absent(),
    this.payload = const Value.absent(),
    this.secretKey = const Value.absent(),
    this.groupId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    required String name,
    required String protocol,
    required String payload,
    required String secretKey,
    this.groupId = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        protocol = Value(protocol),
        payload = Value(payload),
        secretKey = Value(secretKey),
        updatedAt = Value(updatedAt);
  static Insertable<Profile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? protocol,
    Expression<String>? payload,
    Expression<String>? secretKey,
    Expression<String>? groupId,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (protocol != null) 'protocol': protocol,
      if (payload != null) 'payload': payload,
      if (secretKey != null) 'secret_key': secretKey,
      if (groupId != null) 'group_id': groupId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? protocol,
      Value<String>? payload,
      Value<String>? secretKey,
      Value<String?>? groupId,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      protocol: protocol ?? this.protocol,
      payload: payload ?? this.payload,
      secretKey: secretKey ?? this.secretKey,
      groupId: groupId ?? this.groupId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (protocol.present) {
      map['protocol'] = Variable<String>(protocol.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (secretKey.present) {
      map['secret_key'] = Variable<String>(secretKey.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('protocol: $protocol, ')
          ..write('payload: $payload, ')
          ..write('secretKey: $secretKey, ')
          ..write('groupId: $groupId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfileGroupsTable extends ProfileGroups
    with TableInfo<$ProfileGroupsTable, StoredProfileGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subscriptionSecretKeyMeta =
      const VerificationMeta('subscriptionSecretKey');
  @override
  late final GeneratedColumn<String> subscriptionSecretKey =
      GeneratedColumn<String>('subscription_secret_key', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _autoUpdateEnabledMeta =
      const VerificationMeta('autoUpdateEnabled');
  @override
  late final GeneratedColumn<bool> autoUpdateEnabled = GeneratedColumn<bool>(
      'auto_update_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("auto_update_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _autoUpdateMinutesMeta =
      const VerificationMeta('autoUpdateMinutes');
  @override
  late final GeneratedColumn<int> autoUpdateMinutes = GeneratedColumn<int>(
      'auto_update_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(60));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        subscriptionSecretKey,
        updatedAt,
        autoUpdateEnabled,
        autoUpdateMinutes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_groups';
  @override
  VerificationContext validateIntegrity(Insertable<StoredProfileGroup> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('subscription_secret_key')) {
      context.handle(
          _subscriptionSecretKeyMeta,
          subscriptionSecretKey.isAcceptableOrUnknown(
              data['subscription_secret_key']!, _subscriptionSecretKeyMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('auto_update_enabled')) {
      context.handle(
          _autoUpdateEnabledMeta,
          autoUpdateEnabled.isAcceptableOrUnknown(
              data['auto_update_enabled']!, _autoUpdateEnabledMeta));
    }
    if (data.containsKey('auto_update_minutes')) {
      context.handle(
          _autoUpdateMinutesMeta,
          autoUpdateMinutes.isAcceptableOrUnknown(
              data['auto_update_minutes']!, _autoUpdateMinutesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredProfileGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredProfileGroup(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      subscriptionSecretKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}subscription_secret_key']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      autoUpdateEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}auto_update_enabled'])!,
      autoUpdateMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}auto_update_minutes'])!,
    );
  }

  @override
  $ProfileGroupsTable createAlias(String alias) {
    return $ProfileGroupsTable(attachedDatabase, alias);
  }
}

class StoredProfileGroup extends DataClass
    implements Insertable<StoredProfileGroup> {
  final String id;
  final String name;
  final String? subscriptionSecretKey;
  final DateTime? updatedAt;
  final bool autoUpdateEnabled;
  final int autoUpdateMinutes;
  const StoredProfileGroup(
      {required this.id,
      required this.name,
      this.subscriptionSecretKey,
      this.updatedAt,
      required this.autoUpdateEnabled,
      required this.autoUpdateMinutes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || subscriptionSecretKey != null) {
      map['subscription_secret_key'] = Variable<String>(subscriptionSecretKey);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['auto_update_enabled'] = Variable<bool>(autoUpdateEnabled);
    map['auto_update_minutes'] = Variable<int>(autoUpdateMinutes);
    return map;
  }

  ProfileGroupsCompanion toCompanion(bool nullToAbsent) {
    return ProfileGroupsCompanion(
      id: Value(id),
      name: Value(name),
      subscriptionSecretKey: subscriptionSecretKey == null && nullToAbsent
          ? const Value.absent()
          : Value(subscriptionSecretKey),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      autoUpdateEnabled: Value(autoUpdateEnabled),
      autoUpdateMinutes: Value(autoUpdateMinutes),
    );
  }

  factory StoredProfileGroup.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredProfileGroup(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      subscriptionSecretKey:
          serializer.fromJson<String?>(json['subscriptionSecretKey']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      autoUpdateEnabled: serializer.fromJson<bool>(json['autoUpdateEnabled']),
      autoUpdateMinutes: serializer.fromJson<int>(json['autoUpdateMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'subscriptionSecretKey':
          serializer.toJson<String?>(subscriptionSecretKey),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'autoUpdateEnabled': serializer.toJson<bool>(autoUpdateEnabled),
      'autoUpdateMinutes': serializer.toJson<int>(autoUpdateMinutes),
    };
  }

  StoredProfileGroup copyWith(
          {String? id,
          String? name,
          Value<String?> subscriptionSecretKey = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent(),
          bool? autoUpdateEnabled,
          int? autoUpdateMinutes}) =>
      StoredProfileGroup(
        id: id ?? this.id,
        name: name ?? this.name,
        subscriptionSecretKey: subscriptionSecretKey.present
            ? subscriptionSecretKey.value
            : this.subscriptionSecretKey,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
        autoUpdateMinutes: autoUpdateMinutes ?? this.autoUpdateMinutes,
      );
  StoredProfileGroup copyWithCompanion(ProfileGroupsCompanion data) {
    return StoredProfileGroup(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      subscriptionSecretKey: data.subscriptionSecretKey.present
          ? data.subscriptionSecretKey.value
          : this.subscriptionSecretKey,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      autoUpdateEnabled: data.autoUpdateEnabled.present
          ? data.autoUpdateEnabled.value
          : this.autoUpdateEnabled,
      autoUpdateMinutes: data.autoUpdateMinutes.present
          ? data.autoUpdateMinutes.value
          : this.autoUpdateMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredProfileGroup(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('subscriptionSecretKey: $subscriptionSecretKey, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('autoUpdateEnabled: $autoUpdateEnabled, ')
          ..write('autoUpdateMinutes: $autoUpdateMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, subscriptionSecretKey, updatedAt,
      autoUpdateEnabled, autoUpdateMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredProfileGroup &&
          other.id == this.id &&
          other.name == this.name &&
          other.subscriptionSecretKey == this.subscriptionSecretKey &&
          other.updatedAt == this.updatedAt &&
          other.autoUpdateEnabled == this.autoUpdateEnabled &&
          other.autoUpdateMinutes == this.autoUpdateMinutes);
}

class ProfileGroupsCompanion extends UpdateCompanion<StoredProfileGroup> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> subscriptionSecretKey;
  final Value<DateTime?> updatedAt;
  final Value<bool> autoUpdateEnabled;
  final Value<int> autoUpdateMinutes;
  final Value<int> rowid;
  const ProfileGroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.subscriptionSecretKey = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.autoUpdateEnabled = const Value.absent(),
    this.autoUpdateMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfileGroupsCompanion.insert({
    required String id,
    required String name,
    this.subscriptionSecretKey = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.autoUpdateEnabled = const Value.absent(),
    this.autoUpdateMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<StoredProfileGroup> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? subscriptionSecretKey,
    Expression<DateTime>? updatedAt,
    Expression<bool>? autoUpdateEnabled,
    Expression<int>? autoUpdateMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (subscriptionSecretKey != null)
        'subscription_secret_key': subscriptionSecretKey,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (autoUpdateEnabled != null) 'auto_update_enabled': autoUpdateEnabled,
      if (autoUpdateMinutes != null) 'auto_update_minutes': autoUpdateMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfileGroupsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? subscriptionSecretKey,
      Value<DateTime?>? updatedAt,
      Value<bool>? autoUpdateEnabled,
      Value<int>? autoUpdateMinutes,
      Value<int>? rowid}) {
    return ProfileGroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      subscriptionSecretKey:
          subscriptionSecretKey ?? this.subscriptionSecretKey,
      updatedAt: updatedAt ?? this.updatedAt,
      autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
      autoUpdateMinutes: autoUpdateMinutes ?? this.autoUpdateMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (subscriptionSecretKey.present) {
      map['subscription_secret_key'] =
          Variable<String>(subscriptionSecretKey.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (autoUpdateEnabled.present) {
      map['auto_update_enabled'] = Variable<bool>(autoUpdateEnabled.value);
    }
    if (autoUpdateMinutes.present) {
      map['auto_update_minutes'] = Variable<int>(autoUpdateMinutes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileGroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('subscriptionSecretKey: $subscriptionSecretKey, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('autoUpdateEnabled: $autoUpdateEnabled, ')
          ..write('autoUpdateMinutes: $autoUpdateMinutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoutingPoliciesTable extends RoutingPolicies
    with TableInfo<$RoutingPoliciesTable, RoutingPolicy> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutingPoliciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, payload, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routing_policies';
  @override
  VerificationContext validateIntegrity(Insertable<RoutingPolicy> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoutingPolicy map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutingPolicy(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
    );
  }

  @override
  $RoutingPoliciesTable createAlias(String alias) {
    return $RoutingPoliciesTable(attachedDatabase, alias);
  }
}

class RoutingPolicy extends DataClass implements Insertable<RoutingPolicy> {
  final String id;
  final String payload;
  final int position;
  const RoutingPolicy(
      {required this.id, required this.payload, required this.position});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    map['position'] = Variable<int>(position);
    return map;
  }

  RoutingPoliciesCompanion toCompanion(bool nullToAbsent) {
    return RoutingPoliciesCompanion(
      id: Value(id),
      payload: Value(payload),
      position: Value(position),
    );
  }

  factory RoutingPolicy.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutingPolicy(
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'position': serializer.toJson<int>(position),
    };
  }

  RoutingPolicy copyWith({String? id, String? payload, int? position}) =>
      RoutingPolicy(
        id: id ?? this.id,
        payload: payload ?? this.payload,
        position: position ?? this.position,
      );
  RoutingPolicy copyWithCompanion(RoutingPoliciesCompanion data) {
    return RoutingPolicy(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutingPolicy(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutingPolicy &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.position == this.position);
}

class RoutingPoliciesCompanion extends UpdateCompanion<RoutingPolicy> {
  final Value<String> id;
  final Value<String> payload;
  final Value<int> position;
  final Value<int> rowid;
  const RoutingPoliciesCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoutingPoliciesCompanion.insert({
    required String id,
    required String payload,
    required int position,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        payload = Value(payload),
        position = Value(position);
  static Insertable<RoutingPolicy> custom({
    Expression<String>? id,
    Expression<String>? payload,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoutingPoliciesCompanion copyWith(
      {Value<String>? id,
      Value<String>? payload,
      Value<int>? position,
      Value<int>? rowid}) {
    return RoutingPoliciesCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutingPoliciesCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory Setting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) => Setting(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $ProfileGroupsTable profileGroups = $ProfileGroupsTable(this);
  late final $RoutingPoliciesTable routingPolicies =
      $RoutingPoliciesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [profiles, profileGroups, routingPolicies, settings];
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  required String id,
  required String name,
  required String protocol,
  required String payload,
  required String secretKey,
  Value<String?> groupId,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> protocol,
  Value<String> payload,
  Value<String> secretKey,
  Value<String?> groupId,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get protocol => $composableBuilder(
      column: $table.protocol, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get secretKey => $composableBuilder(
      column: $table.secretKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get protocol => $composableBuilder(
      column: $table.protocol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get secretKey => $composableBuilder(
      column: $table.secretKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get protocol =>
      $composableBuilder(column: $table.protocol, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get secretKey =>
      $composableBuilder(column: $table.secretKey, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProfilesTable,
    Profile,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
    Profile,
    PrefetchHooks Function()> {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> protocol = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<String> secretKey = const Value.absent(),
            Value<String?> groupId = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfilesCompanion(
            id: id,
            name: name,
            protocol: protocol,
            payload: payload,
            secretKey: secretKey,
            groupId: groupId,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String protocol,
            required String payload,
            required String secretKey,
            Value<String?> groupId = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfilesCompanion.insert(
            id: id,
            name: name,
            protocol: protocol,
            payload: payload,
            secretKey: secretKey,
            groupId: groupId,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ProfilesTable, Profile>(table),
                    BaseReferences<_$AppDatabase, $ProfilesTable, Profile>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProfilesTable,
    Profile,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
    Profile,
    PrefetchHooks Function()>;
typedef $$ProfileGroupsTableCreateCompanionBuilder = ProfileGroupsCompanion
    Function({
  required String id,
  required String name,
  Value<String?> subscriptionSecretKey,
  Value<DateTime?> updatedAt,
  Value<bool> autoUpdateEnabled,
  Value<int> autoUpdateMinutes,
  Value<int> rowid,
});
typedef $$ProfileGroupsTableUpdateCompanionBuilder = ProfileGroupsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String?> subscriptionSecretKey,
  Value<DateTime?> updatedAt,
  Value<bool> autoUpdateEnabled,
  Value<int> autoUpdateMinutes,
  Value<int> rowid,
});

class $$ProfileGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $ProfileGroupsTable> {
  $$ProfileGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subscriptionSecretKey => $composableBuilder(
      column: $table.subscriptionSecretKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get autoUpdateEnabled => $composableBuilder(
      column: $table.autoUpdateEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get autoUpdateMinutes => $composableBuilder(
      column: $table.autoUpdateMinutes,
      builder: (column) => ColumnFilters(column));
}

class $$ProfileGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfileGroupsTable> {
  $$ProfileGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subscriptionSecretKey => $composableBuilder(
      column: $table.subscriptionSecretKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get autoUpdateEnabled => $composableBuilder(
      column: $table.autoUpdateEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get autoUpdateMinutes => $composableBuilder(
      column: $table.autoUpdateMinutes,
      builder: (column) => ColumnOrderings(column));
}

class $$ProfileGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfileGroupsTable> {
  $$ProfileGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get subscriptionSecretKey => $composableBuilder(
      column: $table.subscriptionSecretKey, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get autoUpdateEnabled => $composableBuilder(
      column: $table.autoUpdateEnabled, builder: (column) => column);

  GeneratedColumn<int> get autoUpdateMinutes => $composableBuilder(
      column: $table.autoUpdateMinutes, builder: (column) => column);
}

class $$ProfileGroupsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProfileGroupsTable,
    StoredProfileGroup,
    $$ProfileGroupsTableFilterComposer,
    $$ProfileGroupsTableOrderingComposer,
    $$ProfileGroupsTableAnnotationComposer,
    $$ProfileGroupsTableCreateCompanionBuilder,
    $$ProfileGroupsTableUpdateCompanionBuilder,
    (
      StoredProfileGroup,
      BaseReferences<_$AppDatabase, $ProfileGroupsTable, StoredProfileGroup>
    ),
    StoredProfileGroup,
    PrefetchHooks Function()> {
  $$ProfileGroupsTableTableManager(_$AppDatabase db, $ProfileGroupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> subscriptionSecretKey = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<bool> autoUpdateEnabled = const Value.absent(),
            Value<int> autoUpdateMinutes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfileGroupsCompanion(
            id: id,
            name: name,
            subscriptionSecretKey: subscriptionSecretKey,
            updatedAt: updatedAt,
            autoUpdateEnabled: autoUpdateEnabled,
            autoUpdateMinutes: autoUpdateMinutes,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> subscriptionSecretKey = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<bool> autoUpdateEnabled = const Value.absent(),
            Value<int> autoUpdateMinutes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfileGroupsCompanion.insert(
            id: id,
            name: name,
            subscriptionSecretKey: subscriptionSecretKey,
            updatedAt: updatedAt,
            autoUpdateEnabled: autoUpdateEnabled,
            autoUpdateMinutes: autoUpdateMinutes,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ProfileGroupsTable, StoredProfileGroup>(table),
                    BaseReferences<_$AppDatabase, $ProfileGroupsTable,
                        StoredProfileGroup>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProfileGroupsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProfileGroupsTable,
    StoredProfileGroup,
    $$ProfileGroupsTableFilterComposer,
    $$ProfileGroupsTableOrderingComposer,
    $$ProfileGroupsTableAnnotationComposer,
    $$ProfileGroupsTableCreateCompanionBuilder,
    $$ProfileGroupsTableUpdateCompanionBuilder,
    (
      StoredProfileGroup,
      BaseReferences<_$AppDatabase, $ProfileGroupsTable, StoredProfileGroup>
    ),
    StoredProfileGroup,
    PrefetchHooks Function()>;
typedef $$RoutingPoliciesTableCreateCompanionBuilder = RoutingPoliciesCompanion
    Function({
  required String id,
  required String payload,
  required int position,
  Value<int> rowid,
});
typedef $$RoutingPoliciesTableUpdateCompanionBuilder = RoutingPoliciesCompanion
    Function({
  Value<String> id,
  Value<String> payload,
  Value<int> position,
  Value<int> rowid,
});

class $$RoutingPoliciesTableFilterComposer
    extends Composer<_$AppDatabase, $RoutingPoliciesTable> {
  $$RoutingPoliciesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));
}

class $$RoutingPoliciesTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutingPoliciesTable> {
  $$RoutingPoliciesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));
}

class $$RoutingPoliciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutingPoliciesTable> {
  $$RoutingPoliciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$RoutingPoliciesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RoutingPoliciesTable,
    RoutingPolicy,
    $$RoutingPoliciesTableFilterComposer,
    $$RoutingPoliciesTableOrderingComposer,
    $$RoutingPoliciesTableAnnotationComposer,
    $$RoutingPoliciesTableCreateCompanionBuilder,
    $$RoutingPoliciesTableUpdateCompanionBuilder,
    (
      RoutingPolicy,
      BaseReferences<_$AppDatabase, $RoutingPoliciesTable, RoutingPolicy>
    ),
    RoutingPolicy,
    PrefetchHooks Function()> {
  $$RoutingPoliciesTableTableManager(
      _$AppDatabase db, $RoutingPoliciesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutingPoliciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutingPoliciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutingPoliciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutingPoliciesCompanion(
            id: id,
            payload: payload,
            position: position,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String payload,
            required int position,
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutingPoliciesCompanion.insert(
            id: id,
            payload: payload,
            position: position,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$RoutingPoliciesTable, RoutingPolicy>(table),
                    BaseReferences<_$AppDatabase, $RoutingPoliciesTable,
                        RoutingPolicy>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RoutingPoliciesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RoutingPoliciesTable,
    RoutingPolicy,
    $$RoutingPoliciesTableFilterComposer,
    $$RoutingPoliciesTableOrderingComposer,
    $$RoutingPoliciesTableAnnotationComposer,
    $$RoutingPoliciesTableCreateCompanionBuilder,
    $$RoutingPoliciesTableUpdateCompanionBuilder,
    (
      RoutingPolicy,
      BaseReferences<_$AppDatabase, $RoutingPoliciesTable, RoutingPolicy>
    ),
    RoutingPolicy,
    PrefetchHooks Function()>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SettingsTable, Setting>(table),
                    BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$ProfileGroupsTableTableManager get profileGroups =>
      $$ProfileGroupsTableTableManager(_db, _db.profileGroups);
  $$RoutingPoliciesTableTableManager get routingPolicies =>
      $$RoutingPoliciesTableTableManager(_db, _db.routingPolicies);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
