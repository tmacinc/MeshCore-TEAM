// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ContactsTable extends Contacts
    with TableInfo<$ContactsTable, ContactData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _publicKeyMeta = const VerificationMeta(
    'publicKey',
  );
  @override
  late final GeneratedColumn<Uint8List> publicKey = GeneratedColumn<Uint8List>(
    'public_key',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<int> hash = GeneratedColumn<int>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSeenMeta = const VerificationMeta(
    'lastSeen',
  );
  @override
  late final GeneratedColumn<int> lastSeen = GeneratedColumn<int>(
    'last_seen',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companionBatteryMilliVoltsMeta =
      const VerificationMeta('companionBatteryMilliVolts');
  @override
  late final GeneratedColumn<int> companionBatteryMilliVolts =
      GeneratedColumn<int>(
        'companion_battery_milli_volts',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _phoneBatteryMilliVoltsMeta =
      const VerificationMeta('phoneBatteryMilliVolts');
  @override
  late final GeneratedColumn<int> phoneBatteryMilliVolts = GeneratedColumn<int>(
    'phone_battery_milli_volts',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isRepeaterMeta = const VerificationMeta(
    'isRepeater',
  );
  @override
  late final GeneratedColumn<bool> isRepeater = GeneratedColumn<bool>(
    'is_repeater',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_repeater" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isRoomServerMeta = const VerificationMeta(
    'isRoomServer',
  );
  @override
  late final GeneratedColumn<bool> isRoomServer = GeneratedColumn<bool>(
    'is_room_server',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_room_server" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDirectMeta = const VerificationMeta(
    'isDirect',
  );
  @override
  late final GeneratedColumn<bool> isDirect = GeneratedColumn<bool>(
    'is_direct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_direct" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hopCountMeta = const VerificationMeta(
    'hopCount',
  );
  @override
  late final GeneratedColumn<int> hopCount = GeneratedColumn<int>(
    'hop_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  static const VerificationMeta _lastTelemetryChannelIdxMeta =
      const VerificationMeta('lastTelemetryChannelIdx');
  @override
  late final GeneratedColumn<int> lastTelemetryChannelIdx =
      GeneratedColumn<int>(
        'last_telemetry_channel_idx',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastTelemetryTimestampMeta =
      const VerificationMeta('lastTelemetryTimestamp');
  @override
  late final GeneratedColumn<int> lastTelemetryTimestamp = GeneratedColumn<int>(
    'last_telemetry_timestamp',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isOutOfRangeMeta = const VerificationMeta(
    'isOutOfRange',
  );
  @override
  late final GeneratedColumn<bool> isOutOfRange = GeneratedColumn<bool>(
    'is_out_of_range',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_out_of_range" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isAutonomousDeviceMeta =
      const VerificationMeta('isAutonomousDevice');
  @override
  late final GeneratedColumn<bool> isAutonomousDevice = GeneratedColumn<bool>(
    'is_autonomous_device',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_autonomous_device" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _companionDeviceKeyMeta =
      const VerificationMeta('companionDeviceKey');
  @override
  late final GeneratedColumn<String> companionDeviceKey =
      GeneratedColumn<String>(
        'companion_device_key',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    publicKey,
    hash,
    name,
    latitude,
    longitude,
    lastSeen,
    companionBatteryMilliVolts,
    phoneBatteryMilliVolts,
    isRepeater,
    isRoomServer,
    isDirect,
    hopCount,
    lastTelemetryChannelIdx,
    lastTelemetryTimestamp,
    isOutOfRange,
    isAutonomousDevice,
    companionDeviceKey,
    isFavorite,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContactData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('public_key')) {
      context.handle(
        _publicKeyMeta,
        publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_publicKeyMeta);
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('last_seen')) {
      context.handle(
        _lastSeenMeta,
        lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_lastSeenMeta);
    }
    if (data.containsKey('companion_battery_milli_volts')) {
      context.handle(
        _companionBatteryMilliVoltsMeta,
        companionBatteryMilliVolts.isAcceptableOrUnknown(
          data['companion_battery_milli_volts']!,
          _companionBatteryMilliVoltsMeta,
        ),
      );
    }
    if (data.containsKey('phone_battery_milli_volts')) {
      context.handle(
        _phoneBatteryMilliVoltsMeta,
        phoneBatteryMilliVolts.isAcceptableOrUnknown(
          data['phone_battery_milli_volts']!,
          _phoneBatteryMilliVoltsMeta,
        ),
      );
    }
    if (data.containsKey('is_repeater')) {
      context.handle(
        _isRepeaterMeta,
        isRepeater.isAcceptableOrUnknown(data['is_repeater']!, _isRepeaterMeta),
      );
    }
    if (data.containsKey('is_room_server')) {
      context.handle(
        _isRoomServerMeta,
        isRoomServer.isAcceptableOrUnknown(
          data['is_room_server']!,
          _isRoomServerMeta,
        ),
      );
    }
    if (data.containsKey('is_direct')) {
      context.handle(
        _isDirectMeta,
        isDirect.isAcceptableOrUnknown(data['is_direct']!, _isDirectMeta),
      );
    }
    if (data.containsKey('hop_count')) {
      context.handle(
        _hopCountMeta,
        hopCount.isAcceptableOrUnknown(data['hop_count']!, _hopCountMeta),
      );
    }
    if (data.containsKey('last_telemetry_channel_idx')) {
      context.handle(
        _lastTelemetryChannelIdxMeta,
        lastTelemetryChannelIdx.isAcceptableOrUnknown(
          data['last_telemetry_channel_idx']!,
          _lastTelemetryChannelIdxMeta,
        ),
      );
    }
    if (data.containsKey('last_telemetry_timestamp')) {
      context.handle(
        _lastTelemetryTimestampMeta,
        lastTelemetryTimestamp.isAcceptableOrUnknown(
          data['last_telemetry_timestamp']!,
          _lastTelemetryTimestampMeta,
        ),
      );
    }
    if (data.containsKey('is_out_of_range')) {
      context.handle(
        _isOutOfRangeMeta,
        isOutOfRange.isAcceptableOrUnknown(
          data['is_out_of_range']!,
          _isOutOfRangeMeta,
        ),
      );
    }
    if (data.containsKey('is_autonomous_device')) {
      context.handle(
        _isAutonomousDeviceMeta,
        isAutonomousDevice.isAcceptableOrUnknown(
          data['is_autonomous_device']!,
          _isAutonomousDeviceMeta,
        ),
      );
    }
    if (data.containsKey('companion_device_key')) {
      context.handle(
        _companionDeviceKeyMeta,
        companionDeviceKey.isAcceptableOrUnknown(
          data['companion_device_key']!,
          _companionDeviceKeyMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {publicKey};
  @override
  ContactData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactData(
      publicKey:
          attachedDatabase.typeMapping.read(
            DriftSqlType.blob,
            data['${effectivePrefix}public_key'],
          )!,
      hash:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}hash'],
          )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      lastSeen:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}last_seen'],
          )!,
      companionBatteryMilliVolts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}companion_battery_milli_volts'],
      ),
      phoneBatteryMilliVolts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}phone_battery_milli_volts'],
      ),
      isRepeater:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_repeater'],
          )!,
      isRoomServer:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_room_server'],
          )!,
      isDirect:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_direct'],
          )!,
      hopCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}hop_count'],
          )!,
      lastTelemetryChannelIdx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_telemetry_channel_idx'],
      ),
      lastTelemetryTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_telemetry_timestamp'],
      ),
      isOutOfRange:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_out_of_range'],
          )!,
      isAutonomousDevice:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_autonomous_device'],
          )!,
      companionDeviceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}companion_device_key'],
      ),
      isFavorite:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_favorite'],
          )!,
    );
  }

  @override
  $ContactsTable createAlias(String alias) {
    return $ContactsTable(attachedDatabase, alias);
  }
}

class ContactData extends DataClass implements Insertable<ContactData> {
  final Uint8List publicKey;
  final int hash;
  final String? name;
  final double? latitude;
  final double? longitude;
  final int lastSeen;
  final int? companionBatteryMilliVolts;
  final int? phoneBatteryMilliVolts;
  final bool isRepeater;
  final bool isRoomServer;
  final bool isDirect;
  final int hopCount;
  final int? lastTelemetryChannelIdx;
  final int? lastTelemetryTimestamp;
  final bool isOutOfRange;
  final bool isAutonomousDevice;
  final String? companionDeviceKey;
  final bool isFavorite;
  const ContactData({
    required this.publicKey,
    required this.hash,
    this.name,
    this.latitude,
    this.longitude,
    required this.lastSeen,
    this.companionBatteryMilliVolts,
    this.phoneBatteryMilliVolts,
    required this.isRepeater,
    required this.isRoomServer,
    required this.isDirect,
    required this.hopCount,
    this.lastTelemetryChannelIdx,
    this.lastTelemetryTimestamp,
    required this.isOutOfRange,
    required this.isAutonomousDevice,
    this.companionDeviceKey,
    required this.isFavorite,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['public_key'] = Variable<Uint8List>(publicKey);
    map['hash'] = Variable<int>(hash);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['last_seen'] = Variable<int>(lastSeen);
    if (!nullToAbsent || companionBatteryMilliVolts != null) {
      map['companion_battery_milli_volts'] = Variable<int>(
        companionBatteryMilliVolts,
      );
    }
    if (!nullToAbsent || phoneBatteryMilliVolts != null) {
      map['phone_battery_milli_volts'] = Variable<int>(phoneBatteryMilliVolts);
    }
    map['is_repeater'] = Variable<bool>(isRepeater);
    map['is_room_server'] = Variable<bool>(isRoomServer);
    map['is_direct'] = Variable<bool>(isDirect);
    map['hop_count'] = Variable<int>(hopCount);
    if (!nullToAbsent || lastTelemetryChannelIdx != null) {
      map['last_telemetry_channel_idx'] = Variable<int>(
        lastTelemetryChannelIdx,
      );
    }
    if (!nullToAbsent || lastTelemetryTimestamp != null) {
      map['last_telemetry_timestamp'] = Variable<int>(lastTelemetryTimestamp);
    }
    map['is_out_of_range'] = Variable<bool>(isOutOfRange);
    map['is_autonomous_device'] = Variable<bool>(isAutonomousDevice);
    if (!nullToAbsent || companionDeviceKey != null) {
      map['companion_device_key'] = Variable<String>(companionDeviceKey);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    return map;
  }

  ContactsCompanion toCompanion(bool nullToAbsent) {
    return ContactsCompanion(
      publicKey: Value(publicKey),
      hash: Value(hash),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      latitude:
          latitude == null && nullToAbsent
              ? const Value.absent()
              : Value(latitude),
      longitude:
          longitude == null && nullToAbsent
              ? const Value.absent()
              : Value(longitude),
      lastSeen: Value(lastSeen),
      companionBatteryMilliVolts:
          companionBatteryMilliVolts == null && nullToAbsent
              ? const Value.absent()
              : Value(companionBatteryMilliVolts),
      phoneBatteryMilliVolts:
          phoneBatteryMilliVolts == null && nullToAbsent
              ? const Value.absent()
              : Value(phoneBatteryMilliVolts),
      isRepeater: Value(isRepeater),
      isRoomServer: Value(isRoomServer),
      isDirect: Value(isDirect),
      hopCount: Value(hopCount),
      lastTelemetryChannelIdx:
          lastTelemetryChannelIdx == null && nullToAbsent
              ? const Value.absent()
              : Value(lastTelemetryChannelIdx),
      lastTelemetryTimestamp:
          lastTelemetryTimestamp == null && nullToAbsent
              ? const Value.absent()
              : Value(lastTelemetryTimestamp),
      isOutOfRange: Value(isOutOfRange),
      isAutonomousDevice: Value(isAutonomousDevice),
      companionDeviceKey:
          companionDeviceKey == null && nullToAbsent
              ? const Value.absent()
              : Value(companionDeviceKey),
      isFavorite: Value(isFavorite),
    );
  }

  factory ContactData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactData(
      publicKey: serializer.fromJson<Uint8List>(json['publicKey']),
      hash: serializer.fromJson<int>(json['hash']),
      name: serializer.fromJson<String?>(json['name']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      lastSeen: serializer.fromJson<int>(json['lastSeen']),
      companionBatteryMilliVolts: serializer.fromJson<int?>(
        json['companionBatteryMilliVolts'],
      ),
      phoneBatteryMilliVolts: serializer.fromJson<int?>(
        json['phoneBatteryMilliVolts'],
      ),
      isRepeater: serializer.fromJson<bool>(json['isRepeater']),
      isRoomServer: serializer.fromJson<bool>(json['isRoomServer']),
      isDirect: serializer.fromJson<bool>(json['isDirect']),
      hopCount: serializer.fromJson<int>(json['hopCount']),
      lastTelemetryChannelIdx: serializer.fromJson<int?>(
        json['lastTelemetryChannelIdx'],
      ),
      lastTelemetryTimestamp: serializer.fromJson<int?>(
        json['lastTelemetryTimestamp'],
      ),
      isOutOfRange: serializer.fromJson<bool>(json['isOutOfRange']),
      isAutonomousDevice: serializer.fromJson<bool>(json['isAutonomousDevice']),
      companionDeviceKey: serializer.fromJson<String?>(
        json['companionDeviceKey'],
      ),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'publicKey': serializer.toJson<Uint8List>(publicKey),
      'hash': serializer.toJson<int>(hash),
      'name': serializer.toJson<String?>(name),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'lastSeen': serializer.toJson<int>(lastSeen),
      'companionBatteryMilliVolts': serializer.toJson<int?>(
        companionBatteryMilliVolts,
      ),
      'phoneBatteryMilliVolts': serializer.toJson<int?>(phoneBatteryMilliVolts),
      'isRepeater': serializer.toJson<bool>(isRepeater),
      'isRoomServer': serializer.toJson<bool>(isRoomServer),
      'isDirect': serializer.toJson<bool>(isDirect),
      'hopCount': serializer.toJson<int>(hopCount),
      'lastTelemetryChannelIdx': serializer.toJson<int?>(
        lastTelemetryChannelIdx,
      ),
      'lastTelemetryTimestamp': serializer.toJson<int?>(lastTelemetryTimestamp),
      'isOutOfRange': serializer.toJson<bool>(isOutOfRange),
      'isAutonomousDevice': serializer.toJson<bool>(isAutonomousDevice),
      'companionDeviceKey': serializer.toJson<String?>(companionDeviceKey),
      'isFavorite': serializer.toJson<bool>(isFavorite),
    };
  }

  ContactData copyWith({
    Uint8List? publicKey,
    int? hash,
    Value<String?> name = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    int? lastSeen,
    Value<int?> companionBatteryMilliVolts = const Value.absent(),
    Value<int?> phoneBatteryMilliVolts = const Value.absent(),
    bool? isRepeater,
    bool? isRoomServer,
    bool? isDirect,
    int? hopCount,
    Value<int?> lastTelemetryChannelIdx = const Value.absent(),
    Value<int?> lastTelemetryTimestamp = const Value.absent(),
    bool? isOutOfRange,
    bool? isAutonomousDevice,
    Value<String?> companionDeviceKey = const Value.absent(),
    bool? isFavorite,
  }) => ContactData(
    publicKey: publicKey ?? this.publicKey,
    hash: hash ?? this.hash,
    name: name.present ? name.value : this.name,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    lastSeen: lastSeen ?? this.lastSeen,
    companionBatteryMilliVolts:
        companionBatteryMilliVolts.present
            ? companionBatteryMilliVolts.value
            : this.companionBatteryMilliVolts,
    phoneBatteryMilliVolts:
        phoneBatteryMilliVolts.present
            ? phoneBatteryMilliVolts.value
            : this.phoneBatteryMilliVolts,
    isRepeater: isRepeater ?? this.isRepeater,
    isRoomServer: isRoomServer ?? this.isRoomServer,
    isDirect: isDirect ?? this.isDirect,
    hopCount: hopCount ?? this.hopCount,
    lastTelemetryChannelIdx:
        lastTelemetryChannelIdx.present
            ? lastTelemetryChannelIdx.value
            : this.lastTelemetryChannelIdx,
    lastTelemetryTimestamp:
        lastTelemetryTimestamp.present
            ? lastTelemetryTimestamp.value
            : this.lastTelemetryTimestamp,
    isOutOfRange: isOutOfRange ?? this.isOutOfRange,
    isAutonomousDevice: isAutonomousDevice ?? this.isAutonomousDevice,
    companionDeviceKey:
        companionDeviceKey.present
            ? companionDeviceKey.value
            : this.companionDeviceKey,
    isFavorite: isFavorite ?? this.isFavorite,
  );
  ContactData copyWithCompanion(ContactsCompanion data) {
    return ContactData(
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      hash: data.hash.present ? data.hash.value : this.hash,
      name: data.name.present ? data.name.value : this.name,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
      companionBatteryMilliVolts:
          data.companionBatteryMilliVolts.present
              ? data.companionBatteryMilliVolts.value
              : this.companionBatteryMilliVolts,
      phoneBatteryMilliVolts:
          data.phoneBatteryMilliVolts.present
              ? data.phoneBatteryMilliVolts.value
              : this.phoneBatteryMilliVolts,
      isRepeater:
          data.isRepeater.present ? data.isRepeater.value : this.isRepeater,
      isRoomServer:
          data.isRoomServer.present
              ? data.isRoomServer.value
              : this.isRoomServer,
      isDirect: data.isDirect.present ? data.isDirect.value : this.isDirect,
      hopCount: data.hopCount.present ? data.hopCount.value : this.hopCount,
      lastTelemetryChannelIdx:
          data.lastTelemetryChannelIdx.present
              ? data.lastTelemetryChannelIdx.value
              : this.lastTelemetryChannelIdx,
      lastTelemetryTimestamp:
          data.lastTelemetryTimestamp.present
              ? data.lastTelemetryTimestamp.value
              : this.lastTelemetryTimestamp,
      isOutOfRange:
          data.isOutOfRange.present
              ? data.isOutOfRange.value
              : this.isOutOfRange,
      isAutonomousDevice:
          data.isAutonomousDevice.present
              ? data.isAutonomousDevice.value
              : this.isAutonomousDevice,
      companionDeviceKey:
          data.companionDeviceKey.present
              ? data.companionDeviceKey.value
              : this.companionDeviceKey,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactData(')
          ..write('publicKey: $publicKey, ')
          ..write('hash: $hash, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('companionBatteryMilliVolts: $companionBatteryMilliVolts, ')
          ..write('phoneBatteryMilliVolts: $phoneBatteryMilliVolts, ')
          ..write('isRepeater: $isRepeater, ')
          ..write('isRoomServer: $isRoomServer, ')
          ..write('isDirect: $isDirect, ')
          ..write('hopCount: $hopCount, ')
          ..write('lastTelemetryChannelIdx: $lastTelemetryChannelIdx, ')
          ..write('lastTelemetryTimestamp: $lastTelemetryTimestamp, ')
          ..write('isOutOfRange: $isOutOfRange, ')
          ..write('isAutonomousDevice: $isAutonomousDevice, ')
          ..write('companionDeviceKey: $companionDeviceKey, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    $driftBlobEquality.hash(publicKey),
    hash,
    name,
    latitude,
    longitude,
    lastSeen,
    companionBatteryMilliVolts,
    phoneBatteryMilliVolts,
    isRepeater,
    isRoomServer,
    isDirect,
    hopCount,
    lastTelemetryChannelIdx,
    lastTelemetryTimestamp,
    isOutOfRange,
    isAutonomousDevice,
    companionDeviceKey,
    isFavorite,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactData &&
          $driftBlobEquality.equals(other.publicKey, this.publicKey) &&
          other.hash == this.hash &&
          other.name == this.name &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.lastSeen == this.lastSeen &&
          other.companionBatteryMilliVolts == this.companionBatteryMilliVolts &&
          other.phoneBatteryMilliVolts == this.phoneBatteryMilliVolts &&
          other.isRepeater == this.isRepeater &&
          other.isRoomServer == this.isRoomServer &&
          other.isDirect == this.isDirect &&
          other.hopCount == this.hopCount &&
          other.lastTelemetryChannelIdx == this.lastTelemetryChannelIdx &&
          other.lastTelemetryTimestamp == this.lastTelemetryTimestamp &&
          other.isOutOfRange == this.isOutOfRange &&
          other.isAutonomousDevice == this.isAutonomousDevice &&
          other.companionDeviceKey == this.companionDeviceKey &&
          other.isFavorite == this.isFavorite);
}

class ContactsCompanion extends UpdateCompanion<ContactData> {
  final Value<Uint8List> publicKey;
  final Value<int> hash;
  final Value<String?> name;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<int> lastSeen;
  final Value<int?> companionBatteryMilliVolts;
  final Value<int?> phoneBatteryMilliVolts;
  final Value<bool> isRepeater;
  final Value<bool> isRoomServer;
  final Value<bool> isDirect;
  final Value<int> hopCount;
  final Value<int?> lastTelemetryChannelIdx;
  final Value<int?> lastTelemetryTimestamp;
  final Value<bool> isOutOfRange;
  final Value<bool> isAutonomousDevice;
  final Value<String?> companionDeviceKey;
  final Value<bool> isFavorite;
  final Value<int> rowid;
  const ContactsCompanion({
    this.publicKey = const Value.absent(),
    this.hash = const Value.absent(),
    this.name = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.companionBatteryMilliVolts = const Value.absent(),
    this.phoneBatteryMilliVolts = const Value.absent(),
    this.isRepeater = const Value.absent(),
    this.isRoomServer = const Value.absent(),
    this.isDirect = const Value.absent(),
    this.hopCount = const Value.absent(),
    this.lastTelemetryChannelIdx = const Value.absent(),
    this.lastTelemetryTimestamp = const Value.absent(),
    this.isOutOfRange = const Value.absent(),
    this.isAutonomousDevice = const Value.absent(),
    this.companionDeviceKey = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactsCompanion.insert({
    required Uint8List publicKey,
    required int hash,
    this.name = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    required int lastSeen,
    this.companionBatteryMilliVolts = const Value.absent(),
    this.phoneBatteryMilliVolts = const Value.absent(),
    this.isRepeater = const Value.absent(),
    this.isRoomServer = const Value.absent(),
    this.isDirect = const Value.absent(),
    this.hopCount = const Value.absent(),
    this.lastTelemetryChannelIdx = const Value.absent(),
    this.lastTelemetryTimestamp = const Value.absent(),
    this.isOutOfRange = const Value.absent(),
    this.isAutonomousDevice = const Value.absent(),
    this.companionDeviceKey = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : publicKey = Value(publicKey),
       hash = Value(hash),
       lastSeen = Value(lastSeen);
  static Insertable<ContactData> custom({
    Expression<Uint8List>? publicKey,
    Expression<int>? hash,
    Expression<String>? name,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? lastSeen,
    Expression<int>? companionBatteryMilliVolts,
    Expression<int>? phoneBatteryMilliVolts,
    Expression<bool>? isRepeater,
    Expression<bool>? isRoomServer,
    Expression<bool>? isDirect,
    Expression<int>? hopCount,
    Expression<int>? lastTelemetryChannelIdx,
    Expression<int>? lastTelemetryTimestamp,
    Expression<bool>? isOutOfRange,
    Expression<bool>? isAutonomousDevice,
    Expression<String>? companionDeviceKey,
    Expression<bool>? isFavorite,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (publicKey != null) 'public_key': publicKey,
      if (hash != null) 'hash': hash,
      if (name != null) 'name': name,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (companionBatteryMilliVolts != null)
        'companion_battery_milli_volts': companionBatteryMilliVolts,
      if (phoneBatteryMilliVolts != null)
        'phone_battery_milli_volts': phoneBatteryMilliVolts,
      if (isRepeater != null) 'is_repeater': isRepeater,
      if (isRoomServer != null) 'is_room_server': isRoomServer,
      if (isDirect != null) 'is_direct': isDirect,
      if (hopCount != null) 'hop_count': hopCount,
      if (lastTelemetryChannelIdx != null)
        'last_telemetry_channel_idx': lastTelemetryChannelIdx,
      if (lastTelemetryTimestamp != null)
        'last_telemetry_timestamp': lastTelemetryTimestamp,
      if (isOutOfRange != null) 'is_out_of_range': isOutOfRange,
      if (isAutonomousDevice != null)
        'is_autonomous_device': isAutonomousDevice,
      if (companionDeviceKey != null)
        'companion_device_key': companionDeviceKey,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactsCompanion copyWith({
    Value<Uint8List>? publicKey,
    Value<int>? hash,
    Value<String?>? name,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<int>? lastSeen,
    Value<int?>? companionBatteryMilliVolts,
    Value<int?>? phoneBatteryMilliVolts,
    Value<bool>? isRepeater,
    Value<bool>? isRoomServer,
    Value<bool>? isDirect,
    Value<int>? hopCount,
    Value<int?>? lastTelemetryChannelIdx,
    Value<int?>? lastTelemetryTimestamp,
    Value<bool>? isOutOfRange,
    Value<bool>? isAutonomousDevice,
    Value<String?>? companionDeviceKey,
    Value<bool>? isFavorite,
    Value<int>? rowid,
  }) {
    return ContactsCompanion(
      publicKey: publicKey ?? this.publicKey,
      hash: hash ?? this.hash,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastSeen: lastSeen ?? this.lastSeen,
      companionBatteryMilliVolts:
          companionBatteryMilliVolts ?? this.companionBatteryMilliVolts,
      phoneBatteryMilliVolts:
          phoneBatteryMilliVolts ?? this.phoneBatteryMilliVolts,
      isRepeater: isRepeater ?? this.isRepeater,
      isRoomServer: isRoomServer ?? this.isRoomServer,
      isDirect: isDirect ?? this.isDirect,
      hopCount: hopCount ?? this.hopCount,
      lastTelemetryChannelIdx:
          lastTelemetryChannelIdx ?? this.lastTelemetryChannelIdx,
      lastTelemetryTimestamp:
          lastTelemetryTimestamp ?? this.lastTelemetryTimestamp,
      isOutOfRange: isOutOfRange ?? this.isOutOfRange,
      isAutonomousDevice: isAutonomousDevice ?? this.isAutonomousDevice,
      companionDeviceKey: companionDeviceKey ?? this.companionDeviceKey,
      isFavorite: isFavorite ?? this.isFavorite,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (publicKey.present) {
      map['public_key'] = Variable<Uint8List>(publicKey.value);
    }
    if (hash.present) {
      map['hash'] = Variable<int>(hash.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<int>(lastSeen.value);
    }
    if (companionBatteryMilliVolts.present) {
      map['companion_battery_milli_volts'] = Variable<int>(
        companionBatteryMilliVolts.value,
      );
    }
    if (phoneBatteryMilliVolts.present) {
      map['phone_battery_milli_volts'] = Variable<int>(
        phoneBatteryMilliVolts.value,
      );
    }
    if (isRepeater.present) {
      map['is_repeater'] = Variable<bool>(isRepeater.value);
    }
    if (isRoomServer.present) {
      map['is_room_server'] = Variable<bool>(isRoomServer.value);
    }
    if (isDirect.present) {
      map['is_direct'] = Variable<bool>(isDirect.value);
    }
    if (hopCount.present) {
      map['hop_count'] = Variable<int>(hopCount.value);
    }
    if (lastTelemetryChannelIdx.present) {
      map['last_telemetry_channel_idx'] = Variable<int>(
        lastTelemetryChannelIdx.value,
      );
    }
    if (lastTelemetryTimestamp.present) {
      map['last_telemetry_timestamp'] = Variable<int>(
        lastTelemetryTimestamp.value,
      );
    }
    if (isOutOfRange.present) {
      map['is_out_of_range'] = Variable<bool>(isOutOfRange.value);
    }
    if (isAutonomousDevice.present) {
      map['is_autonomous_device'] = Variable<bool>(isAutonomousDevice.value);
    }
    if (companionDeviceKey.present) {
      map['companion_device_key'] = Variable<String>(companionDeviceKey.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactsCompanion(')
          ..write('publicKey: $publicKey, ')
          ..write('hash: $hash, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('companionBatteryMilliVolts: $companionBatteryMilliVolts, ')
          ..write('phoneBatteryMilliVolts: $phoneBatteryMilliVolts, ')
          ..write('isRepeater: $isRepeater, ')
          ..write('isRoomServer: $isRoomServer, ')
          ..write('isDirect: $isDirect, ')
          ..write('hopCount: $hopCount, ')
          ..write('lastTelemetryChannelIdx: $lastTelemetryChannelIdx, ')
          ..write('lastTelemetryTimestamp: $lastTelemetryTimestamp, ')
          ..write('isOutOfRange: $isOutOfRange, ')
          ..write('isAutonomousDevice: $isAutonomousDevice, ')
          ..write('companionDeviceKey: $companionDeviceKey, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChannelsTable extends Channels
    with TableInfo<$ChannelsTable, ChannelData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<int> hash = GeneratedColumn<int>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sharedKeyMeta = const VerificationMeta(
    'sharedKey',
  );
  @override
  late final GeneratedColumn<Uint8List> sharedKey = GeneratedColumn<Uint8List>(
    'shared_key',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPublicMeta = const VerificationMeta(
    'isPublic',
  );
  @override
  late final GeneratedColumn<bool> isPublic = GeneratedColumn<bool>(
    'is_public',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_public" IN (0, 1))',
    ),
  );
  static const VerificationMeta _shareLocationMeta = const VerificationMeta(
    'shareLocation',
  );
  @override
  late final GeneratedColumn<bool> shareLocation = GeneratedColumn<bool>(
    'share_location',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("share_location" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _channelIndexMeta = const VerificationMeta(
    'channelIndex',
  );
  @override
  late final GeneratedColumn<int> channelIndex = GeneratedColumn<int>(
    'channel_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notificationModeMeta = const VerificationMeta(
    'notificationMode',
  );
  @override
  late final GeneratedColumn<String> notificationMode = GeneratedColumn<String>(
    'notification_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _companionDeviceKeyMeta =
      const VerificationMeta('companionDeviceKey');
  @override
  late final GeneratedColumn<String> companionDeviceKey =
      GeneratedColumn<String>(
        'companion_device_key',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    hash,
    name,
    sharedKey,
    isPublic,
    shareLocation,
    channelIndex,
    createdAt,
    notificationMode,
    isFavorite,
    companionDeviceKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChannelData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('shared_key')) {
      context.handle(
        _sharedKeyMeta,
        sharedKey.isAcceptableOrUnknown(data['shared_key']!, _sharedKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_sharedKeyMeta);
    }
    if (data.containsKey('is_public')) {
      context.handle(
        _isPublicMeta,
        isPublic.isAcceptableOrUnknown(data['is_public']!, _isPublicMeta),
      );
    } else if (isInserting) {
      context.missing(_isPublicMeta);
    }
    if (data.containsKey('share_location')) {
      context.handle(
        _shareLocationMeta,
        shareLocation.isAcceptableOrUnknown(
          data['share_location']!,
          _shareLocationMeta,
        ),
      );
    }
    if (data.containsKey('channel_index')) {
      context.handle(
        _channelIndexMeta,
        channelIndex.isAcceptableOrUnknown(
          data['channel_index']!,
          _channelIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_channelIndexMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('notification_mode')) {
      context.handle(
        _notificationModeMeta,
        notificationMode.isAcceptableOrUnknown(
          data['notification_mode']!,
          _notificationModeMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('companion_device_key')) {
      context.handle(
        _companionDeviceKeyMeta,
        companionDeviceKey.isAcceptableOrUnknown(
          data['companion_device_key']!,
          _companionDeviceKeyMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {hash};
  @override
  ChannelData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChannelData(
      hash:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}hash'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      sharedKey:
          attachedDatabase.typeMapping.read(
            DriftSqlType.blob,
            data['${effectivePrefix}shared_key'],
          )!,
      isPublic:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_public'],
          )!,
      shareLocation:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}share_location'],
          )!,
      channelIndex:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}channel_index'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}created_at'],
          )!,
      notificationMode:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}notification_mode'],
          )!,
      isFavorite:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_favorite'],
          )!,
      companionDeviceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}companion_device_key'],
      ),
    );
  }

  @override
  $ChannelsTable createAlias(String alias) {
    return $ChannelsTable(attachedDatabase, alias);
  }
}

class ChannelData extends DataClass implements Insertable<ChannelData> {
  final int hash;
  final String name;
  final Uint8List sharedKey;
  final bool isPublic;
  final bool shareLocation;
  final int channelIndex;
  final int createdAt;
  final String notificationMode;
  final bool isFavorite;
  final String? companionDeviceKey;
  const ChannelData({
    required this.hash,
    required this.name,
    required this.sharedKey,
    required this.isPublic,
    required this.shareLocation,
    required this.channelIndex,
    required this.createdAt,
    required this.notificationMode,
    required this.isFavorite,
    this.companionDeviceKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['hash'] = Variable<int>(hash);
    map['name'] = Variable<String>(name);
    map['shared_key'] = Variable<Uint8List>(sharedKey);
    map['is_public'] = Variable<bool>(isPublic);
    map['share_location'] = Variable<bool>(shareLocation);
    map['channel_index'] = Variable<int>(channelIndex);
    map['created_at'] = Variable<int>(createdAt);
    map['notification_mode'] = Variable<String>(notificationMode);
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || companionDeviceKey != null) {
      map['companion_device_key'] = Variable<String>(companionDeviceKey);
    }
    return map;
  }

  ChannelsCompanion toCompanion(bool nullToAbsent) {
    return ChannelsCompanion(
      hash: Value(hash),
      name: Value(name),
      sharedKey: Value(sharedKey),
      isPublic: Value(isPublic),
      shareLocation: Value(shareLocation),
      channelIndex: Value(channelIndex),
      createdAt: Value(createdAt),
      notificationMode: Value(notificationMode),
      isFavorite: Value(isFavorite),
      companionDeviceKey:
          companionDeviceKey == null && nullToAbsent
              ? const Value.absent()
              : Value(companionDeviceKey),
    );
  }

  factory ChannelData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChannelData(
      hash: serializer.fromJson<int>(json['hash']),
      name: serializer.fromJson<String>(json['name']),
      sharedKey: serializer.fromJson<Uint8List>(json['sharedKey']),
      isPublic: serializer.fromJson<bool>(json['isPublic']),
      shareLocation: serializer.fromJson<bool>(json['shareLocation']),
      channelIndex: serializer.fromJson<int>(json['channelIndex']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      notificationMode: serializer.fromJson<String>(json['notificationMode']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      companionDeviceKey: serializer.fromJson<String?>(
        json['companionDeviceKey'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'hash': serializer.toJson<int>(hash),
      'name': serializer.toJson<String>(name),
      'sharedKey': serializer.toJson<Uint8List>(sharedKey),
      'isPublic': serializer.toJson<bool>(isPublic),
      'shareLocation': serializer.toJson<bool>(shareLocation),
      'channelIndex': serializer.toJson<int>(channelIndex),
      'createdAt': serializer.toJson<int>(createdAt),
      'notificationMode': serializer.toJson<String>(notificationMode),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'companionDeviceKey': serializer.toJson<String?>(companionDeviceKey),
    };
  }

  ChannelData copyWith({
    int? hash,
    String? name,
    Uint8List? sharedKey,
    bool? isPublic,
    bool? shareLocation,
    int? channelIndex,
    int? createdAt,
    String? notificationMode,
    bool? isFavorite,
    Value<String?> companionDeviceKey = const Value.absent(),
  }) => ChannelData(
    hash: hash ?? this.hash,
    name: name ?? this.name,
    sharedKey: sharedKey ?? this.sharedKey,
    isPublic: isPublic ?? this.isPublic,
    shareLocation: shareLocation ?? this.shareLocation,
    channelIndex: channelIndex ?? this.channelIndex,
    createdAt: createdAt ?? this.createdAt,
    notificationMode: notificationMode ?? this.notificationMode,
    isFavorite: isFavorite ?? this.isFavorite,
    companionDeviceKey:
        companionDeviceKey.present
            ? companionDeviceKey.value
            : this.companionDeviceKey,
  );
  ChannelData copyWithCompanion(ChannelsCompanion data) {
    return ChannelData(
      hash: data.hash.present ? data.hash.value : this.hash,
      name: data.name.present ? data.name.value : this.name,
      sharedKey: data.sharedKey.present ? data.sharedKey.value : this.sharedKey,
      isPublic: data.isPublic.present ? data.isPublic.value : this.isPublic,
      shareLocation:
          data.shareLocation.present
              ? data.shareLocation.value
              : this.shareLocation,
      channelIndex:
          data.channelIndex.present
              ? data.channelIndex.value
              : this.channelIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      notificationMode:
          data.notificationMode.present
              ? data.notificationMode.value
              : this.notificationMode,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      companionDeviceKey:
          data.companionDeviceKey.present
              ? data.companionDeviceKey.value
              : this.companionDeviceKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChannelData(')
          ..write('hash: $hash, ')
          ..write('name: $name, ')
          ..write('sharedKey: $sharedKey, ')
          ..write('isPublic: $isPublic, ')
          ..write('shareLocation: $shareLocation, ')
          ..write('channelIndex: $channelIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('notificationMode: $notificationMode, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('companionDeviceKey: $companionDeviceKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    hash,
    name,
    $driftBlobEquality.hash(sharedKey),
    isPublic,
    shareLocation,
    channelIndex,
    createdAt,
    notificationMode,
    isFavorite,
    companionDeviceKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelData &&
          other.hash == this.hash &&
          other.name == this.name &&
          $driftBlobEquality.equals(other.sharedKey, this.sharedKey) &&
          other.isPublic == this.isPublic &&
          other.shareLocation == this.shareLocation &&
          other.channelIndex == this.channelIndex &&
          other.createdAt == this.createdAt &&
          other.notificationMode == this.notificationMode &&
          other.isFavorite == this.isFavorite &&
          other.companionDeviceKey == this.companionDeviceKey);
}

class ChannelsCompanion extends UpdateCompanion<ChannelData> {
  final Value<int> hash;
  final Value<String> name;
  final Value<Uint8List> sharedKey;
  final Value<bool> isPublic;
  final Value<bool> shareLocation;
  final Value<int> channelIndex;
  final Value<int> createdAt;
  final Value<String> notificationMode;
  final Value<bool> isFavorite;
  final Value<String?> companionDeviceKey;
  const ChannelsCompanion({
    this.hash = const Value.absent(),
    this.name = const Value.absent(),
    this.sharedKey = const Value.absent(),
    this.isPublic = const Value.absent(),
    this.shareLocation = const Value.absent(),
    this.channelIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.notificationMode = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.companionDeviceKey = const Value.absent(),
  });
  ChannelsCompanion.insert({
    this.hash = const Value.absent(),
    required String name,
    required Uint8List sharedKey,
    required bool isPublic,
    this.shareLocation = const Value.absent(),
    required int channelIndex,
    required int createdAt,
    this.notificationMode = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.companionDeviceKey = const Value.absent(),
  }) : name = Value(name),
       sharedKey = Value(sharedKey),
       isPublic = Value(isPublic),
       channelIndex = Value(channelIndex),
       createdAt = Value(createdAt);
  static Insertable<ChannelData> custom({
    Expression<int>? hash,
    Expression<String>? name,
    Expression<Uint8List>? sharedKey,
    Expression<bool>? isPublic,
    Expression<bool>? shareLocation,
    Expression<int>? channelIndex,
    Expression<int>? createdAt,
    Expression<String>? notificationMode,
    Expression<bool>? isFavorite,
    Expression<String>? companionDeviceKey,
  }) {
    return RawValuesInsertable({
      if (hash != null) 'hash': hash,
      if (name != null) 'name': name,
      if (sharedKey != null) 'shared_key': sharedKey,
      if (isPublic != null) 'is_public': isPublic,
      if (shareLocation != null) 'share_location': shareLocation,
      if (channelIndex != null) 'channel_index': channelIndex,
      if (createdAt != null) 'created_at': createdAt,
      if (notificationMode != null) 'notification_mode': notificationMode,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (companionDeviceKey != null)
        'companion_device_key': companionDeviceKey,
    });
  }

  ChannelsCompanion copyWith({
    Value<int>? hash,
    Value<String>? name,
    Value<Uint8List>? sharedKey,
    Value<bool>? isPublic,
    Value<bool>? shareLocation,
    Value<int>? channelIndex,
    Value<int>? createdAt,
    Value<String>? notificationMode,
    Value<bool>? isFavorite,
    Value<String?>? companionDeviceKey,
  }) {
    return ChannelsCompanion(
      hash: hash ?? this.hash,
      name: name ?? this.name,
      sharedKey: sharedKey ?? this.sharedKey,
      isPublic: isPublic ?? this.isPublic,
      shareLocation: shareLocation ?? this.shareLocation,
      channelIndex: channelIndex ?? this.channelIndex,
      createdAt: createdAt ?? this.createdAt,
      notificationMode: notificationMode ?? this.notificationMode,
      isFavorite: isFavorite ?? this.isFavorite,
      companionDeviceKey: companionDeviceKey ?? this.companionDeviceKey,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (hash.present) {
      map['hash'] = Variable<int>(hash.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sharedKey.present) {
      map['shared_key'] = Variable<Uint8List>(sharedKey.value);
    }
    if (isPublic.present) {
      map['is_public'] = Variable<bool>(isPublic.value);
    }
    if (shareLocation.present) {
      map['share_location'] = Variable<bool>(shareLocation.value);
    }
    if (channelIndex.present) {
      map['channel_index'] = Variable<int>(channelIndex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (notificationMode.present) {
      map['notification_mode'] = Variable<String>(notificationMode.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (companionDeviceKey.present) {
      map['companion_device_key'] = Variable<String>(companionDeviceKey.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelsCompanion(')
          ..write('hash: $hash, ')
          ..write('name: $name, ')
          ..write('sharedKey: $sharedKey, ')
          ..write('isPublic: $isPublic, ')
          ..write('shareLocation: $shareLocation, ')
          ..write('channelIndex: $channelIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('notificationMode: $notificationMode, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('companionDeviceKey: $companionDeviceKey')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages
    with TableInfo<$MessagesTable, MessageData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<Uint8List> senderId = GeneratedColumn<Uint8List>(
    'sender_id',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderNameMeta = const VerificationMeta(
    'senderName',
  );
  @override
  late final GeneratedColumn<String> senderName = GeneratedColumn<String>(
    'sender_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelHashMeta = const VerificationMeta(
    'channelHash',
  );
  @override
  late final GeneratedColumn<int> channelHash = GeneratedColumn<int>(
    'channel_hash',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPrivateMeta = const VerificationMeta(
    'isPrivate',
  );
  @override
  late final GeneratedColumn<bool> isPrivate = GeneratedColumn<bool>(
    'is_private',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_private" IN (0, 1))',
    ),
  );
  static const VerificationMeta _ackChecksumMeta = const VerificationMeta(
    'ackChecksum',
  );
  @override
  late final GeneratedColumn<Uint8List> ackChecksum =
      GeneratedColumn<Uint8List>(
        'ack_checksum',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deliveryStatusMeta = const VerificationMeta(
    'deliveryStatus',
  );
  @override
  late final GeneratedColumn<String> deliveryStatus = GeneratedColumn<String>(
    'delivery_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heardByCountMeta = const VerificationMeta(
    'heardByCount',
  );
  @override
  late final GeneratedColumn<int> heardByCount = GeneratedColumn<int>(
    'heard_by_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _attemptMeta = const VerificationMeta(
    'attempt',
  );
  @override
  late final GeneratedColumn<int> attempt = GeneratedColumn<int>(
    'attempt',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isSentByMeMeta = const VerificationMeta(
    'isSentByMe',
  );
  @override
  late final GeneratedColumn<bool> isSentByMe = GeneratedColumn<bool>(
    'is_sent_by_me',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_sent_by_me" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _companionDeviceKeyMeta =
      const VerificationMeta('companionDeviceKey');
  @override
  late final GeneratedColumn<String> companionDeviceKey =
      GeneratedColumn<String>(
        'companion_device_key',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _senderPeerIdMeta = const VerificationMeta(
    'senderPeerId',
  );
  @override
  late final GeneratedColumn<int> senderPeerId = GeneratedColumn<int>(
    'sender_peer_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    senderId,
    senderName,
    channelHash,
    content,
    timestamp,
    isPrivate,
    ackChecksum,
    deliveryStatus,
    heardByCount,
    attempt,
    isSentByMe,
    isRead,
    companionDeviceKey,
    senderPeerId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('sender_name')) {
      context.handle(
        _senderNameMeta,
        senderName.isAcceptableOrUnknown(data['sender_name']!, _senderNameMeta),
      );
    }
    if (data.containsKey('channel_hash')) {
      context.handle(
        _channelHashMeta,
        channelHash.isAcceptableOrUnknown(
          data['channel_hash']!,
          _channelHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_channelHashMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('is_private')) {
      context.handle(
        _isPrivateMeta,
        isPrivate.isAcceptableOrUnknown(data['is_private']!, _isPrivateMeta),
      );
    } else if (isInserting) {
      context.missing(_isPrivateMeta);
    }
    if (data.containsKey('ack_checksum')) {
      context.handle(
        _ackChecksumMeta,
        ackChecksum.isAcceptableOrUnknown(
          data['ack_checksum']!,
          _ackChecksumMeta,
        ),
      );
    }
    if (data.containsKey('delivery_status')) {
      context.handle(
        _deliveryStatusMeta,
        deliveryStatus.isAcceptableOrUnknown(
          data['delivery_status']!,
          _deliveryStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveryStatusMeta);
    }
    if (data.containsKey('heard_by_count')) {
      context.handle(
        _heardByCountMeta,
        heardByCount.isAcceptableOrUnknown(
          data['heard_by_count']!,
          _heardByCountMeta,
        ),
      );
    }
    if (data.containsKey('attempt')) {
      context.handle(
        _attemptMeta,
        attempt.isAcceptableOrUnknown(data['attempt']!, _attemptMeta),
      );
    }
    if (data.containsKey('is_sent_by_me')) {
      context.handle(
        _isSentByMeMeta,
        isSentByMe.isAcceptableOrUnknown(
          data['is_sent_by_me']!,
          _isSentByMeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isSentByMeMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('companion_device_key')) {
      context.handle(
        _companionDeviceKeyMeta,
        companionDeviceKey.isAcceptableOrUnknown(
          data['companion_device_key']!,
          _companionDeviceKeyMeta,
        ),
      );
    }
    if (data.containsKey('sender_peer_id')) {
      context.handle(
        _senderPeerIdMeta,
        senderPeerId.isAcceptableOrUnknown(
          data['sender_peer_id']!,
          _senderPeerIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      senderId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.blob,
            data['${effectivePrefix}sender_id'],
          )!,
      senderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_name'],
      ),
      channelHash:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}channel_hash'],
          )!,
      content:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}content'],
          )!,
      timestamp:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}timestamp'],
          )!,
      isPrivate:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_private'],
          )!,
      ackChecksum: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}ack_checksum'],
      ),
      deliveryStatus:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}delivery_status'],
          )!,
      heardByCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}heard_by_count'],
          )!,
      attempt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}attempt'],
          )!,
      isSentByMe:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_sent_by_me'],
          )!,
      isRead:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_read'],
          )!,
      companionDeviceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}companion_device_key'],
      ),
      senderPeerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sender_peer_id'],
      ),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class MessageData extends DataClass implements Insertable<MessageData> {
  final String id;
  final Uint8List senderId;
  final String? senderName;
  final int channelHash;
  final String content;
  final int timestamp;
  final bool isPrivate;
  final Uint8List? ackChecksum;
  final String deliveryStatus;
  final int heardByCount;
  final int attempt;
  final bool isSentByMe;
  final bool isRead;
  final String? companionDeviceKey;
  final int? senderPeerId;
  const MessageData({
    required this.id,
    required this.senderId,
    this.senderName,
    required this.channelHash,
    required this.content,
    required this.timestamp,
    required this.isPrivate,
    this.ackChecksum,
    required this.deliveryStatus,
    required this.heardByCount,
    required this.attempt,
    required this.isSentByMe,
    required this.isRead,
    this.companionDeviceKey,
    this.senderPeerId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sender_id'] = Variable<Uint8List>(senderId);
    if (!nullToAbsent || senderName != null) {
      map['sender_name'] = Variable<String>(senderName);
    }
    map['channel_hash'] = Variable<int>(channelHash);
    map['content'] = Variable<String>(content);
    map['timestamp'] = Variable<int>(timestamp);
    map['is_private'] = Variable<bool>(isPrivate);
    if (!nullToAbsent || ackChecksum != null) {
      map['ack_checksum'] = Variable<Uint8List>(ackChecksum);
    }
    map['delivery_status'] = Variable<String>(deliveryStatus);
    map['heard_by_count'] = Variable<int>(heardByCount);
    map['attempt'] = Variable<int>(attempt);
    map['is_sent_by_me'] = Variable<bool>(isSentByMe);
    map['is_read'] = Variable<bool>(isRead);
    if (!nullToAbsent || companionDeviceKey != null) {
      map['companion_device_key'] = Variable<String>(companionDeviceKey);
    }
    if (!nullToAbsent || senderPeerId != null) {
      map['sender_peer_id'] = Variable<int>(senderPeerId);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      senderId: Value(senderId),
      senderName:
          senderName == null && nullToAbsent
              ? const Value.absent()
              : Value(senderName),
      channelHash: Value(channelHash),
      content: Value(content),
      timestamp: Value(timestamp),
      isPrivate: Value(isPrivate),
      ackChecksum:
          ackChecksum == null && nullToAbsent
              ? const Value.absent()
              : Value(ackChecksum),
      deliveryStatus: Value(deliveryStatus),
      heardByCount: Value(heardByCount),
      attempt: Value(attempt),
      isSentByMe: Value(isSentByMe),
      isRead: Value(isRead),
      companionDeviceKey:
          companionDeviceKey == null && nullToAbsent
              ? const Value.absent()
              : Value(companionDeviceKey),
      senderPeerId:
          senderPeerId == null && nullToAbsent
              ? const Value.absent()
              : Value(senderPeerId),
    );
  }

  factory MessageData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageData(
      id: serializer.fromJson<String>(json['id']),
      senderId: serializer.fromJson<Uint8List>(json['senderId']),
      senderName: serializer.fromJson<String?>(json['senderName']),
      channelHash: serializer.fromJson<int>(json['channelHash']),
      content: serializer.fromJson<String>(json['content']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      isPrivate: serializer.fromJson<bool>(json['isPrivate']),
      ackChecksum: serializer.fromJson<Uint8List?>(json['ackChecksum']),
      deliveryStatus: serializer.fromJson<String>(json['deliveryStatus']),
      heardByCount: serializer.fromJson<int>(json['heardByCount']),
      attempt: serializer.fromJson<int>(json['attempt']),
      isSentByMe: serializer.fromJson<bool>(json['isSentByMe']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      companionDeviceKey: serializer.fromJson<String?>(
        json['companionDeviceKey'],
      ),
      senderPeerId: serializer.fromJson<int?>(json['senderPeerId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'senderId': serializer.toJson<Uint8List>(senderId),
      'senderName': serializer.toJson<String?>(senderName),
      'channelHash': serializer.toJson<int>(channelHash),
      'content': serializer.toJson<String>(content),
      'timestamp': serializer.toJson<int>(timestamp),
      'isPrivate': serializer.toJson<bool>(isPrivate),
      'ackChecksum': serializer.toJson<Uint8List?>(ackChecksum),
      'deliveryStatus': serializer.toJson<String>(deliveryStatus),
      'heardByCount': serializer.toJson<int>(heardByCount),
      'attempt': serializer.toJson<int>(attempt),
      'isSentByMe': serializer.toJson<bool>(isSentByMe),
      'isRead': serializer.toJson<bool>(isRead),
      'companionDeviceKey': serializer.toJson<String?>(companionDeviceKey),
      'senderPeerId': serializer.toJson<int?>(senderPeerId),
    };
  }

  MessageData copyWith({
    String? id,
    Uint8List? senderId,
    Value<String?> senderName = const Value.absent(),
    int? channelHash,
    String? content,
    int? timestamp,
    bool? isPrivate,
    Value<Uint8List?> ackChecksum = const Value.absent(),
    String? deliveryStatus,
    int? heardByCount,
    int? attempt,
    bool? isSentByMe,
    bool? isRead,
    Value<String?> companionDeviceKey = const Value.absent(),
    Value<int?> senderPeerId = const Value.absent(),
  }) => MessageData(
    id: id ?? this.id,
    senderId: senderId ?? this.senderId,
    senderName: senderName.present ? senderName.value : this.senderName,
    channelHash: channelHash ?? this.channelHash,
    content: content ?? this.content,
    timestamp: timestamp ?? this.timestamp,
    isPrivate: isPrivate ?? this.isPrivate,
    ackChecksum: ackChecksum.present ? ackChecksum.value : this.ackChecksum,
    deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    heardByCount: heardByCount ?? this.heardByCount,
    attempt: attempt ?? this.attempt,
    isSentByMe: isSentByMe ?? this.isSentByMe,
    isRead: isRead ?? this.isRead,
    companionDeviceKey:
        companionDeviceKey.present
            ? companionDeviceKey.value
            : this.companionDeviceKey,
    senderPeerId: senderPeerId.present ? senderPeerId.value : this.senderPeerId,
  );
  MessageData copyWithCompanion(MessagesCompanion data) {
    return MessageData(
      id: data.id.present ? data.id.value : this.id,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      senderName:
          data.senderName.present ? data.senderName.value : this.senderName,
      channelHash:
          data.channelHash.present ? data.channelHash.value : this.channelHash,
      content: data.content.present ? data.content.value : this.content,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isPrivate: data.isPrivate.present ? data.isPrivate.value : this.isPrivate,
      ackChecksum:
          data.ackChecksum.present ? data.ackChecksum.value : this.ackChecksum,
      deliveryStatus:
          data.deliveryStatus.present
              ? data.deliveryStatus.value
              : this.deliveryStatus,
      heardByCount:
          data.heardByCount.present
              ? data.heardByCount.value
              : this.heardByCount,
      attempt: data.attempt.present ? data.attempt.value : this.attempt,
      isSentByMe:
          data.isSentByMe.present ? data.isSentByMe.value : this.isSentByMe,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      companionDeviceKey:
          data.companionDeviceKey.present
              ? data.companionDeviceKey.value
              : this.companionDeviceKey,
      senderPeerId:
          data.senderPeerId.present
              ? data.senderPeerId.value
              : this.senderPeerId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageData(')
          ..write('id: $id, ')
          ..write('senderId: $senderId, ')
          ..write('senderName: $senderName, ')
          ..write('channelHash: $channelHash, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('ackChecksum: $ackChecksum, ')
          ..write('deliveryStatus: $deliveryStatus, ')
          ..write('heardByCount: $heardByCount, ')
          ..write('attempt: $attempt, ')
          ..write('isSentByMe: $isSentByMe, ')
          ..write('isRead: $isRead, ')
          ..write('companionDeviceKey: $companionDeviceKey, ')
          ..write('senderPeerId: $senderPeerId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    $driftBlobEquality.hash(senderId),
    senderName,
    channelHash,
    content,
    timestamp,
    isPrivate,
    $driftBlobEquality.hash(ackChecksum),
    deliveryStatus,
    heardByCount,
    attempt,
    isSentByMe,
    isRead,
    companionDeviceKey,
    senderPeerId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageData &&
          other.id == this.id &&
          $driftBlobEquality.equals(other.senderId, this.senderId) &&
          other.senderName == this.senderName &&
          other.channelHash == this.channelHash &&
          other.content == this.content &&
          other.timestamp == this.timestamp &&
          other.isPrivate == this.isPrivate &&
          $driftBlobEquality.equals(other.ackChecksum, this.ackChecksum) &&
          other.deliveryStatus == this.deliveryStatus &&
          other.heardByCount == this.heardByCount &&
          other.attempt == this.attempt &&
          other.isSentByMe == this.isSentByMe &&
          other.isRead == this.isRead &&
          other.companionDeviceKey == this.companionDeviceKey &&
          other.senderPeerId == this.senderPeerId);
}

class MessagesCompanion extends UpdateCompanion<MessageData> {
  final Value<String> id;
  final Value<Uint8List> senderId;
  final Value<String?> senderName;
  final Value<int> channelHash;
  final Value<String> content;
  final Value<int> timestamp;
  final Value<bool> isPrivate;
  final Value<Uint8List?> ackChecksum;
  final Value<String> deliveryStatus;
  final Value<int> heardByCount;
  final Value<int> attempt;
  final Value<bool> isSentByMe;
  final Value<bool> isRead;
  final Value<String?> companionDeviceKey;
  final Value<int?> senderPeerId;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.senderId = const Value.absent(),
    this.senderName = const Value.absent(),
    this.channelHash = const Value.absent(),
    this.content = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isPrivate = const Value.absent(),
    this.ackChecksum = const Value.absent(),
    this.deliveryStatus = const Value.absent(),
    this.heardByCount = const Value.absent(),
    this.attempt = const Value.absent(),
    this.isSentByMe = const Value.absent(),
    this.isRead = const Value.absent(),
    this.companionDeviceKey = const Value.absent(),
    this.senderPeerId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    required Uint8List senderId,
    this.senderName = const Value.absent(),
    required int channelHash,
    required String content,
    required int timestamp,
    required bool isPrivate,
    this.ackChecksum = const Value.absent(),
    required String deliveryStatus,
    this.heardByCount = const Value.absent(),
    this.attempt = const Value.absent(),
    required bool isSentByMe,
    this.isRead = const Value.absent(),
    this.companionDeviceKey = const Value.absent(),
    this.senderPeerId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       senderId = Value(senderId),
       channelHash = Value(channelHash),
       content = Value(content),
       timestamp = Value(timestamp),
       isPrivate = Value(isPrivate),
       deliveryStatus = Value(deliveryStatus),
       isSentByMe = Value(isSentByMe);
  static Insertable<MessageData> custom({
    Expression<String>? id,
    Expression<Uint8List>? senderId,
    Expression<String>? senderName,
    Expression<int>? channelHash,
    Expression<String>? content,
    Expression<int>? timestamp,
    Expression<bool>? isPrivate,
    Expression<Uint8List>? ackChecksum,
    Expression<String>? deliveryStatus,
    Expression<int>? heardByCount,
    Expression<int>? attempt,
    Expression<bool>? isSentByMe,
    Expression<bool>? isRead,
    Expression<String>? companionDeviceKey,
    Expression<int>? senderPeerId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (senderId != null) 'sender_id': senderId,
      if (senderName != null) 'sender_name': senderName,
      if (channelHash != null) 'channel_hash': channelHash,
      if (content != null) 'content': content,
      if (timestamp != null) 'timestamp': timestamp,
      if (isPrivate != null) 'is_private': isPrivate,
      if (ackChecksum != null) 'ack_checksum': ackChecksum,
      if (deliveryStatus != null) 'delivery_status': deliveryStatus,
      if (heardByCount != null) 'heard_by_count': heardByCount,
      if (attempt != null) 'attempt': attempt,
      if (isSentByMe != null) 'is_sent_by_me': isSentByMe,
      if (isRead != null) 'is_read': isRead,
      if (companionDeviceKey != null)
        'companion_device_key': companionDeviceKey,
      if (senderPeerId != null) 'sender_peer_id': senderPeerId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? id,
    Value<Uint8List>? senderId,
    Value<String?>? senderName,
    Value<int>? channelHash,
    Value<String>? content,
    Value<int>? timestamp,
    Value<bool>? isPrivate,
    Value<Uint8List?>? ackChecksum,
    Value<String>? deliveryStatus,
    Value<int>? heardByCount,
    Value<int>? attempt,
    Value<bool>? isSentByMe,
    Value<bool>? isRead,
    Value<String?>? companionDeviceKey,
    Value<int?>? senderPeerId,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      channelHash: channelHash ?? this.channelHash,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isPrivate: isPrivate ?? this.isPrivate,
      ackChecksum: ackChecksum ?? this.ackChecksum,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      heardByCount: heardByCount ?? this.heardByCount,
      attempt: attempt ?? this.attempt,
      isSentByMe: isSentByMe ?? this.isSentByMe,
      isRead: isRead ?? this.isRead,
      companionDeviceKey: companionDeviceKey ?? this.companionDeviceKey,
      senderPeerId: senderPeerId ?? this.senderPeerId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<Uint8List>(senderId.value);
    }
    if (senderName.present) {
      map['sender_name'] = Variable<String>(senderName.value);
    }
    if (channelHash.present) {
      map['channel_hash'] = Variable<int>(channelHash.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (isPrivate.present) {
      map['is_private'] = Variable<bool>(isPrivate.value);
    }
    if (ackChecksum.present) {
      map['ack_checksum'] = Variable<Uint8List>(ackChecksum.value);
    }
    if (deliveryStatus.present) {
      map['delivery_status'] = Variable<String>(deliveryStatus.value);
    }
    if (heardByCount.present) {
      map['heard_by_count'] = Variable<int>(heardByCount.value);
    }
    if (attempt.present) {
      map['attempt'] = Variable<int>(attempt.value);
    }
    if (isSentByMe.present) {
      map['is_sent_by_me'] = Variable<bool>(isSentByMe.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (companionDeviceKey.present) {
      map['companion_device_key'] = Variable<String>(companionDeviceKey.value);
    }
    if (senderPeerId.present) {
      map['sender_peer_id'] = Variable<int>(senderPeerId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('senderId: $senderId, ')
          ..write('senderName: $senderName, ')
          ..write('channelHash: $channelHash, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('ackChecksum: $ackChecksum, ')
          ..write('deliveryStatus: $deliveryStatus, ')
          ..write('heardByCount: $heardByCount, ')
          ..write('attempt: $attempt, ')
          ..write('isSentByMe: $isSentByMe, ')
          ..write('isRead: $isRead, ')
          ..write('companionDeviceKey: $companionDeviceKey, ')
          ..write('senderPeerId: $senderPeerId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WaypointsTable extends Waypoints
    with TableInfo<$WaypointsTable, WaypointData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaypointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meshIdMeta = const VerificationMeta('meshId');
  @override
  late final GeneratedColumn<String> meshId = GeneratedColumn<String>(
    'mesh_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _waypointTypeMeta = const VerificationMeta(
    'waypointType',
  );
  @override
  late final GeneratedColumn<String> waypointType = GeneratedColumn<String>(
    'waypoint_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creatorNodeIdMeta = const VerificationMeta(
    'creatorNodeId',
  );
  @override
  late final GeneratedColumn<String> creatorNodeId = GeneratedColumn<String>(
    'creator_node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isReceivedMeta = const VerificationMeta(
    'isReceived',
  );
  @override
  late final GeneratedColumn<bool> isReceived = GeneratedColumn<bool>(
    'is_received',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_received" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isVisibleMeta = const VerificationMeta(
    'isVisible',
  );
  @override
  late final GeneratedColumn<bool> isVisible = GeneratedColumn<bool>(
    'is_visible',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_visible" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isNewMeta = const VerificationMeta('isNew');
  @override
  late final GeneratedColumn<bool> isNew = GeneratedColumn<bool>(
    'is_new',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_new" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    meshId,
    name,
    description,
    latitude,
    longitude,
    waypointType,
    creatorNodeId,
    createdAt,
    isReceived,
    isVisible,
    isNew,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'waypoints';
  @override
  VerificationContext validateIntegrity(
    Insertable<WaypointData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('mesh_id')) {
      context.handle(
        _meshIdMeta,
        meshId.isAcceptableOrUnknown(data['mesh_id']!, _meshIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('waypoint_type')) {
      context.handle(
        _waypointTypeMeta,
        waypointType.isAcceptableOrUnknown(
          data['waypoint_type']!,
          _waypointTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_waypointTypeMeta);
    }
    if (data.containsKey('creator_node_id')) {
      context.handle(
        _creatorNodeIdMeta,
        creatorNodeId.isAcceptableOrUnknown(
          data['creator_node_id']!,
          _creatorNodeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_creatorNodeIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_received')) {
      context.handle(
        _isReceivedMeta,
        isReceived.isAcceptableOrUnknown(data['is_received']!, _isReceivedMeta),
      );
    }
    if (data.containsKey('is_visible')) {
      context.handle(
        _isVisibleMeta,
        isVisible.isAcceptableOrUnknown(data['is_visible']!, _isVisibleMeta),
      );
    }
    if (data.containsKey('is_new')) {
      context.handle(
        _isNewMeta,
        isNew.isAcceptableOrUnknown(data['is_new']!, _isNewMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WaypointData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaypointData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      meshId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mesh_id'],
      ),
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      description:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}description'],
          )!,
      latitude:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}latitude'],
          )!,
      longitude:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}longitude'],
          )!,
      waypointType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}waypoint_type'],
          )!,
      creatorNodeId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}creator_node_id'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}created_at'],
          )!,
      isReceived:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_received'],
          )!,
      isVisible:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_visible'],
          )!,
      isNew:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_new'],
          )!,
    );
  }

  @override
  $WaypointsTable createAlias(String alias) {
    return $WaypointsTable(attachedDatabase, alias);
  }
}

class WaypointData extends DataClass implements Insertable<WaypointData> {
  final String id;
  final String? meshId;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String waypointType;
  final String creatorNodeId;
  final int createdAt;
  final bool isReceived;
  final bool isVisible;
  final bool isNew;
  const WaypointData({
    required this.id,
    this.meshId,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.waypointType,
    required this.creatorNodeId,
    required this.createdAt,
    required this.isReceived,
    required this.isVisible,
    required this.isNew,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || meshId != null) {
      map['mesh_id'] = Variable<String>(meshId);
    }
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['waypoint_type'] = Variable<String>(waypointType);
    map['creator_node_id'] = Variable<String>(creatorNodeId);
    map['created_at'] = Variable<int>(createdAt);
    map['is_received'] = Variable<bool>(isReceived);
    map['is_visible'] = Variable<bool>(isVisible);
    map['is_new'] = Variable<bool>(isNew);
    return map;
  }

  WaypointsCompanion toCompanion(bool nullToAbsent) {
    return WaypointsCompanion(
      id: Value(id),
      meshId:
          meshId == null && nullToAbsent ? const Value.absent() : Value(meshId),
      name: Value(name),
      description: Value(description),
      latitude: Value(latitude),
      longitude: Value(longitude),
      waypointType: Value(waypointType),
      creatorNodeId: Value(creatorNodeId),
      createdAt: Value(createdAt),
      isReceived: Value(isReceived),
      isVisible: Value(isVisible),
      isNew: Value(isNew),
    );
  }

  factory WaypointData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaypointData(
      id: serializer.fromJson<String>(json['id']),
      meshId: serializer.fromJson<String?>(json['meshId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      waypointType: serializer.fromJson<String>(json['waypointType']),
      creatorNodeId: serializer.fromJson<String>(json['creatorNodeId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      isReceived: serializer.fromJson<bool>(json['isReceived']),
      isVisible: serializer.fromJson<bool>(json['isVisible']),
      isNew: serializer.fromJson<bool>(json['isNew']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'meshId': serializer.toJson<String?>(meshId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'waypointType': serializer.toJson<String>(waypointType),
      'creatorNodeId': serializer.toJson<String>(creatorNodeId),
      'createdAt': serializer.toJson<int>(createdAt),
      'isReceived': serializer.toJson<bool>(isReceived),
      'isVisible': serializer.toJson<bool>(isVisible),
      'isNew': serializer.toJson<bool>(isNew),
    };
  }

  WaypointData copyWith({
    String? id,
    Value<String?> meshId = const Value.absent(),
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? waypointType,
    String? creatorNodeId,
    int? createdAt,
    bool? isReceived,
    bool? isVisible,
    bool? isNew,
  }) => WaypointData(
    id: id ?? this.id,
    meshId: meshId.present ? meshId.value : this.meshId,
    name: name ?? this.name,
    description: description ?? this.description,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    waypointType: waypointType ?? this.waypointType,
    creatorNodeId: creatorNodeId ?? this.creatorNodeId,
    createdAt: createdAt ?? this.createdAt,
    isReceived: isReceived ?? this.isReceived,
    isVisible: isVisible ?? this.isVisible,
    isNew: isNew ?? this.isNew,
  );
  WaypointData copyWithCompanion(WaypointsCompanion data) {
    return WaypointData(
      id: data.id.present ? data.id.value : this.id,
      meshId: data.meshId.present ? data.meshId.value : this.meshId,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      waypointType:
          data.waypointType.present
              ? data.waypointType.value
              : this.waypointType,
      creatorNodeId:
          data.creatorNodeId.present
              ? data.creatorNodeId.value
              : this.creatorNodeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isReceived:
          data.isReceived.present ? data.isReceived.value : this.isReceived,
      isVisible: data.isVisible.present ? data.isVisible.value : this.isVisible,
      isNew: data.isNew.present ? data.isNew.value : this.isNew,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaypointData(')
          ..write('id: $id, ')
          ..write('meshId: $meshId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('waypointType: $waypointType, ')
          ..write('creatorNodeId: $creatorNodeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('isReceived: $isReceived, ')
          ..write('isVisible: $isVisible, ')
          ..write('isNew: $isNew')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    meshId,
    name,
    description,
    latitude,
    longitude,
    waypointType,
    creatorNodeId,
    createdAt,
    isReceived,
    isVisible,
    isNew,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaypointData &&
          other.id == this.id &&
          other.meshId == this.meshId &&
          other.name == this.name &&
          other.description == this.description &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.waypointType == this.waypointType &&
          other.creatorNodeId == this.creatorNodeId &&
          other.createdAt == this.createdAt &&
          other.isReceived == this.isReceived &&
          other.isVisible == this.isVisible &&
          other.isNew == this.isNew);
}

class WaypointsCompanion extends UpdateCompanion<WaypointData> {
  final Value<String> id;
  final Value<String?> meshId;
  final Value<String> name;
  final Value<String> description;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String> waypointType;
  final Value<String> creatorNodeId;
  final Value<int> createdAt;
  final Value<bool> isReceived;
  final Value<bool> isVisible;
  final Value<bool> isNew;
  final Value<int> rowid;
  const WaypointsCompanion({
    this.id = const Value.absent(),
    this.meshId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.waypointType = const Value.absent(),
    this.creatorNodeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isReceived = const Value.absent(),
    this.isVisible = const Value.absent(),
    this.isNew = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WaypointsCompanion.insert({
    required String id,
    this.meshId = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required double latitude,
    required double longitude,
    required String waypointType,
    required String creatorNodeId,
    required int createdAt,
    this.isReceived = const Value.absent(),
    this.isVisible = const Value.absent(),
    this.isNew = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       latitude = Value(latitude),
       longitude = Value(longitude),
       waypointType = Value(waypointType),
       creatorNodeId = Value(creatorNodeId),
       createdAt = Value(createdAt);
  static Insertable<WaypointData> custom({
    Expression<String>? id,
    Expression<String>? meshId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? waypointType,
    Expression<String>? creatorNodeId,
    Expression<int>? createdAt,
    Expression<bool>? isReceived,
    Expression<bool>? isVisible,
    Expression<bool>? isNew,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (meshId != null) 'mesh_id': meshId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (waypointType != null) 'waypoint_type': waypointType,
      if (creatorNodeId != null) 'creator_node_id': creatorNodeId,
      if (createdAt != null) 'created_at': createdAt,
      if (isReceived != null) 'is_received': isReceived,
      if (isVisible != null) 'is_visible': isVisible,
      if (isNew != null) 'is_new': isNew,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WaypointsCompanion copyWith({
    Value<String>? id,
    Value<String?>? meshId,
    Value<String>? name,
    Value<String>? description,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<String>? waypointType,
    Value<String>? creatorNodeId,
    Value<int>? createdAt,
    Value<bool>? isReceived,
    Value<bool>? isVisible,
    Value<bool>? isNew,
    Value<int>? rowid,
  }) {
    return WaypointsCompanion(
      id: id ?? this.id,
      meshId: meshId ?? this.meshId,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      waypointType: waypointType ?? this.waypointType,
      creatorNodeId: creatorNodeId ?? this.creatorNodeId,
      createdAt: createdAt ?? this.createdAt,
      isReceived: isReceived ?? this.isReceived,
      isVisible: isVisible ?? this.isVisible,
      isNew: isNew ?? this.isNew,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (meshId.present) {
      map['mesh_id'] = Variable<String>(meshId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (waypointType.present) {
      map['waypoint_type'] = Variable<String>(waypointType.value);
    }
    if (creatorNodeId.present) {
      map['creator_node_id'] = Variable<String>(creatorNodeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (isReceived.present) {
      map['is_received'] = Variable<bool>(isReceived.value);
    }
    if (isVisible.present) {
      map['is_visible'] = Variable<bool>(isVisible.value);
    }
    if (isNew.present) {
      map['is_new'] = Variable<bool>(isNew.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaypointsCompanion(')
          ..write('id: $id, ')
          ..write('meshId: $meshId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('waypointType: $waypointType, ')
          ..write('creatorNodeId: $creatorNodeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('isReceived: $isReceived, ')
          ..write('isVisible: $isVisible, ')
          ..write('isNew: $isNew, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompanionDevicesTable extends CompanionDevices
    with TableInfo<$CompanionDevicesTable, CompanionDeviceData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompanionDevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _publicKeyHexMeta = const VerificationMeta(
    'publicKeyHex',
  );
  @override
  late final GeneratedColumn<String> publicKeyHex = GeneratedColumn<String>(
    'public_key_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstConnectedMeta = const VerificationMeta(
    'firstConnected',
  );
  @override
  late final GeneratedColumn<int> firstConnected = GeneratedColumn<int>(
    'first_connected',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastConnectedMeta = const VerificationMeta(
    'lastConnected',
  );
  @override
  late final GeneratedColumn<int> lastConnected = GeneratedColumn<int>(
    'last_connected',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _connectionCountMeta = const VerificationMeta(
    'connectionCount',
  );
  @override
  late final GeneratedColumn<int> connectionCount = GeneratedColumn<int>(
    'connection_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    publicKeyHex,
    name,
    firstConnected,
    lastConnected,
    connectionCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'companion_devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompanionDeviceData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('public_key_hex')) {
      context.handle(
        _publicKeyHexMeta,
        publicKeyHex.isAcceptableOrUnknown(
          data['public_key_hex']!,
          _publicKeyHexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publicKeyHexMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('first_connected')) {
      context.handle(
        _firstConnectedMeta,
        firstConnected.isAcceptableOrUnknown(
          data['first_connected']!,
          _firstConnectedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstConnectedMeta);
    }
    if (data.containsKey('last_connected')) {
      context.handle(
        _lastConnectedMeta,
        lastConnected.isAcceptableOrUnknown(
          data['last_connected']!,
          _lastConnectedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastConnectedMeta);
    }
    if (data.containsKey('connection_count')) {
      context.handle(
        _connectionCountMeta,
        connectionCount.isAcceptableOrUnknown(
          data['connection_count']!,
          _connectionCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {publicKeyHex};
  @override
  CompanionDeviceData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompanionDeviceData(
      publicKeyHex:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}public_key_hex'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      firstConnected:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}first_connected'],
          )!,
      lastConnected:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}last_connected'],
          )!,
      connectionCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}connection_count'],
          )!,
    );
  }

  @override
  $CompanionDevicesTable createAlias(String alias) {
    return $CompanionDevicesTable(attachedDatabase, alias);
  }
}

class CompanionDeviceData extends DataClass
    implements Insertable<CompanionDeviceData> {
  final String publicKeyHex;
  final String name;
  final int firstConnected;
  final int lastConnected;
  final int connectionCount;
  const CompanionDeviceData({
    required this.publicKeyHex,
    required this.name,
    required this.firstConnected,
    required this.lastConnected,
    required this.connectionCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['public_key_hex'] = Variable<String>(publicKeyHex);
    map['name'] = Variable<String>(name);
    map['first_connected'] = Variable<int>(firstConnected);
    map['last_connected'] = Variable<int>(lastConnected);
    map['connection_count'] = Variable<int>(connectionCount);
    return map;
  }

  CompanionDevicesCompanion toCompanion(bool nullToAbsent) {
    return CompanionDevicesCompanion(
      publicKeyHex: Value(publicKeyHex),
      name: Value(name),
      firstConnected: Value(firstConnected),
      lastConnected: Value(lastConnected),
      connectionCount: Value(connectionCount),
    );
  }

  factory CompanionDeviceData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompanionDeviceData(
      publicKeyHex: serializer.fromJson<String>(json['publicKeyHex']),
      name: serializer.fromJson<String>(json['name']),
      firstConnected: serializer.fromJson<int>(json['firstConnected']),
      lastConnected: serializer.fromJson<int>(json['lastConnected']),
      connectionCount: serializer.fromJson<int>(json['connectionCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'publicKeyHex': serializer.toJson<String>(publicKeyHex),
      'name': serializer.toJson<String>(name),
      'firstConnected': serializer.toJson<int>(firstConnected),
      'lastConnected': serializer.toJson<int>(lastConnected),
      'connectionCount': serializer.toJson<int>(connectionCount),
    };
  }

  CompanionDeviceData copyWith({
    String? publicKeyHex,
    String? name,
    int? firstConnected,
    int? lastConnected,
    int? connectionCount,
  }) => CompanionDeviceData(
    publicKeyHex: publicKeyHex ?? this.publicKeyHex,
    name: name ?? this.name,
    firstConnected: firstConnected ?? this.firstConnected,
    lastConnected: lastConnected ?? this.lastConnected,
    connectionCount: connectionCount ?? this.connectionCount,
  );
  CompanionDeviceData copyWithCompanion(CompanionDevicesCompanion data) {
    return CompanionDeviceData(
      publicKeyHex:
          data.publicKeyHex.present
              ? data.publicKeyHex.value
              : this.publicKeyHex,
      name: data.name.present ? data.name.value : this.name,
      firstConnected:
          data.firstConnected.present
              ? data.firstConnected.value
              : this.firstConnected,
      lastConnected:
          data.lastConnected.present
              ? data.lastConnected.value
              : this.lastConnected,
      connectionCount:
          data.connectionCount.present
              ? data.connectionCount.value
              : this.connectionCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompanionDeviceData(')
          ..write('publicKeyHex: $publicKeyHex, ')
          ..write('name: $name, ')
          ..write('firstConnected: $firstConnected, ')
          ..write('lastConnected: $lastConnected, ')
          ..write('connectionCount: $connectionCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    publicKeyHex,
    name,
    firstConnected,
    lastConnected,
    connectionCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompanionDeviceData &&
          other.publicKeyHex == this.publicKeyHex &&
          other.name == this.name &&
          other.firstConnected == this.firstConnected &&
          other.lastConnected == this.lastConnected &&
          other.connectionCount == this.connectionCount);
}

class CompanionDevicesCompanion extends UpdateCompanion<CompanionDeviceData> {
  final Value<String> publicKeyHex;
  final Value<String> name;
  final Value<int> firstConnected;
  final Value<int> lastConnected;
  final Value<int> connectionCount;
  final Value<int> rowid;
  const CompanionDevicesCompanion({
    this.publicKeyHex = const Value.absent(),
    this.name = const Value.absent(),
    this.firstConnected = const Value.absent(),
    this.lastConnected = const Value.absent(),
    this.connectionCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompanionDevicesCompanion.insert({
    required String publicKeyHex,
    required String name,
    required int firstConnected,
    required int lastConnected,
    this.connectionCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : publicKeyHex = Value(publicKeyHex),
       name = Value(name),
       firstConnected = Value(firstConnected),
       lastConnected = Value(lastConnected);
  static Insertable<CompanionDeviceData> custom({
    Expression<String>? publicKeyHex,
    Expression<String>? name,
    Expression<int>? firstConnected,
    Expression<int>? lastConnected,
    Expression<int>? connectionCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (publicKeyHex != null) 'public_key_hex': publicKeyHex,
      if (name != null) 'name': name,
      if (firstConnected != null) 'first_connected': firstConnected,
      if (lastConnected != null) 'last_connected': lastConnected,
      if (connectionCount != null) 'connection_count': connectionCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompanionDevicesCompanion copyWith({
    Value<String>? publicKeyHex,
    Value<String>? name,
    Value<int>? firstConnected,
    Value<int>? lastConnected,
    Value<int>? connectionCount,
    Value<int>? rowid,
  }) {
    return CompanionDevicesCompanion(
      publicKeyHex: publicKeyHex ?? this.publicKeyHex,
      name: name ?? this.name,
      firstConnected: firstConnected ?? this.firstConnected,
      lastConnected: lastConnected ?? this.lastConnected,
      connectionCount: connectionCount ?? this.connectionCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (publicKeyHex.present) {
      map['public_key_hex'] = Variable<String>(publicKeyHex.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (firstConnected.present) {
      map['first_connected'] = Variable<int>(firstConnected.value);
    }
    if (lastConnected.present) {
      map['last_connected'] = Variable<int>(lastConnected.value);
    }
    if (connectionCount.present) {
      map['connection_count'] = Variable<int>(connectionCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompanionDevicesCompanion(')
          ..write('publicKeyHex: $publicKeyHex, ')
          ..write('name: $name, ')
          ..write('firstConnected: $firstConnected, ')
          ..write('lastConnected: $lastConnected, ')
          ..write('connectionCount: $connectionCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeersTable extends Peers with TableInfo<$PeersTable, PeerData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _radioPublicKeyMeta = const VerificationMeta(
    'radioPublicKey',
  );
  @override
  late final GeneratedColumn<Uint8List> radioPublicKey =
      GeneratedColumn<Uint8List>(
        'radio_public_key',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      );
  static const VerificationMeta _radioKeyPrefixMeta = const VerificationMeta(
    'radioKeyPrefix',
  );
  @override
  late final GeneratedColumn<String> radioKeyPrefix = GeneratedColumn<String>(
    'radio_key_prefix',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appIdentityIdMeta = const VerificationMeta(
    'appIdentityId',
  );
  @override
  late final GeneratedColumn<String> appIdentityId = GeneratedColumn<String>(
    'app_identity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _radioNameMeta = const VerificationMeta(
    'radioName',
  );
  @override
  late final GeneratedColumn<String> radioName = GeneratedColumn<String>(
    'radio_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aliasMeta = const VerificationMeta('alias');
  @override
  late final GeneratedColumn<String> alias = GeneratedColumn<String>(
    'alias',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aliasUpdatedAtMeta = const VerificationMeta(
    'aliasUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> aliasUpdatedAt = GeneratedColumn<int>(
    'alias_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capFlagsMeta = const VerificationMeta(
    'capFlags',
  );
  @override
  late final GeneratedColumn<int> capFlags = GeneratedColumn<int>(
    'cap_flags',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capObservedAtMeta = const VerificationMeta(
    'capObservedAt',
  );
  @override
  late final GeneratedColumn<int> capObservedAt = GeneratedColumn<int>(
    'cap_observed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isTeamMemberMeta = const VerificationMeta(
    'isTeamMember',
  );
  @override
  late final GeneratedColumn<bool> isTeamMember = GeneratedColumn<bool>(
    'is_team_member',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_team_member" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastTeamChannelHashMeta =
      const VerificationMeta('lastTeamChannelHash');
  @override
  late final GeneratedColumn<int> lastTeamChannelHash = GeneratedColumn<int>(
    'last_team_channel_hash',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstSeenMeta = const VerificationMeta(
    'firstSeen',
  );
  @override
  late final GeneratedColumn<int> firstSeen = GeneratedColumn<int>(
    'first_seen',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenMeta = const VerificationMeta(
    'lastSeen',
  );
  @override
  late final GeneratedColumn<int> lastSeen = GeneratedColumn<int>(
    'last_seen',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    radioPublicKey,
    radioKeyPrefix,
    appIdentityId,
    radioName,
    alias,
    aliasUpdatedAt,
    capFlags,
    capObservedAt,
    isTeamMember,
    lastTeamChannelHash,
    firstSeen,
    lastSeen,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'peers';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeerData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('radio_public_key')) {
      context.handle(
        _radioPublicKeyMeta,
        radioPublicKey.isAcceptableOrUnknown(
          data['radio_public_key']!,
          _radioPublicKeyMeta,
        ),
      );
    }
    if (data.containsKey('radio_key_prefix')) {
      context.handle(
        _radioKeyPrefixMeta,
        radioKeyPrefix.isAcceptableOrUnknown(
          data['radio_key_prefix']!,
          _radioKeyPrefixMeta,
        ),
      );
    }
    if (data.containsKey('app_identity_id')) {
      context.handle(
        _appIdentityIdMeta,
        appIdentityId.isAcceptableOrUnknown(
          data['app_identity_id']!,
          _appIdentityIdMeta,
        ),
      );
    }
    if (data.containsKey('radio_name')) {
      context.handle(
        _radioNameMeta,
        radioName.isAcceptableOrUnknown(data['radio_name']!, _radioNameMeta),
      );
    }
    if (data.containsKey('alias')) {
      context.handle(
        _aliasMeta,
        alias.isAcceptableOrUnknown(data['alias']!, _aliasMeta),
      );
    }
    if (data.containsKey('alias_updated_at')) {
      context.handle(
        _aliasUpdatedAtMeta,
        aliasUpdatedAt.isAcceptableOrUnknown(
          data['alias_updated_at']!,
          _aliasUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('cap_flags')) {
      context.handle(
        _capFlagsMeta,
        capFlags.isAcceptableOrUnknown(data['cap_flags']!, _capFlagsMeta),
      );
    }
    if (data.containsKey('cap_observed_at')) {
      context.handle(
        _capObservedAtMeta,
        capObservedAt.isAcceptableOrUnknown(
          data['cap_observed_at']!,
          _capObservedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_team_member')) {
      context.handle(
        _isTeamMemberMeta,
        isTeamMember.isAcceptableOrUnknown(
          data['is_team_member']!,
          _isTeamMemberMeta,
        ),
      );
    }
    if (data.containsKey('last_team_channel_hash')) {
      context.handle(
        _lastTeamChannelHashMeta,
        lastTeamChannelHash.isAcceptableOrUnknown(
          data['last_team_channel_hash']!,
          _lastTeamChannelHashMeta,
        ),
      );
    }
    if (data.containsKey('first_seen')) {
      context.handle(
        _firstSeenMeta,
        firstSeen.isAcceptableOrUnknown(data['first_seen']!, _firstSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_firstSeenMeta);
    }
    if (data.containsKey('last_seen')) {
      context.handle(
        _lastSeenMeta,
        lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_lastSeenMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeerData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeerData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      radioPublicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}radio_public_key'],
      ),
      radioKeyPrefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}radio_key_prefix'],
      ),
      appIdentityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_identity_id'],
      ),
      radioName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}radio_name'],
      ),
      alias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alias'],
      ),
      aliasUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}alias_updated_at'],
      ),
      capFlags: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cap_flags'],
      ),
      capObservedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cap_observed_at'],
      ),
      isTeamMember:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_team_member'],
          )!,
      lastTeamChannelHash: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_team_channel_hash'],
      ),
      firstSeen:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}first_seen'],
          )!,
      lastSeen:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}last_seen'],
          )!,
    );
  }

  @override
  $PeersTable createAlias(String alias) {
    return $PeersTable(attachedDatabase, alias);
  }
}

class PeerData extends DataClass implements Insertable<PeerData> {
  final int id;
  final Uint8List? radioPublicKey;
  final String? radioKeyPrefix;
  final String? appIdentityId;
  final String? radioName;
  final String? alias;
  final int? aliasUpdatedAt;
  final int? capFlags;
  final int? capObservedAt;
  final bool isTeamMember;
  final int? lastTeamChannelHash;
  final int firstSeen;
  final int lastSeen;
  const PeerData({
    required this.id,
    this.radioPublicKey,
    this.radioKeyPrefix,
    this.appIdentityId,
    this.radioName,
    this.alias,
    this.aliasUpdatedAt,
    this.capFlags,
    this.capObservedAt,
    required this.isTeamMember,
    this.lastTeamChannelHash,
    required this.firstSeen,
    required this.lastSeen,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || radioPublicKey != null) {
      map['radio_public_key'] = Variable<Uint8List>(radioPublicKey);
    }
    if (!nullToAbsent || radioKeyPrefix != null) {
      map['radio_key_prefix'] = Variable<String>(radioKeyPrefix);
    }
    if (!nullToAbsent || appIdentityId != null) {
      map['app_identity_id'] = Variable<String>(appIdentityId);
    }
    if (!nullToAbsent || radioName != null) {
      map['radio_name'] = Variable<String>(radioName);
    }
    if (!nullToAbsent || alias != null) {
      map['alias'] = Variable<String>(alias);
    }
    if (!nullToAbsent || aliasUpdatedAt != null) {
      map['alias_updated_at'] = Variable<int>(aliasUpdatedAt);
    }
    if (!nullToAbsent || capFlags != null) {
      map['cap_flags'] = Variable<int>(capFlags);
    }
    if (!nullToAbsent || capObservedAt != null) {
      map['cap_observed_at'] = Variable<int>(capObservedAt);
    }
    map['is_team_member'] = Variable<bool>(isTeamMember);
    if (!nullToAbsent || lastTeamChannelHash != null) {
      map['last_team_channel_hash'] = Variable<int>(lastTeamChannelHash);
    }
    map['first_seen'] = Variable<int>(firstSeen);
    map['last_seen'] = Variable<int>(lastSeen);
    return map;
  }

  PeersCompanion toCompanion(bool nullToAbsent) {
    return PeersCompanion(
      id: Value(id),
      radioPublicKey:
          radioPublicKey == null && nullToAbsent
              ? const Value.absent()
              : Value(radioPublicKey),
      radioKeyPrefix:
          radioKeyPrefix == null && nullToAbsent
              ? const Value.absent()
              : Value(radioKeyPrefix),
      appIdentityId:
          appIdentityId == null && nullToAbsent
              ? const Value.absent()
              : Value(appIdentityId),
      radioName:
          radioName == null && nullToAbsent
              ? const Value.absent()
              : Value(radioName),
      alias:
          alias == null && nullToAbsent ? const Value.absent() : Value(alias),
      aliasUpdatedAt:
          aliasUpdatedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(aliasUpdatedAt),
      capFlags:
          capFlags == null && nullToAbsent
              ? const Value.absent()
              : Value(capFlags),
      capObservedAt:
          capObservedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(capObservedAt),
      isTeamMember: Value(isTeamMember),
      lastTeamChannelHash:
          lastTeamChannelHash == null && nullToAbsent
              ? const Value.absent()
              : Value(lastTeamChannelHash),
      firstSeen: Value(firstSeen),
      lastSeen: Value(lastSeen),
    );
  }

  factory PeerData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeerData(
      id: serializer.fromJson<int>(json['id']),
      radioPublicKey: serializer.fromJson<Uint8List?>(json['radioPublicKey']),
      radioKeyPrefix: serializer.fromJson<String?>(json['radioKeyPrefix']),
      appIdentityId: serializer.fromJson<String?>(json['appIdentityId']),
      radioName: serializer.fromJson<String?>(json['radioName']),
      alias: serializer.fromJson<String?>(json['alias']),
      aliasUpdatedAt: serializer.fromJson<int?>(json['aliasUpdatedAt']),
      capFlags: serializer.fromJson<int?>(json['capFlags']),
      capObservedAt: serializer.fromJson<int?>(json['capObservedAt']),
      isTeamMember: serializer.fromJson<bool>(json['isTeamMember']),
      lastTeamChannelHash: serializer.fromJson<int?>(
        json['lastTeamChannelHash'],
      ),
      firstSeen: serializer.fromJson<int>(json['firstSeen']),
      lastSeen: serializer.fromJson<int>(json['lastSeen']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'radioPublicKey': serializer.toJson<Uint8List?>(radioPublicKey),
      'radioKeyPrefix': serializer.toJson<String?>(radioKeyPrefix),
      'appIdentityId': serializer.toJson<String?>(appIdentityId),
      'radioName': serializer.toJson<String?>(radioName),
      'alias': serializer.toJson<String?>(alias),
      'aliasUpdatedAt': serializer.toJson<int?>(aliasUpdatedAt),
      'capFlags': serializer.toJson<int?>(capFlags),
      'capObservedAt': serializer.toJson<int?>(capObservedAt),
      'isTeamMember': serializer.toJson<bool>(isTeamMember),
      'lastTeamChannelHash': serializer.toJson<int?>(lastTeamChannelHash),
      'firstSeen': serializer.toJson<int>(firstSeen),
      'lastSeen': serializer.toJson<int>(lastSeen),
    };
  }

  PeerData copyWith({
    int? id,
    Value<Uint8List?> radioPublicKey = const Value.absent(),
    Value<String?> radioKeyPrefix = const Value.absent(),
    Value<String?> appIdentityId = const Value.absent(),
    Value<String?> radioName = const Value.absent(),
    Value<String?> alias = const Value.absent(),
    Value<int?> aliasUpdatedAt = const Value.absent(),
    Value<int?> capFlags = const Value.absent(),
    Value<int?> capObservedAt = const Value.absent(),
    bool? isTeamMember,
    Value<int?> lastTeamChannelHash = const Value.absent(),
    int? firstSeen,
    int? lastSeen,
  }) => PeerData(
    id: id ?? this.id,
    radioPublicKey:
        radioPublicKey.present ? radioPublicKey.value : this.radioPublicKey,
    radioKeyPrefix:
        radioKeyPrefix.present ? radioKeyPrefix.value : this.radioKeyPrefix,
    appIdentityId:
        appIdentityId.present ? appIdentityId.value : this.appIdentityId,
    radioName: radioName.present ? radioName.value : this.radioName,
    alias: alias.present ? alias.value : this.alias,
    aliasUpdatedAt:
        aliasUpdatedAt.present ? aliasUpdatedAt.value : this.aliasUpdatedAt,
    capFlags: capFlags.present ? capFlags.value : this.capFlags,
    capObservedAt:
        capObservedAt.present ? capObservedAt.value : this.capObservedAt,
    isTeamMember: isTeamMember ?? this.isTeamMember,
    lastTeamChannelHash:
        lastTeamChannelHash.present
            ? lastTeamChannelHash.value
            : this.lastTeamChannelHash,
    firstSeen: firstSeen ?? this.firstSeen,
    lastSeen: lastSeen ?? this.lastSeen,
  );
  PeerData copyWithCompanion(PeersCompanion data) {
    return PeerData(
      id: data.id.present ? data.id.value : this.id,
      radioPublicKey:
          data.radioPublicKey.present
              ? data.radioPublicKey.value
              : this.radioPublicKey,
      radioKeyPrefix:
          data.radioKeyPrefix.present
              ? data.radioKeyPrefix.value
              : this.radioKeyPrefix,
      appIdentityId:
          data.appIdentityId.present
              ? data.appIdentityId.value
              : this.appIdentityId,
      radioName: data.radioName.present ? data.radioName.value : this.radioName,
      alias: data.alias.present ? data.alias.value : this.alias,
      aliasUpdatedAt:
          data.aliasUpdatedAt.present
              ? data.aliasUpdatedAt.value
              : this.aliasUpdatedAt,
      capFlags: data.capFlags.present ? data.capFlags.value : this.capFlags,
      capObservedAt:
          data.capObservedAt.present
              ? data.capObservedAt.value
              : this.capObservedAt,
      isTeamMember:
          data.isTeamMember.present
              ? data.isTeamMember.value
              : this.isTeamMember,
      lastTeamChannelHash:
          data.lastTeamChannelHash.present
              ? data.lastTeamChannelHash.value
              : this.lastTeamChannelHash,
      firstSeen: data.firstSeen.present ? data.firstSeen.value : this.firstSeen,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeerData(')
          ..write('id: $id, ')
          ..write('radioPublicKey: $radioPublicKey, ')
          ..write('radioKeyPrefix: $radioKeyPrefix, ')
          ..write('appIdentityId: $appIdentityId, ')
          ..write('radioName: $radioName, ')
          ..write('alias: $alias, ')
          ..write('aliasUpdatedAt: $aliasUpdatedAt, ')
          ..write('capFlags: $capFlags, ')
          ..write('capObservedAt: $capObservedAt, ')
          ..write('isTeamMember: $isTeamMember, ')
          ..write('lastTeamChannelHash: $lastTeamChannelHash, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('lastSeen: $lastSeen')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    $driftBlobEquality.hash(radioPublicKey),
    radioKeyPrefix,
    appIdentityId,
    radioName,
    alias,
    aliasUpdatedAt,
    capFlags,
    capObservedAt,
    isTeamMember,
    lastTeamChannelHash,
    firstSeen,
    lastSeen,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeerData &&
          other.id == this.id &&
          $driftBlobEquality.equals(
            other.radioPublicKey,
            this.radioPublicKey,
          ) &&
          other.radioKeyPrefix == this.radioKeyPrefix &&
          other.appIdentityId == this.appIdentityId &&
          other.radioName == this.radioName &&
          other.alias == this.alias &&
          other.aliasUpdatedAt == this.aliasUpdatedAt &&
          other.capFlags == this.capFlags &&
          other.capObservedAt == this.capObservedAt &&
          other.isTeamMember == this.isTeamMember &&
          other.lastTeamChannelHash == this.lastTeamChannelHash &&
          other.firstSeen == this.firstSeen &&
          other.lastSeen == this.lastSeen);
}

class PeersCompanion extends UpdateCompanion<PeerData> {
  final Value<int> id;
  final Value<Uint8List?> radioPublicKey;
  final Value<String?> radioKeyPrefix;
  final Value<String?> appIdentityId;
  final Value<String?> radioName;
  final Value<String?> alias;
  final Value<int?> aliasUpdatedAt;
  final Value<int?> capFlags;
  final Value<int?> capObservedAt;
  final Value<bool> isTeamMember;
  final Value<int?> lastTeamChannelHash;
  final Value<int> firstSeen;
  final Value<int> lastSeen;
  const PeersCompanion({
    this.id = const Value.absent(),
    this.radioPublicKey = const Value.absent(),
    this.radioKeyPrefix = const Value.absent(),
    this.appIdentityId = const Value.absent(),
    this.radioName = const Value.absent(),
    this.alias = const Value.absent(),
    this.aliasUpdatedAt = const Value.absent(),
    this.capFlags = const Value.absent(),
    this.capObservedAt = const Value.absent(),
    this.isTeamMember = const Value.absent(),
    this.lastTeamChannelHash = const Value.absent(),
    this.firstSeen = const Value.absent(),
    this.lastSeen = const Value.absent(),
  });
  PeersCompanion.insert({
    this.id = const Value.absent(),
    this.radioPublicKey = const Value.absent(),
    this.radioKeyPrefix = const Value.absent(),
    this.appIdentityId = const Value.absent(),
    this.radioName = const Value.absent(),
    this.alias = const Value.absent(),
    this.aliasUpdatedAt = const Value.absent(),
    this.capFlags = const Value.absent(),
    this.capObservedAt = const Value.absent(),
    this.isTeamMember = const Value.absent(),
    this.lastTeamChannelHash = const Value.absent(),
    required int firstSeen,
    required int lastSeen,
  }) : firstSeen = Value(firstSeen),
       lastSeen = Value(lastSeen);
  static Insertable<PeerData> custom({
    Expression<int>? id,
    Expression<Uint8List>? radioPublicKey,
    Expression<String>? radioKeyPrefix,
    Expression<String>? appIdentityId,
    Expression<String>? radioName,
    Expression<String>? alias,
    Expression<int>? aliasUpdatedAt,
    Expression<int>? capFlags,
    Expression<int>? capObservedAt,
    Expression<bool>? isTeamMember,
    Expression<int>? lastTeamChannelHash,
    Expression<int>? firstSeen,
    Expression<int>? lastSeen,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (radioPublicKey != null) 'radio_public_key': radioPublicKey,
      if (radioKeyPrefix != null) 'radio_key_prefix': radioKeyPrefix,
      if (appIdentityId != null) 'app_identity_id': appIdentityId,
      if (radioName != null) 'radio_name': radioName,
      if (alias != null) 'alias': alias,
      if (aliasUpdatedAt != null) 'alias_updated_at': aliasUpdatedAt,
      if (capFlags != null) 'cap_flags': capFlags,
      if (capObservedAt != null) 'cap_observed_at': capObservedAt,
      if (isTeamMember != null) 'is_team_member': isTeamMember,
      if (lastTeamChannelHash != null)
        'last_team_channel_hash': lastTeamChannelHash,
      if (firstSeen != null) 'first_seen': firstSeen,
      if (lastSeen != null) 'last_seen': lastSeen,
    });
  }

  PeersCompanion copyWith({
    Value<int>? id,
    Value<Uint8List?>? radioPublicKey,
    Value<String?>? radioKeyPrefix,
    Value<String?>? appIdentityId,
    Value<String?>? radioName,
    Value<String?>? alias,
    Value<int?>? aliasUpdatedAt,
    Value<int?>? capFlags,
    Value<int?>? capObservedAt,
    Value<bool>? isTeamMember,
    Value<int?>? lastTeamChannelHash,
    Value<int>? firstSeen,
    Value<int>? lastSeen,
  }) {
    return PeersCompanion(
      id: id ?? this.id,
      radioPublicKey: radioPublicKey ?? this.radioPublicKey,
      radioKeyPrefix: radioKeyPrefix ?? this.radioKeyPrefix,
      appIdentityId: appIdentityId ?? this.appIdentityId,
      radioName: radioName ?? this.radioName,
      alias: alias ?? this.alias,
      aliasUpdatedAt: aliasUpdatedAt ?? this.aliasUpdatedAt,
      capFlags: capFlags ?? this.capFlags,
      capObservedAt: capObservedAt ?? this.capObservedAt,
      isTeamMember: isTeamMember ?? this.isTeamMember,
      lastTeamChannelHash: lastTeamChannelHash ?? this.lastTeamChannelHash,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (radioPublicKey.present) {
      map['radio_public_key'] = Variable<Uint8List>(radioPublicKey.value);
    }
    if (radioKeyPrefix.present) {
      map['radio_key_prefix'] = Variable<String>(radioKeyPrefix.value);
    }
    if (appIdentityId.present) {
      map['app_identity_id'] = Variable<String>(appIdentityId.value);
    }
    if (radioName.present) {
      map['radio_name'] = Variable<String>(radioName.value);
    }
    if (alias.present) {
      map['alias'] = Variable<String>(alias.value);
    }
    if (aliasUpdatedAt.present) {
      map['alias_updated_at'] = Variable<int>(aliasUpdatedAt.value);
    }
    if (capFlags.present) {
      map['cap_flags'] = Variable<int>(capFlags.value);
    }
    if (capObservedAt.present) {
      map['cap_observed_at'] = Variable<int>(capObservedAt.value);
    }
    if (isTeamMember.present) {
      map['is_team_member'] = Variable<bool>(isTeamMember.value);
    }
    if (lastTeamChannelHash.present) {
      map['last_team_channel_hash'] = Variable<int>(lastTeamChannelHash.value);
    }
    if (firstSeen.present) {
      map['first_seen'] = Variable<int>(firstSeen.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<int>(lastSeen.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeersCompanion(')
          ..write('id: $id, ')
          ..write('radioPublicKey: $radioPublicKey, ')
          ..write('radioKeyPrefix: $radioKeyPrefix, ')
          ..write('appIdentityId: $appIdentityId, ')
          ..write('radioName: $radioName, ')
          ..write('alias: $alias, ')
          ..write('aliasUpdatedAt: $aliasUpdatedAt, ')
          ..write('capFlags: $capFlags, ')
          ..write('capObservedAt: $capObservedAt, ')
          ..write('isTeamMember: $isTeamMember, ')
          ..write('lastTeamChannelHash: $lastTeamChannelHash, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('lastSeen: $lastSeen')
          ..write(')'))
        .toString();
  }
}

class $PeerLocationsTable extends PeerLocations
    with TableInfo<$PeerLocationsTable, PeerLocationData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeerLocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _peerIdMeta = const VerificationMeta('peerId');
  @override
  late final GeneratedColumn<int> peerId = GeneratedColumn<int>(
    'peer_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES peers (id)',
    ),
  );
  static const VerificationMeta _lastSeenMeta = const VerificationMeta(
    'lastSeen',
  );
  @override
  late final GeneratedColumn<int> lastSeen = GeneratedColumn<int>(
    'last_seen',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastLatitudeMeta = const VerificationMeta(
    'lastLatitude',
  );
  @override
  late final GeneratedColumn<double> lastLatitude = GeneratedColumn<double>(
    'last_latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastLongitudeMeta = const VerificationMeta(
    'lastLongitude',
  );
  @override
  late final GeneratedColumn<double> lastLongitude = GeneratedColumn<double>(
    'last_longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastChannelHashMeta = const VerificationMeta(
    'lastChannelHash',
  );
  @override
  late final GeneratedColumn<int> lastChannelHash = GeneratedColumn<int>(
    'last_channel_hash',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPathLenMeta = const VerificationMeta(
    'lastPathLen',
  );
  @override
  late final GeneratedColumn<int> lastPathLen = GeneratedColumn<int>(
    'last_path_len',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companionBatteryMilliVoltsMeta =
      const VerificationMeta('companionBatteryMilliVolts');
  @override
  late final GeneratedColumn<int> companionBatteryMilliVolts =
      GeneratedColumn<int>(
        'companion_battery_milli_volts',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _phoneBatteryMilliVoltsMeta =
      const VerificationMeta('phoneBatteryMilliVolts');
  @override
  late final GeneratedColumn<int> phoneBatteryMilliVolts = GeneratedColumn<int>(
    'phone_battery_milli_volts',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAutonomousDeviceMeta =
      const VerificationMeta('isAutonomousDevice');
  @override
  late final GeneratedColumn<bool> isAutonomousDevice = GeneratedColumn<bool>(
    'is_autonomous_device',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_autonomous_device" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isManuallyHiddenMeta = const VerificationMeta(
    'isManuallyHidden',
  );
  @override
  late final GeneratedColumn<bool> isManuallyHidden = GeneratedColumn<bool>(
    'is_manually_hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_manually_hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hiddenAtMeta = const VerificationMeta(
    'hiddenAt',
  );
  @override
  late final GeneratedColumn<int> hiddenAt = GeneratedColumn<int>(
    'hidden_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstSeenMeta = const VerificationMeta(
    'firstSeen',
  );
  @override
  late final GeneratedColumn<int> firstSeen = GeneratedColumn<int>(
    'first_seen',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalTelemetryReceivedMeta =
      const VerificationMeta('totalTelemetryReceived');
  @override
  late final GeneratedColumn<int> totalTelemetryReceived = GeneratedColumn<int>(
    'total_telemetry_received',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    peerId,
    lastSeen,
    lastLatitude,
    lastLongitude,
    lastChannelHash,
    lastPathLen,
    companionBatteryMilliVolts,
    phoneBatteryMilliVolts,
    isAutonomousDevice,
    isManuallyHidden,
    hiddenAt,
    firstSeen,
    totalTelemetryReceived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'peer_locations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeerLocationData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('peer_id')) {
      context.handle(
        _peerIdMeta,
        peerId.isAcceptableOrUnknown(data['peer_id']!, _peerIdMeta),
      );
    }
    if (data.containsKey('last_seen')) {
      context.handle(
        _lastSeenMeta,
        lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_lastSeenMeta);
    }
    if (data.containsKey('last_latitude')) {
      context.handle(
        _lastLatitudeMeta,
        lastLatitude.isAcceptableOrUnknown(
          data['last_latitude']!,
          _lastLatitudeMeta,
        ),
      );
    }
    if (data.containsKey('last_longitude')) {
      context.handle(
        _lastLongitudeMeta,
        lastLongitude.isAcceptableOrUnknown(
          data['last_longitude']!,
          _lastLongitudeMeta,
        ),
      );
    }
    if (data.containsKey('last_channel_hash')) {
      context.handle(
        _lastChannelHashMeta,
        lastChannelHash.isAcceptableOrUnknown(
          data['last_channel_hash']!,
          _lastChannelHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastChannelHashMeta);
    }
    if (data.containsKey('last_path_len')) {
      context.handle(
        _lastPathLenMeta,
        lastPathLen.isAcceptableOrUnknown(
          data['last_path_len']!,
          _lastPathLenMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastPathLenMeta);
    }
    if (data.containsKey('companion_battery_milli_volts')) {
      context.handle(
        _companionBatteryMilliVoltsMeta,
        companionBatteryMilliVolts.isAcceptableOrUnknown(
          data['companion_battery_milli_volts']!,
          _companionBatteryMilliVoltsMeta,
        ),
      );
    }
    if (data.containsKey('phone_battery_milli_volts')) {
      context.handle(
        _phoneBatteryMilliVoltsMeta,
        phoneBatteryMilliVolts.isAcceptableOrUnknown(
          data['phone_battery_milli_volts']!,
          _phoneBatteryMilliVoltsMeta,
        ),
      );
    }
    if (data.containsKey('is_autonomous_device')) {
      context.handle(
        _isAutonomousDeviceMeta,
        isAutonomousDevice.isAcceptableOrUnknown(
          data['is_autonomous_device']!,
          _isAutonomousDeviceMeta,
        ),
      );
    }
    if (data.containsKey('is_manually_hidden')) {
      context.handle(
        _isManuallyHiddenMeta,
        isManuallyHidden.isAcceptableOrUnknown(
          data['is_manually_hidden']!,
          _isManuallyHiddenMeta,
        ),
      );
    }
    if (data.containsKey('hidden_at')) {
      context.handle(
        _hiddenAtMeta,
        hiddenAt.isAcceptableOrUnknown(data['hidden_at']!, _hiddenAtMeta),
      );
    }
    if (data.containsKey('first_seen')) {
      context.handle(
        _firstSeenMeta,
        firstSeen.isAcceptableOrUnknown(data['first_seen']!, _firstSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_firstSeenMeta);
    }
    if (data.containsKey('total_telemetry_received')) {
      context.handle(
        _totalTelemetryReceivedMeta,
        totalTelemetryReceived.isAcceptableOrUnknown(
          data['total_telemetry_received']!,
          _totalTelemetryReceivedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {peerId};
  @override
  PeerLocationData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeerLocationData(
      peerId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}peer_id'],
          )!,
      lastSeen:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}last_seen'],
          )!,
      lastLatitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}last_latitude'],
      ),
      lastLongitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}last_longitude'],
      ),
      lastChannelHash:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}last_channel_hash'],
          )!,
      lastPathLen:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}last_path_len'],
          )!,
      companionBatteryMilliVolts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}companion_battery_milli_volts'],
      ),
      phoneBatteryMilliVolts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}phone_battery_milli_volts'],
      ),
      isAutonomousDevice:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_autonomous_device'],
          )!,
      isManuallyHidden:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_manually_hidden'],
          )!,
      hiddenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hidden_at'],
      ),
      firstSeen:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}first_seen'],
          )!,
      totalTelemetryReceived:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}total_telemetry_received'],
          )!,
    );
  }

  @override
  $PeerLocationsTable createAlias(String alias) {
    return $PeerLocationsTable(attachedDatabase, alias);
  }
}

class PeerLocationData extends DataClass
    implements Insertable<PeerLocationData> {
  final int peerId;
  final int lastSeen;
  final double? lastLatitude;
  final double? lastLongitude;
  final int lastChannelHash;
  final int lastPathLen;
  final int? companionBatteryMilliVolts;
  final int? phoneBatteryMilliVolts;
  final bool isAutonomousDevice;
  final bool isManuallyHidden;
  final int? hiddenAt;
  final int firstSeen;
  final int totalTelemetryReceived;
  const PeerLocationData({
    required this.peerId,
    required this.lastSeen,
    this.lastLatitude,
    this.lastLongitude,
    required this.lastChannelHash,
    required this.lastPathLen,
    this.companionBatteryMilliVolts,
    this.phoneBatteryMilliVolts,
    required this.isAutonomousDevice,
    required this.isManuallyHidden,
    this.hiddenAt,
    required this.firstSeen,
    required this.totalTelemetryReceived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['peer_id'] = Variable<int>(peerId);
    map['last_seen'] = Variable<int>(lastSeen);
    if (!nullToAbsent || lastLatitude != null) {
      map['last_latitude'] = Variable<double>(lastLatitude);
    }
    if (!nullToAbsent || lastLongitude != null) {
      map['last_longitude'] = Variable<double>(lastLongitude);
    }
    map['last_channel_hash'] = Variable<int>(lastChannelHash);
    map['last_path_len'] = Variable<int>(lastPathLen);
    if (!nullToAbsent || companionBatteryMilliVolts != null) {
      map['companion_battery_milli_volts'] = Variable<int>(
        companionBatteryMilliVolts,
      );
    }
    if (!nullToAbsent || phoneBatteryMilliVolts != null) {
      map['phone_battery_milli_volts'] = Variable<int>(phoneBatteryMilliVolts);
    }
    map['is_autonomous_device'] = Variable<bool>(isAutonomousDevice);
    map['is_manually_hidden'] = Variable<bool>(isManuallyHidden);
    if (!nullToAbsent || hiddenAt != null) {
      map['hidden_at'] = Variable<int>(hiddenAt);
    }
    map['first_seen'] = Variable<int>(firstSeen);
    map['total_telemetry_received'] = Variable<int>(totalTelemetryReceived);
    return map;
  }

  PeerLocationsCompanion toCompanion(bool nullToAbsent) {
    return PeerLocationsCompanion(
      peerId: Value(peerId),
      lastSeen: Value(lastSeen),
      lastLatitude:
          lastLatitude == null && nullToAbsent
              ? const Value.absent()
              : Value(lastLatitude),
      lastLongitude:
          lastLongitude == null && nullToAbsent
              ? const Value.absent()
              : Value(lastLongitude),
      lastChannelHash: Value(lastChannelHash),
      lastPathLen: Value(lastPathLen),
      companionBatteryMilliVolts:
          companionBatteryMilliVolts == null && nullToAbsent
              ? const Value.absent()
              : Value(companionBatteryMilliVolts),
      phoneBatteryMilliVolts:
          phoneBatteryMilliVolts == null && nullToAbsent
              ? const Value.absent()
              : Value(phoneBatteryMilliVolts),
      isAutonomousDevice: Value(isAutonomousDevice),
      isManuallyHidden: Value(isManuallyHidden),
      hiddenAt:
          hiddenAt == null && nullToAbsent
              ? const Value.absent()
              : Value(hiddenAt),
      firstSeen: Value(firstSeen),
      totalTelemetryReceived: Value(totalTelemetryReceived),
    );
  }

  factory PeerLocationData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeerLocationData(
      peerId: serializer.fromJson<int>(json['peerId']),
      lastSeen: serializer.fromJson<int>(json['lastSeen']),
      lastLatitude: serializer.fromJson<double?>(json['lastLatitude']),
      lastLongitude: serializer.fromJson<double?>(json['lastLongitude']),
      lastChannelHash: serializer.fromJson<int>(json['lastChannelHash']),
      lastPathLen: serializer.fromJson<int>(json['lastPathLen']),
      companionBatteryMilliVolts: serializer.fromJson<int?>(
        json['companionBatteryMilliVolts'],
      ),
      phoneBatteryMilliVolts: serializer.fromJson<int?>(
        json['phoneBatteryMilliVolts'],
      ),
      isAutonomousDevice: serializer.fromJson<bool>(json['isAutonomousDevice']),
      isManuallyHidden: serializer.fromJson<bool>(json['isManuallyHidden']),
      hiddenAt: serializer.fromJson<int?>(json['hiddenAt']),
      firstSeen: serializer.fromJson<int>(json['firstSeen']),
      totalTelemetryReceived: serializer.fromJson<int>(
        json['totalTelemetryReceived'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'peerId': serializer.toJson<int>(peerId),
      'lastSeen': serializer.toJson<int>(lastSeen),
      'lastLatitude': serializer.toJson<double?>(lastLatitude),
      'lastLongitude': serializer.toJson<double?>(lastLongitude),
      'lastChannelHash': serializer.toJson<int>(lastChannelHash),
      'lastPathLen': serializer.toJson<int>(lastPathLen),
      'companionBatteryMilliVolts': serializer.toJson<int?>(
        companionBatteryMilliVolts,
      ),
      'phoneBatteryMilliVolts': serializer.toJson<int?>(phoneBatteryMilliVolts),
      'isAutonomousDevice': serializer.toJson<bool>(isAutonomousDevice),
      'isManuallyHidden': serializer.toJson<bool>(isManuallyHidden),
      'hiddenAt': serializer.toJson<int?>(hiddenAt),
      'firstSeen': serializer.toJson<int>(firstSeen),
      'totalTelemetryReceived': serializer.toJson<int>(totalTelemetryReceived),
    };
  }

  PeerLocationData copyWith({
    int? peerId,
    int? lastSeen,
    Value<double?> lastLatitude = const Value.absent(),
    Value<double?> lastLongitude = const Value.absent(),
    int? lastChannelHash,
    int? lastPathLen,
    Value<int?> companionBatteryMilliVolts = const Value.absent(),
    Value<int?> phoneBatteryMilliVolts = const Value.absent(),
    bool? isAutonomousDevice,
    bool? isManuallyHidden,
    Value<int?> hiddenAt = const Value.absent(),
    int? firstSeen,
    int? totalTelemetryReceived,
  }) => PeerLocationData(
    peerId: peerId ?? this.peerId,
    lastSeen: lastSeen ?? this.lastSeen,
    lastLatitude: lastLatitude.present ? lastLatitude.value : this.lastLatitude,
    lastLongitude:
        lastLongitude.present ? lastLongitude.value : this.lastLongitude,
    lastChannelHash: lastChannelHash ?? this.lastChannelHash,
    lastPathLen: lastPathLen ?? this.lastPathLen,
    companionBatteryMilliVolts:
        companionBatteryMilliVolts.present
            ? companionBatteryMilliVolts.value
            : this.companionBatteryMilliVolts,
    phoneBatteryMilliVolts:
        phoneBatteryMilliVolts.present
            ? phoneBatteryMilliVolts.value
            : this.phoneBatteryMilliVolts,
    isAutonomousDevice: isAutonomousDevice ?? this.isAutonomousDevice,
    isManuallyHidden: isManuallyHidden ?? this.isManuallyHidden,
    hiddenAt: hiddenAt.present ? hiddenAt.value : this.hiddenAt,
    firstSeen: firstSeen ?? this.firstSeen,
    totalTelemetryReceived:
        totalTelemetryReceived ?? this.totalTelemetryReceived,
  );
  PeerLocationData copyWithCompanion(PeerLocationsCompanion data) {
    return PeerLocationData(
      peerId: data.peerId.present ? data.peerId.value : this.peerId,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
      lastLatitude:
          data.lastLatitude.present
              ? data.lastLatitude.value
              : this.lastLatitude,
      lastLongitude:
          data.lastLongitude.present
              ? data.lastLongitude.value
              : this.lastLongitude,
      lastChannelHash:
          data.lastChannelHash.present
              ? data.lastChannelHash.value
              : this.lastChannelHash,
      lastPathLen:
          data.lastPathLen.present ? data.lastPathLen.value : this.lastPathLen,
      companionBatteryMilliVolts:
          data.companionBatteryMilliVolts.present
              ? data.companionBatteryMilliVolts.value
              : this.companionBatteryMilliVolts,
      phoneBatteryMilliVolts:
          data.phoneBatteryMilliVolts.present
              ? data.phoneBatteryMilliVolts.value
              : this.phoneBatteryMilliVolts,
      isAutonomousDevice:
          data.isAutonomousDevice.present
              ? data.isAutonomousDevice.value
              : this.isAutonomousDevice,
      isManuallyHidden:
          data.isManuallyHidden.present
              ? data.isManuallyHidden.value
              : this.isManuallyHidden,
      hiddenAt: data.hiddenAt.present ? data.hiddenAt.value : this.hiddenAt,
      firstSeen: data.firstSeen.present ? data.firstSeen.value : this.firstSeen,
      totalTelemetryReceived:
          data.totalTelemetryReceived.present
              ? data.totalTelemetryReceived.value
              : this.totalTelemetryReceived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeerLocationData(')
          ..write('peerId: $peerId, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('lastLatitude: $lastLatitude, ')
          ..write('lastLongitude: $lastLongitude, ')
          ..write('lastChannelHash: $lastChannelHash, ')
          ..write('lastPathLen: $lastPathLen, ')
          ..write('companionBatteryMilliVolts: $companionBatteryMilliVolts, ')
          ..write('phoneBatteryMilliVolts: $phoneBatteryMilliVolts, ')
          ..write('isAutonomousDevice: $isAutonomousDevice, ')
          ..write('isManuallyHidden: $isManuallyHidden, ')
          ..write('hiddenAt: $hiddenAt, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('totalTelemetryReceived: $totalTelemetryReceived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    peerId,
    lastSeen,
    lastLatitude,
    lastLongitude,
    lastChannelHash,
    lastPathLen,
    companionBatteryMilliVolts,
    phoneBatteryMilliVolts,
    isAutonomousDevice,
    isManuallyHidden,
    hiddenAt,
    firstSeen,
    totalTelemetryReceived,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeerLocationData &&
          other.peerId == this.peerId &&
          other.lastSeen == this.lastSeen &&
          other.lastLatitude == this.lastLatitude &&
          other.lastLongitude == this.lastLongitude &&
          other.lastChannelHash == this.lastChannelHash &&
          other.lastPathLen == this.lastPathLen &&
          other.companionBatteryMilliVolts == this.companionBatteryMilliVolts &&
          other.phoneBatteryMilliVolts == this.phoneBatteryMilliVolts &&
          other.isAutonomousDevice == this.isAutonomousDevice &&
          other.isManuallyHidden == this.isManuallyHidden &&
          other.hiddenAt == this.hiddenAt &&
          other.firstSeen == this.firstSeen &&
          other.totalTelemetryReceived == this.totalTelemetryReceived);
}

class PeerLocationsCompanion extends UpdateCompanion<PeerLocationData> {
  final Value<int> peerId;
  final Value<int> lastSeen;
  final Value<double?> lastLatitude;
  final Value<double?> lastLongitude;
  final Value<int> lastChannelHash;
  final Value<int> lastPathLen;
  final Value<int?> companionBatteryMilliVolts;
  final Value<int?> phoneBatteryMilliVolts;
  final Value<bool> isAutonomousDevice;
  final Value<bool> isManuallyHidden;
  final Value<int?> hiddenAt;
  final Value<int> firstSeen;
  final Value<int> totalTelemetryReceived;
  const PeerLocationsCompanion({
    this.peerId = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.lastLatitude = const Value.absent(),
    this.lastLongitude = const Value.absent(),
    this.lastChannelHash = const Value.absent(),
    this.lastPathLen = const Value.absent(),
    this.companionBatteryMilliVolts = const Value.absent(),
    this.phoneBatteryMilliVolts = const Value.absent(),
    this.isAutonomousDevice = const Value.absent(),
    this.isManuallyHidden = const Value.absent(),
    this.hiddenAt = const Value.absent(),
    this.firstSeen = const Value.absent(),
    this.totalTelemetryReceived = const Value.absent(),
  });
  PeerLocationsCompanion.insert({
    this.peerId = const Value.absent(),
    required int lastSeen,
    this.lastLatitude = const Value.absent(),
    this.lastLongitude = const Value.absent(),
    required int lastChannelHash,
    required int lastPathLen,
    this.companionBatteryMilliVolts = const Value.absent(),
    this.phoneBatteryMilliVolts = const Value.absent(),
    this.isAutonomousDevice = const Value.absent(),
    this.isManuallyHidden = const Value.absent(),
    this.hiddenAt = const Value.absent(),
    required int firstSeen,
    this.totalTelemetryReceived = const Value.absent(),
  }) : lastSeen = Value(lastSeen),
       lastChannelHash = Value(lastChannelHash),
       lastPathLen = Value(lastPathLen),
       firstSeen = Value(firstSeen);
  static Insertable<PeerLocationData> custom({
    Expression<int>? peerId,
    Expression<int>? lastSeen,
    Expression<double>? lastLatitude,
    Expression<double>? lastLongitude,
    Expression<int>? lastChannelHash,
    Expression<int>? lastPathLen,
    Expression<int>? companionBatteryMilliVolts,
    Expression<int>? phoneBatteryMilliVolts,
    Expression<bool>? isAutonomousDevice,
    Expression<bool>? isManuallyHidden,
    Expression<int>? hiddenAt,
    Expression<int>? firstSeen,
    Expression<int>? totalTelemetryReceived,
  }) {
    return RawValuesInsertable({
      if (peerId != null) 'peer_id': peerId,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (lastLatitude != null) 'last_latitude': lastLatitude,
      if (lastLongitude != null) 'last_longitude': lastLongitude,
      if (lastChannelHash != null) 'last_channel_hash': lastChannelHash,
      if (lastPathLen != null) 'last_path_len': lastPathLen,
      if (companionBatteryMilliVolts != null)
        'companion_battery_milli_volts': companionBatteryMilliVolts,
      if (phoneBatteryMilliVolts != null)
        'phone_battery_milli_volts': phoneBatteryMilliVolts,
      if (isAutonomousDevice != null)
        'is_autonomous_device': isAutonomousDevice,
      if (isManuallyHidden != null) 'is_manually_hidden': isManuallyHidden,
      if (hiddenAt != null) 'hidden_at': hiddenAt,
      if (firstSeen != null) 'first_seen': firstSeen,
      if (totalTelemetryReceived != null)
        'total_telemetry_received': totalTelemetryReceived,
    });
  }

  PeerLocationsCompanion copyWith({
    Value<int>? peerId,
    Value<int>? lastSeen,
    Value<double?>? lastLatitude,
    Value<double?>? lastLongitude,
    Value<int>? lastChannelHash,
    Value<int>? lastPathLen,
    Value<int?>? companionBatteryMilliVolts,
    Value<int?>? phoneBatteryMilliVolts,
    Value<bool>? isAutonomousDevice,
    Value<bool>? isManuallyHidden,
    Value<int?>? hiddenAt,
    Value<int>? firstSeen,
    Value<int>? totalTelemetryReceived,
  }) {
    return PeerLocationsCompanion(
      peerId: peerId ?? this.peerId,
      lastSeen: lastSeen ?? this.lastSeen,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      lastChannelHash: lastChannelHash ?? this.lastChannelHash,
      lastPathLen: lastPathLen ?? this.lastPathLen,
      companionBatteryMilliVolts:
          companionBatteryMilliVolts ?? this.companionBatteryMilliVolts,
      phoneBatteryMilliVolts:
          phoneBatteryMilliVolts ?? this.phoneBatteryMilliVolts,
      isAutonomousDevice: isAutonomousDevice ?? this.isAutonomousDevice,
      isManuallyHidden: isManuallyHidden ?? this.isManuallyHidden,
      hiddenAt: hiddenAt ?? this.hiddenAt,
      firstSeen: firstSeen ?? this.firstSeen,
      totalTelemetryReceived:
          totalTelemetryReceived ?? this.totalTelemetryReceived,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (peerId.present) {
      map['peer_id'] = Variable<int>(peerId.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<int>(lastSeen.value);
    }
    if (lastLatitude.present) {
      map['last_latitude'] = Variable<double>(lastLatitude.value);
    }
    if (lastLongitude.present) {
      map['last_longitude'] = Variable<double>(lastLongitude.value);
    }
    if (lastChannelHash.present) {
      map['last_channel_hash'] = Variable<int>(lastChannelHash.value);
    }
    if (lastPathLen.present) {
      map['last_path_len'] = Variable<int>(lastPathLen.value);
    }
    if (companionBatteryMilliVolts.present) {
      map['companion_battery_milli_volts'] = Variable<int>(
        companionBatteryMilliVolts.value,
      );
    }
    if (phoneBatteryMilliVolts.present) {
      map['phone_battery_milli_volts'] = Variable<int>(
        phoneBatteryMilliVolts.value,
      );
    }
    if (isAutonomousDevice.present) {
      map['is_autonomous_device'] = Variable<bool>(isAutonomousDevice.value);
    }
    if (isManuallyHidden.present) {
      map['is_manually_hidden'] = Variable<bool>(isManuallyHidden.value);
    }
    if (hiddenAt.present) {
      map['hidden_at'] = Variable<int>(hiddenAt.value);
    }
    if (firstSeen.present) {
      map['first_seen'] = Variable<int>(firstSeen.value);
    }
    if (totalTelemetryReceived.present) {
      map['total_telemetry_received'] = Variable<int>(
        totalTelemetryReceived.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeerLocationsCompanion(')
          ..write('peerId: $peerId, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('lastLatitude: $lastLatitude, ')
          ..write('lastLongitude: $lastLongitude, ')
          ..write('lastChannelHash: $lastChannelHash, ')
          ..write('lastPathLen: $lastPathLen, ')
          ..write('companionBatteryMilliVolts: $companionBatteryMilliVolts, ')
          ..write('phoneBatteryMilliVolts: $phoneBatteryMilliVolts, ')
          ..write('isAutonomousDevice: $isAutonomousDevice, ')
          ..write('isManuallyHidden: $isManuallyHidden, ')
          ..write('hiddenAt: $hiddenAt, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('totalTelemetryReceived: $totalTelemetryReceived')
          ..write(')'))
        .toString();
  }
}

class $PeerPositionHistoryTable extends PeerPositionHistory
    with TableInfo<$PeerPositionHistoryTable, PeerPositionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeerPositionHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _peerIdMeta = const VerificationMeta('peerId');
  @override
  late final GeneratedColumn<int> peerId = GeneratedColumn<int>(
    'peer_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES peers (id)',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelHashMeta = const VerificationMeta(
    'channelHash',
  );
  @override
  late final GeneratedColumn<int> channelHash = GeneratedColumn<int>(
    'channel_hash',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathLenMeta = const VerificationMeta(
    'pathLen',
  );
  @override
  late final GeneratedColumn<int> pathLen = GeneratedColumn<int>(
    'path_len',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    peerId,
    timestamp,
    latitude,
    longitude,
    channelHash,
    pathLen,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'peer_position_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeerPositionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('peer_id')) {
      context.handle(
        _peerIdMeta,
        peerId.isAcceptableOrUnknown(data['peer_id']!, _peerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_peerIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('channel_hash')) {
      context.handle(
        _channelHashMeta,
        channelHash.isAcceptableOrUnknown(
          data['channel_hash']!,
          _channelHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_channelHashMeta);
    }
    if (data.containsKey('path_len')) {
      context.handle(
        _pathLenMeta,
        pathLen.isAcceptableOrUnknown(data['path_len']!, _pathLenMeta),
      );
    } else if (isInserting) {
      context.missing(_pathLenMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeerPositionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeerPositionData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      peerId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}peer_id'],
          )!,
      timestamp:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}timestamp'],
          )!,
      latitude:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}latitude'],
          )!,
      longitude:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}longitude'],
          )!,
      channelHash:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}channel_hash'],
          )!,
      pathLen:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}path_len'],
          )!,
    );
  }

  @override
  $PeerPositionHistoryTable createAlias(String alias) {
    return $PeerPositionHistoryTable(attachedDatabase, alias);
  }
}

class PeerPositionData extends DataClass
    implements Insertable<PeerPositionData> {
  final int id;
  final int peerId;
  final int timestamp;
  final double latitude;
  final double longitude;
  final int channelHash;
  final int pathLen;
  const PeerPositionData({
    required this.id,
    required this.peerId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.channelHash,
    required this.pathLen,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['peer_id'] = Variable<int>(peerId);
    map['timestamp'] = Variable<int>(timestamp);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['channel_hash'] = Variable<int>(channelHash);
    map['path_len'] = Variable<int>(pathLen);
    return map;
  }

  PeerPositionHistoryCompanion toCompanion(bool nullToAbsent) {
    return PeerPositionHistoryCompanion(
      id: Value(id),
      peerId: Value(peerId),
      timestamp: Value(timestamp),
      latitude: Value(latitude),
      longitude: Value(longitude),
      channelHash: Value(channelHash),
      pathLen: Value(pathLen),
    );
  }

  factory PeerPositionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeerPositionData(
      id: serializer.fromJson<int>(json['id']),
      peerId: serializer.fromJson<int>(json['peerId']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      channelHash: serializer.fromJson<int>(json['channelHash']),
      pathLen: serializer.fromJson<int>(json['pathLen']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'peerId': serializer.toJson<int>(peerId),
      'timestamp': serializer.toJson<int>(timestamp),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'channelHash': serializer.toJson<int>(channelHash),
      'pathLen': serializer.toJson<int>(pathLen),
    };
  }

  PeerPositionData copyWith({
    int? id,
    int? peerId,
    int? timestamp,
    double? latitude,
    double? longitude,
    int? channelHash,
    int? pathLen,
  }) => PeerPositionData(
    id: id ?? this.id,
    peerId: peerId ?? this.peerId,
    timestamp: timestamp ?? this.timestamp,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    channelHash: channelHash ?? this.channelHash,
    pathLen: pathLen ?? this.pathLen,
  );
  PeerPositionData copyWithCompanion(PeerPositionHistoryCompanion data) {
    return PeerPositionData(
      id: data.id.present ? data.id.value : this.id,
      peerId: data.peerId.present ? data.peerId.value : this.peerId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      channelHash:
          data.channelHash.present ? data.channelHash.value : this.channelHash,
      pathLen: data.pathLen.present ? data.pathLen.value : this.pathLen,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeerPositionData(')
          ..write('id: $id, ')
          ..write('peerId: $peerId, ')
          ..write('timestamp: $timestamp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('channelHash: $channelHash, ')
          ..write('pathLen: $pathLen')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    peerId,
    timestamp,
    latitude,
    longitude,
    channelHash,
    pathLen,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeerPositionData &&
          other.id == this.id &&
          other.peerId == this.peerId &&
          other.timestamp == this.timestamp &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.channelHash == this.channelHash &&
          other.pathLen == this.pathLen);
}

class PeerPositionHistoryCompanion extends UpdateCompanion<PeerPositionData> {
  final Value<int> id;
  final Value<int> peerId;
  final Value<int> timestamp;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<int> channelHash;
  final Value<int> pathLen;
  const PeerPositionHistoryCompanion({
    this.id = const Value.absent(),
    this.peerId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.channelHash = const Value.absent(),
    this.pathLen = const Value.absent(),
  });
  PeerPositionHistoryCompanion.insert({
    this.id = const Value.absent(),
    required int peerId,
    required int timestamp,
    required double latitude,
    required double longitude,
    required int channelHash,
    required int pathLen,
  }) : peerId = Value(peerId),
       timestamp = Value(timestamp),
       latitude = Value(latitude),
       longitude = Value(longitude),
       channelHash = Value(channelHash),
       pathLen = Value(pathLen);
  static Insertable<PeerPositionData> custom({
    Expression<int>? id,
    Expression<int>? peerId,
    Expression<int>? timestamp,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? channelHash,
    Expression<int>? pathLen,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (peerId != null) 'peer_id': peerId,
      if (timestamp != null) 'timestamp': timestamp,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (channelHash != null) 'channel_hash': channelHash,
      if (pathLen != null) 'path_len': pathLen,
    });
  }

  PeerPositionHistoryCompanion copyWith({
    Value<int>? id,
    Value<int>? peerId,
    Value<int>? timestamp,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<int>? channelHash,
    Value<int>? pathLen,
  }) {
    return PeerPositionHistoryCompanion(
      id: id ?? this.id,
      peerId: peerId ?? this.peerId,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      channelHash: channelHash ?? this.channelHash,
      pathLen: pathLen ?? this.pathLen,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (peerId.present) {
      map['peer_id'] = Variable<int>(peerId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (channelHash.present) {
      map['channel_hash'] = Variable<int>(channelHash.value);
    }
    if (pathLen.present) {
      map['path_len'] = Variable<int>(pathLen.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeerPositionHistoryCompanion(')
          ..write('id: $id, ')
          ..write('peerId: $peerId, ')
          ..write('timestamp: $timestamp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('channelHash: $channelHash, ')
          ..write('pathLen: $pathLen')
          ..write(')'))
        .toString();
  }
}

class $AckRecordsTable extends AckRecords
    with TableInfo<$AckRecordsTable, AckRecordData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AckRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ackerPublicKeyMeta = const VerificationMeta(
    'ackerPublicKey',
  );
  @override
  late final GeneratedColumn<Uint8List> ackerPublicKey =
      GeneratedColumn<Uint8List>(
        'acker_public_key',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<int> receivedAt = GeneratedColumn<int>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snrMeta = const VerificationMeta('snr');
  @override
  late final GeneratedColumn<int> snr = GeneratedColumn<int>(
    'snr',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rssiMeta = const VerificationMeta('rssi');
  @override
  late final GeneratedColumn<int> rssi = GeneratedColumn<int>(
    'rssi',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _companionDeviceKeyMeta =
      const VerificationMeta('companionDeviceKey');
  @override
  late final GeneratedColumn<String> companionDeviceKey =
      GeneratedColumn<String>(
        'companion_device_key',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    messageId,
    ackerPublicKey,
    receivedAt,
    snr,
    rssi,
    companionDeviceKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ack_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<AckRecordData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('acker_public_key')) {
      context.handle(
        _ackerPublicKeyMeta,
        ackerPublicKey.isAcceptableOrUnknown(
          data['acker_public_key']!,
          _ackerPublicKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ackerPublicKeyMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('snr')) {
      context.handle(
        _snrMeta,
        snr.isAcceptableOrUnknown(data['snr']!, _snrMeta),
      );
    }
    if (data.containsKey('rssi')) {
      context.handle(
        _rssiMeta,
        rssi.isAcceptableOrUnknown(data['rssi']!, _rssiMeta),
      );
    }
    if (data.containsKey('companion_device_key')) {
      context.handle(
        _companionDeviceKeyMeta,
        companionDeviceKey.isAcceptableOrUnknown(
          data['companion_device_key']!,
          _companionDeviceKeyMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId, ackerPublicKey};
  @override
  AckRecordData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AckRecordData(
      messageId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}message_id'],
          )!,
      ackerPublicKey:
          attachedDatabase.typeMapping.read(
            DriftSqlType.blob,
            data['${effectivePrefix}acker_public_key'],
          )!,
      receivedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}received_at'],
          )!,
      snr: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snr'],
      ),
      rssi: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rssi'],
      ),
      companionDeviceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}companion_device_key'],
      ),
    );
  }

  @override
  $AckRecordsTable createAlias(String alias) {
    return $AckRecordsTable(attachedDatabase, alias);
  }
}

class AckRecordData extends DataClass implements Insertable<AckRecordData> {
  final String messageId;
  final Uint8List ackerPublicKey;
  final int receivedAt;
  final int? snr;
  final int? rssi;
  final String? companionDeviceKey;
  const AckRecordData({
    required this.messageId,
    required this.ackerPublicKey,
    required this.receivedAt,
    this.snr,
    this.rssi,
    this.companionDeviceKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['acker_public_key'] = Variable<Uint8List>(ackerPublicKey);
    map['received_at'] = Variable<int>(receivedAt);
    if (!nullToAbsent || snr != null) {
      map['snr'] = Variable<int>(snr);
    }
    if (!nullToAbsent || rssi != null) {
      map['rssi'] = Variable<int>(rssi);
    }
    if (!nullToAbsent || companionDeviceKey != null) {
      map['companion_device_key'] = Variable<String>(companionDeviceKey);
    }
    return map;
  }

  AckRecordsCompanion toCompanion(bool nullToAbsent) {
    return AckRecordsCompanion(
      messageId: Value(messageId),
      ackerPublicKey: Value(ackerPublicKey),
      receivedAt: Value(receivedAt),
      snr: snr == null && nullToAbsent ? const Value.absent() : Value(snr),
      rssi: rssi == null && nullToAbsent ? const Value.absent() : Value(rssi),
      companionDeviceKey:
          companionDeviceKey == null && nullToAbsent
              ? const Value.absent()
              : Value(companionDeviceKey),
    );
  }

  factory AckRecordData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AckRecordData(
      messageId: serializer.fromJson<String>(json['messageId']),
      ackerPublicKey: serializer.fromJson<Uint8List>(json['ackerPublicKey']),
      receivedAt: serializer.fromJson<int>(json['receivedAt']),
      snr: serializer.fromJson<int?>(json['snr']),
      rssi: serializer.fromJson<int?>(json['rssi']),
      companionDeviceKey: serializer.fromJson<String?>(
        json['companionDeviceKey'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'ackerPublicKey': serializer.toJson<Uint8List>(ackerPublicKey),
      'receivedAt': serializer.toJson<int>(receivedAt),
      'snr': serializer.toJson<int?>(snr),
      'rssi': serializer.toJson<int?>(rssi),
      'companionDeviceKey': serializer.toJson<String?>(companionDeviceKey),
    };
  }

  AckRecordData copyWith({
    String? messageId,
    Uint8List? ackerPublicKey,
    int? receivedAt,
    Value<int?> snr = const Value.absent(),
    Value<int?> rssi = const Value.absent(),
    Value<String?> companionDeviceKey = const Value.absent(),
  }) => AckRecordData(
    messageId: messageId ?? this.messageId,
    ackerPublicKey: ackerPublicKey ?? this.ackerPublicKey,
    receivedAt: receivedAt ?? this.receivedAt,
    snr: snr.present ? snr.value : this.snr,
    rssi: rssi.present ? rssi.value : this.rssi,
    companionDeviceKey:
        companionDeviceKey.present
            ? companionDeviceKey.value
            : this.companionDeviceKey,
  );
  AckRecordData copyWithCompanion(AckRecordsCompanion data) {
    return AckRecordData(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      ackerPublicKey:
          data.ackerPublicKey.present
              ? data.ackerPublicKey.value
              : this.ackerPublicKey,
      receivedAt:
          data.receivedAt.present ? data.receivedAt.value : this.receivedAt,
      snr: data.snr.present ? data.snr.value : this.snr,
      rssi: data.rssi.present ? data.rssi.value : this.rssi,
      companionDeviceKey:
          data.companionDeviceKey.present
              ? data.companionDeviceKey.value
              : this.companionDeviceKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AckRecordData(')
          ..write('messageId: $messageId, ')
          ..write('ackerPublicKey: $ackerPublicKey, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('snr: $snr, ')
          ..write('rssi: $rssi, ')
          ..write('companionDeviceKey: $companionDeviceKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    messageId,
    $driftBlobEquality.hash(ackerPublicKey),
    receivedAt,
    snr,
    rssi,
    companionDeviceKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AckRecordData &&
          other.messageId == this.messageId &&
          $driftBlobEquality.equals(
            other.ackerPublicKey,
            this.ackerPublicKey,
          ) &&
          other.receivedAt == this.receivedAt &&
          other.snr == this.snr &&
          other.rssi == this.rssi &&
          other.companionDeviceKey == this.companionDeviceKey);
}

class AckRecordsCompanion extends UpdateCompanion<AckRecordData> {
  final Value<String> messageId;
  final Value<Uint8List> ackerPublicKey;
  final Value<int> receivedAt;
  final Value<int?> snr;
  final Value<int?> rssi;
  final Value<String?> companionDeviceKey;
  final Value<int> rowid;
  const AckRecordsCompanion({
    this.messageId = const Value.absent(),
    this.ackerPublicKey = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.snr = const Value.absent(),
    this.rssi = const Value.absent(),
    this.companionDeviceKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AckRecordsCompanion.insert({
    required String messageId,
    required Uint8List ackerPublicKey,
    required int receivedAt,
    this.snr = const Value.absent(),
    this.rssi = const Value.absent(),
    this.companionDeviceKey = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       ackerPublicKey = Value(ackerPublicKey),
       receivedAt = Value(receivedAt);
  static Insertable<AckRecordData> custom({
    Expression<String>? messageId,
    Expression<Uint8List>? ackerPublicKey,
    Expression<int>? receivedAt,
    Expression<int>? snr,
    Expression<int>? rssi,
    Expression<String>? companionDeviceKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (ackerPublicKey != null) 'acker_public_key': ackerPublicKey,
      if (receivedAt != null) 'received_at': receivedAt,
      if (snr != null) 'snr': snr,
      if (rssi != null) 'rssi': rssi,
      if (companionDeviceKey != null)
        'companion_device_key': companionDeviceKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AckRecordsCompanion copyWith({
    Value<String>? messageId,
    Value<Uint8List>? ackerPublicKey,
    Value<int>? receivedAt,
    Value<int?>? snr,
    Value<int?>? rssi,
    Value<String?>? companionDeviceKey,
    Value<int>? rowid,
  }) {
    return AckRecordsCompanion(
      messageId: messageId ?? this.messageId,
      ackerPublicKey: ackerPublicKey ?? this.ackerPublicKey,
      receivedAt: receivedAt ?? this.receivedAt,
      snr: snr ?? this.snr,
      rssi: rssi ?? this.rssi,
      companionDeviceKey: companionDeviceKey ?? this.companionDeviceKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (ackerPublicKey.present) {
      map['acker_public_key'] = Variable<Uint8List>(ackerPublicKey.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<int>(receivedAt.value);
    }
    if (snr.present) {
      map['snr'] = Variable<int>(snr.value);
    }
    if (rssi.present) {
      map['rssi'] = Variable<int>(rssi.value);
    }
    if (companionDeviceKey.present) {
      map['companion_device_key'] = Variable<String>(companionDeviceKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AckRecordsCompanion(')
          ..write('messageId: $messageId, ')
          ..write('ackerPublicKey: $ackerPublicKey, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('snr: $snr, ')
          ..write('rssi: $rssi, ')
          ..write('companionDeviceKey: $companionDeviceKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineMapAreasTable extends OfflineMapAreas
    with TableInfo<$OfflineMapAreasTable, OfflineMapAreaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineMapAreasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _northMeta = const VerificationMeta('north');
  @override
  late final GeneratedColumn<double> north = GeneratedColumn<double>(
    'north',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _southMeta = const VerificationMeta('south');
  @override
  late final GeneratedColumn<double> south = GeneratedColumn<double>(
    'south',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eastMeta = const VerificationMeta('east');
  @override
  late final GeneratedColumn<double> east = GeneratedColumn<double>(
    'east',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _westMeta = const VerificationMeta('west');
  @override
  late final GeneratedColumn<double> west = GeneratedColumn<double>(
    'west',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minZoomMeta = const VerificationMeta(
    'minZoom',
  );
  @override
  late final GeneratedColumn<int> minZoom = GeneratedColumn<int>(
    'min_zoom',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxZoomMeta = const VerificationMeta(
    'maxZoom',
  );
  @override
  late final GeneratedColumn<int> maxZoom = GeneratedColumn<int>(
    'max_zoom',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tileCountMeta = const VerificationMeta(
    'tileCount',
  );
  @override
  late final GeneratedColumn<int> tileCount = GeneratedColumn<int>(
    'tile_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<int> downloadedAt = GeneratedColumn<int>(
    'downloaded_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    providerId,
    north,
    south,
    east,
    west,
    minZoom,
    maxZoom,
    tileCount,
    downloadedAt,
    sizeBytes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_map_areas';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineMapAreaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('north')) {
      context.handle(
        _northMeta,
        north.isAcceptableOrUnknown(data['north']!, _northMeta),
      );
    } else if (isInserting) {
      context.missing(_northMeta);
    }
    if (data.containsKey('south')) {
      context.handle(
        _southMeta,
        south.isAcceptableOrUnknown(data['south']!, _southMeta),
      );
    } else if (isInserting) {
      context.missing(_southMeta);
    }
    if (data.containsKey('east')) {
      context.handle(
        _eastMeta,
        east.isAcceptableOrUnknown(data['east']!, _eastMeta),
      );
    } else if (isInserting) {
      context.missing(_eastMeta);
    }
    if (data.containsKey('west')) {
      context.handle(
        _westMeta,
        west.isAcceptableOrUnknown(data['west']!, _westMeta),
      );
    } else if (isInserting) {
      context.missing(_westMeta);
    }
    if (data.containsKey('min_zoom')) {
      context.handle(
        _minZoomMeta,
        minZoom.isAcceptableOrUnknown(data['min_zoom']!, _minZoomMeta),
      );
    } else if (isInserting) {
      context.missing(_minZoomMeta);
    }
    if (data.containsKey('max_zoom')) {
      context.handle(
        _maxZoomMeta,
        maxZoom.isAcceptableOrUnknown(data['max_zoom']!, _maxZoomMeta),
      );
    } else if (isInserting) {
      context.missing(_maxZoomMeta);
    }
    if (data.containsKey('tile_count')) {
      context.handle(
        _tileCountMeta,
        tileCount.isAcceptableOrUnknown(data['tile_count']!, _tileCountMeta),
      );
    } else if (isInserting) {
      context.missing(_tileCountMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineMapAreaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineMapAreaData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      providerId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}provider_id'],
          )!,
      north:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}north'],
          )!,
      south:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}south'],
          )!,
      east:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}east'],
          )!,
      west:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}west'],
          )!,
      minZoom:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}min_zoom'],
          )!,
      maxZoom:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}max_zoom'],
          )!,
      tileCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}tile_count'],
          )!,
      downloadedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}downloaded_at'],
          )!,
      sizeBytes:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}size_bytes'],
          )!,
    );
  }

  @override
  $OfflineMapAreasTable createAlias(String alias) {
    return $OfflineMapAreasTable(attachedDatabase, alias);
  }
}

class OfflineMapAreaData extends DataClass
    implements Insertable<OfflineMapAreaData> {
  final String id;
  final String name;
  final String providerId;
  final double north;
  final double south;
  final double east;
  final double west;
  final int minZoom;
  final int maxZoom;
  final int tileCount;
  final int downloadedAt;
  final int sizeBytes;
  const OfflineMapAreaData({
    required this.id,
    required this.name,
    required this.providerId,
    required this.north,
    required this.south,
    required this.east,
    required this.west,
    required this.minZoom,
    required this.maxZoom,
    required this.tileCount,
    required this.downloadedAt,
    required this.sizeBytes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['provider_id'] = Variable<String>(providerId);
    map['north'] = Variable<double>(north);
    map['south'] = Variable<double>(south);
    map['east'] = Variable<double>(east);
    map['west'] = Variable<double>(west);
    map['min_zoom'] = Variable<int>(minZoom);
    map['max_zoom'] = Variable<int>(maxZoom);
    map['tile_count'] = Variable<int>(tileCount);
    map['downloaded_at'] = Variable<int>(downloadedAt);
    map['size_bytes'] = Variable<int>(sizeBytes);
    return map;
  }

  OfflineMapAreasCompanion toCompanion(bool nullToAbsent) {
    return OfflineMapAreasCompanion(
      id: Value(id),
      name: Value(name),
      providerId: Value(providerId),
      north: Value(north),
      south: Value(south),
      east: Value(east),
      west: Value(west),
      minZoom: Value(minZoom),
      maxZoom: Value(maxZoom),
      tileCount: Value(tileCount),
      downloadedAt: Value(downloadedAt),
      sizeBytes: Value(sizeBytes),
    );
  }

  factory OfflineMapAreaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineMapAreaData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      providerId: serializer.fromJson<String>(json['providerId']),
      north: serializer.fromJson<double>(json['north']),
      south: serializer.fromJson<double>(json['south']),
      east: serializer.fromJson<double>(json['east']),
      west: serializer.fromJson<double>(json['west']),
      minZoom: serializer.fromJson<int>(json['minZoom']),
      maxZoom: serializer.fromJson<int>(json['maxZoom']),
      tileCount: serializer.fromJson<int>(json['tileCount']),
      downloadedAt: serializer.fromJson<int>(json['downloadedAt']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'providerId': serializer.toJson<String>(providerId),
      'north': serializer.toJson<double>(north),
      'south': serializer.toJson<double>(south),
      'east': serializer.toJson<double>(east),
      'west': serializer.toJson<double>(west),
      'minZoom': serializer.toJson<int>(minZoom),
      'maxZoom': serializer.toJson<int>(maxZoom),
      'tileCount': serializer.toJson<int>(tileCount),
      'downloadedAt': serializer.toJson<int>(downloadedAt),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
    };
  }

  OfflineMapAreaData copyWith({
    String? id,
    String? name,
    String? providerId,
    double? north,
    double? south,
    double? east,
    double? west,
    int? minZoom,
    int? maxZoom,
    int? tileCount,
    int? downloadedAt,
    int? sizeBytes,
  }) => OfflineMapAreaData(
    id: id ?? this.id,
    name: name ?? this.name,
    providerId: providerId ?? this.providerId,
    north: north ?? this.north,
    south: south ?? this.south,
    east: east ?? this.east,
    west: west ?? this.west,
    minZoom: minZoom ?? this.minZoom,
    maxZoom: maxZoom ?? this.maxZoom,
    tileCount: tileCount ?? this.tileCount,
    downloadedAt: downloadedAt ?? this.downloadedAt,
    sizeBytes: sizeBytes ?? this.sizeBytes,
  );
  OfflineMapAreaData copyWithCompanion(OfflineMapAreasCompanion data) {
    return OfflineMapAreaData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      north: data.north.present ? data.north.value : this.north,
      south: data.south.present ? data.south.value : this.south,
      east: data.east.present ? data.east.value : this.east,
      west: data.west.present ? data.west.value : this.west,
      minZoom: data.minZoom.present ? data.minZoom.value : this.minZoom,
      maxZoom: data.maxZoom.present ? data.maxZoom.value : this.maxZoom,
      tileCount: data.tileCount.present ? data.tileCount.value : this.tileCount,
      downloadedAt:
          data.downloadedAt.present
              ? data.downloadedAt.value
              : this.downloadedAt,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineMapAreaData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('providerId: $providerId, ')
          ..write('north: $north, ')
          ..write('south: $south, ')
          ..write('east: $east, ')
          ..write('west: $west, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('tileCount: $tileCount, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('sizeBytes: $sizeBytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    providerId,
    north,
    south,
    east,
    west,
    minZoom,
    maxZoom,
    tileCount,
    downloadedAt,
    sizeBytes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineMapAreaData &&
          other.id == this.id &&
          other.name == this.name &&
          other.providerId == this.providerId &&
          other.north == this.north &&
          other.south == this.south &&
          other.east == this.east &&
          other.west == this.west &&
          other.minZoom == this.minZoom &&
          other.maxZoom == this.maxZoom &&
          other.tileCount == this.tileCount &&
          other.downloadedAt == this.downloadedAt &&
          other.sizeBytes == this.sizeBytes);
}

class OfflineMapAreasCompanion extends UpdateCompanion<OfflineMapAreaData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> providerId;
  final Value<double> north;
  final Value<double> south;
  final Value<double> east;
  final Value<double> west;
  final Value<int> minZoom;
  final Value<int> maxZoom;
  final Value<int> tileCount;
  final Value<int> downloadedAt;
  final Value<int> sizeBytes;
  final Value<int> rowid;
  const OfflineMapAreasCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.providerId = const Value.absent(),
    this.north = const Value.absent(),
    this.south = const Value.absent(),
    this.east = const Value.absent(),
    this.west = const Value.absent(),
    this.minZoom = const Value.absent(),
    this.maxZoom = const Value.absent(),
    this.tileCount = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineMapAreasCompanion.insert({
    required String id,
    required String name,
    required String providerId,
    required double north,
    required double south,
    required double east,
    required double west,
    required int minZoom,
    required int maxZoom,
    required int tileCount,
    required int downloadedAt,
    required int sizeBytes,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       providerId = Value(providerId),
       north = Value(north),
       south = Value(south),
       east = Value(east),
       west = Value(west),
       minZoom = Value(minZoom),
       maxZoom = Value(maxZoom),
       tileCount = Value(tileCount),
       downloadedAt = Value(downloadedAt),
       sizeBytes = Value(sizeBytes);
  static Insertable<OfflineMapAreaData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? providerId,
    Expression<double>? north,
    Expression<double>? south,
    Expression<double>? east,
    Expression<double>? west,
    Expression<int>? minZoom,
    Expression<int>? maxZoom,
    Expression<int>? tileCount,
    Expression<int>? downloadedAt,
    Expression<int>? sizeBytes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (providerId != null) 'provider_id': providerId,
      if (north != null) 'north': north,
      if (south != null) 'south': south,
      if (east != null) 'east': east,
      if (west != null) 'west': west,
      if (minZoom != null) 'min_zoom': minZoom,
      if (maxZoom != null) 'max_zoom': maxZoom,
      if (tileCount != null) 'tile_count': tileCount,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineMapAreasCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? providerId,
    Value<double>? north,
    Value<double>? south,
    Value<double>? east,
    Value<double>? west,
    Value<int>? minZoom,
    Value<int>? maxZoom,
    Value<int>? tileCount,
    Value<int>? downloadedAt,
    Value<int>? sizeBytes,
    Value<int>? rowid,
  }) {
    return OfflineMapAreasCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      providerId: providerId ?? this.providerId,
      north: north ?? this.north,
      south: south ?? this.south,
      east: east ?? this.east,
      west: west ?? this.west,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      tileCount: tileCount ?? this.tileCount,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      sizeBytes: sizeBytes ?? this.sizeBytes,
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
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (north.present) {
      map['north'] = Variable<double>(north.value);
    }
    if (south.present) {
      map['south'] = Variable<double>(south.value);
    }
    if (east.present) {
      map['east'] = Variable<double>(east.value);
    }
    if (west.present) {
      map['west'] = Variable<double>(west.value);
    }
    if (minZoom.present) {
      map['min_zoom'] = Variable<int>(minZoom.value);
    }
    if (maxZoom.present) {
      map['max_zoom'] = Variable<int>(maxZoom.value);
    }
    if (tileCount.present) {
      map['tile_count'] = Variable<int>(tileCount.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<int>(downloadedAt.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineMapAreasCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('providerId: $providerId, ')
          ..write('north: $north, ')
          ..write('south: $south, ')
          ..write('east: $east, ')
          ..write('west: $west, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('tileCount: $tileCount, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportedOverlayMapsTable extends ImportedOverlayMaps
    with TableInfo<$ImportedOverlayMapsTable, ImportedOverlayMapData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportedOverlayMapsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dirPathMeta = const VerificationMeta(
    'dirPath',
  );
  @override
  late final GeneratedColumn<String> dirPath = GeneratedColumn<String>(
    'dir_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tileCountMeta = const VerificationMeta(
    'tileCount',
  );
  @override
  late final GeneratedColumn<int> tileCount = GeneratedColumn<int>(
    'tile_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<int> importedAt = GeneratedColumn<int>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isVisibleMeta = const VerificationMeta(
    'isVisible',
  );
  @override
  late final GeneratedColumn<bool> isVisible = GeneratedColumn<bool>(
    'is_visible',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_visible" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _boundsNorthMeta = const VerificationMeta(
    'boundsNorth',
  );
  @override
  late final GeneratedColumn<double> boundsNorth = GeneratedColumn<double>(
    'bounds_north',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundsSouthMeta = const VerificationMeta(
    'boundsSouth',
  );
  @override
  late final GeneratedColumn<double> boundsSouth = GeneratedColumn<double>(
    'bounds_south',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundsEastMeta = const VerificationMeta(
    'boundsEast',
  );
  @override
  late final GeneratedColumn<double> boundsEast = GeneratedColumn<double>(
    'bounds_east',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundsWestMeta = const VerificationMeta(
    'boundsWest',
  );
  @override
  late final GeneratedColumn<double> boundsWest = GeneratedColumn<double>(
    'bounds_west',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _layerTypeMeta = const VerificationMeta(
    'layerType',
  );
  @override
  late final GeneratedColumn<String> layerType = GeneratedColumn<String>(
    'layer_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('kmz'),
  );
  static const VerificationMeta _minZoomMeta = const VerificationMeta(
    'minZoom',
  );
  @override
  late final GeneratedColumn<int> minZoom = GeneratedColumn<int>(
    'min_zoom',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxZoomMeta = const VerificationMeta(
    'maxZoom',
  );
  @override
  late final GeneratedColumn<int> maxZoom = GeneratedColumn<int>(
    'max_zoom',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _opacityMeta = const VerificationMeta(
    'opacity',
  );
  @override
  late final GeneratedColumn<double> opacity = GeneratedColumn<double>(
    'opacity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    dirPath,
    tileCount,
    importedAt,
    isVisible,
    boundsNorth,
    boundsSouth,
    boundsEast,
    boundsWest,
    layerType,
    minZoom,
    maxZoom,
    opacity,
    sizeBytes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'imported_overlay_maps';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportedOverlayMapData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('dir_path')) {
      context.handle(
        _dirPathMeta,
        dirPath.isAcceptableOrUnknown(data['dir_path']!, _dirPathMeta),
      );
    } else if (isInserting) {
      context.missing(_dirPathMeta);
    }
    if (data.containsKey('tile_count')) {
      context.handle(
        _tileCountMeta,
        tileCount.isAcceptableOrUnknown(data['tile_count']!, _tileCountMeta),
      );
    } else if (isInserting) {
      context.missing(_tileCountMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    if (data.containsKey('is_visible')) {
      context.handle(
        _isVisibleMeta,
        isVisible.isAcceptableOrUnknown(data['is_visible']!, _isVisibleMeta),
      );
    }
    if (data.containsKey('bounds_north')) {
      context.handle(
        _boundsNorthMeta,
        boundsNorth.isAcceptableOrUnknown(
          data['bounds_north']!,
          _boundsNorthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boundsNorthMeta);
    }
    if (data.containsKey('bounds_south')) {
      context.handle(
        _boundsSouthMeta,
        boundsSouth.isAcceptableOrUnknown(
          data['bounds_south']!,
          _boundsSouthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boundsSouthMeta);
    }
    if (data.containsKey('bounds_east')) {
      context.handle(
        _boundsEastMeta,
        boundsEast.isAcceptableOrUnknown(data['bounds_east']!, _boundsEastMeta),
      );
    } else if (isInserting) {
      context.missing(_boundsEastMeta);
    }
    if (data.containsKey('bounds_west')) {
      context.handle(
        _boundsWestMeta,
        boundsWest.isAcceptableOrUnknown(data['bounds_west']!, _boundsWestMeta),
      );
    } else if (isInserting) {
      context.missing(_boundsWestMeta);
    }
    if (data.containsKey('layer_type')) {
      context.handle(
        _layerTypeMeta,
        layerType.isAcceptableOrUnknown(data['layer_type']!, _layerTypeMeta),
      );
    }
    if (data.containsKey('min_zoom')) {
      context.handle(
        _minZoomMeta,
        minZoom.isAcceptableOrUnknown(data['min_zoom']!, _minZoomMeta),
      );
    }
    if (data.containsKey('max_zoom')) {
      context.handle(
        _maxZoomMeta,
        maxZoom.isAcceptableOrUnknown(data['max_zoom']!, _maxZoomMeta),
      );
    }
    if (data.containsKey('opacity')) {
      context.handle(
        _opacityMeta,
        opacity.isAcceptableOrUnknown(data['opacity']!, _opacityMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportedOverlayMapData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportedOverlayMapData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      dirPath:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}dir_path'],
          )!,
      tileCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}tile_count'],
          )!,
      importedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}imported_at'],
          )!,
      isVisible:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_visible'],
          )!,
      boundsNorth:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}bounds_north'],
          )!,
      boundsSouth:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}bounds_south'],
          )!,
      boundsEast:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}bounds_east'],
          )!,
      boundsWest:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}bounds_west'],
          )!,
      layerType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}layer_type'],
          )!,
      minZoom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_zoom'],
      ),
      maxZoom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_zoom'],
      ),
      opacity:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}opacity'],
          )!,
      sizeBytes:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}size_bytes'],
          )!,
    );
  }

  @override
  $ImportedOverlayMapsTable createAlias(String alias) {
    return $ImportedOverlayMapsTable(attachedDatabase, alias);
  }
}

class ImportedOverlayMapData extends DataClass
    implements Insertable<ImportedOverlayMapData> {
  final String id;
  final String name;
  final String dirPath;
  final int tileCount;
  final int importedAt;
  final bool isVisible;
  final double boundsNorth;
  final double boundsSouth;
  final double boundsEast;
  final double boundsWest;

  /// Discriminator: 'kmz' | 'mbtiles' | 'geopdf'. Defaults to 'kmz' so rows
  /// written before schema v9 keep their meaning with no data migration.
  final String layerType;

  /// Native zoom range. Null for KMZ, which has no pyramid semantics.
  final int? minZoom;
  final int? maxZoom;

  /// Per-layer render opacity, 0.0-1.0.
  final double opacity;

  /// On-disk size, recorded at import. Avoids walking a multi-GB MBTiles
  /// file every time the manage screen rebuilds.
  final int sizeBytes;
  const ImportedOverlayMapData({
    required this.id,
    required this.name,
    required this.dirPath,
    required this.tileCount,
    required this.importedAt,
    required this.isVisible,
    required this.boundsNorth,
    required this.boundsSouth,
    required this.boundsEast,
    required this.boundsWest,
    required this.layerType,
    this.minZoom,
    this.maxZoom,
    required this.opacity,
    required this.sizeBytes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['dir_path'] = Variable<String>(dirPath);
    map['tile_count'] = Variable<int>(tileCount);
    map['imported_at'] = Variable<int>(importedAt);
    map['is_visible'] = Variable<bool>(isVisible);
    map['bounds_north'] = Variable<double>(boundsNorth);
    map['bounds_south'] = Variable<double>(boundsSouth);
    map['bounds_east'] = Variable<double>(boundsEast);
    map['bounds_west'] = Variable<double>(boundsWest);
    map['layer_type'] = Variable<String>(layerType);
    if (!nullToAbsent || minZoom != null) {
      map['min_zoom'] = Variable<int>(minZoom);
    }
    if (!nullToAbsent || maxZoom != null) {
      map['max_zoom'] = Variable<int>(maxZoom);
    }
    map['opacity'] = Variable<double>(opacity);
    map['size_bytes'] = Variable<int>(sizeBytes);
    return map;
  }

  ImportedOverlayMapsCompanion toCompanion(bool nullToAbsent) {
    return ImportedOverlayMapsCompanion(
      id: Value(id),
      name: Value(name),
      dirPath: Value(dirPath),
      tileCount: Value(tileCount),
      importedAt: Value(importedAt),
      isVisible: Value(isVisible),
      boundsNorth: Value(boundsNorth),
      boundsSouth: Value(boundsSouth),
      boundsEast: Value(boundsEast),
      boundsWest: Value(boundsWest),
      layerType: Value(layerType),
      minZoom:
          minZoom == null && nullToAbsent
              ? const Value.absent()
              : Value(minZoom),
      maxZoom:
          maxZoom == null && nullToAbsent
              ? const Value.absent()
              : Value(maxZoom),
      opacity: Value(opacity),
      sizeBytes: Value(sizeBytes),
    );
  }

  factory ImportedOverlayMapData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportedOverlayMapData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      dirPath: serializer.fromJson<String>(json['dirPath']),
      tileCount: serializer.fromJson<int>(json['tileCount']),
      importedAt: serializer.fromJson<int>(json['importedAt']),
      isVisible: serializer.fromJson<bool>(json['isVisible']),
      boundsNorth: serializer.fromJson<double>(json['boundsNorth']),
      boundsSouth: serializer.fromJson<double>(json['boundsSouth']),
      boundsEast: serializer.fromJson<double>(json['boundsEast']),
      boundsWest: serializer.fromJson<double>(json['boundsWest']),
      layerType: serializer.fromJson<String>(json['layerType']),
      minZoom: serializer.fromJson<int?>(json['minZoom']),
      maxZoom: serializer.fromJson<int?>(json['maxZoom']),
      opacity: serializer.fromJson<double>(json['opacity']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'dirPath': serializer.toJson<String>(dirPath),
      'tileCount': serializer.toJson<int>(tileCount),
      'importedAt': serializer.toJson<int>(importedAt),
      'isVisible': serializer.toJson<bool>(isVisible),
      'boundsNorth': serializer.toJson<double>(boundsNorth),
      'boundsSouth': serializer.toJson<double>(boundsSouth),
      'boundsEast': serializer.toJson<double>(boundsEast),
      'boundsWest': serializer.toJson<double>(boundsWest),
      'layerType': serializer.toJson<String>(layerType),
      'minZoom': serializer.toJson<int?>(minZoom),
      'maxZoom': serializer.toJson<int?>(maxZoom),
      'opacity': serializer.toJson<double>(opacity),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
    };
  }

  ImportedOverlayMapData copyWith({
    String? id,
    String? name,
    String? dirPath,
    int? tileCount,
    int? importedAt,
    bool? isVisible,
    double? boundsNorth,
    double? boundsSouth,
    double? boundsEast,
    double? boundsWest,
    String? layerType,
    Value<int?> minZoom = const Value.absent(),
    Value<int?> maxZoom = const Value.absent(),
    double? opacity,
    int? sizeBytes,
  }) => ImportedOverlayMapData(
    id: id ?? this.id,
    name: name ?? this.name,
    dirPath: dirPath ?? this.dirPath,
    tileCount: tileCount ?? this.tileCount,
    importedAt: importedAt ?? this.importedAt,
    isVisible: isVisible ?? this.isVisible,
    boundsNorth: boundsNorth ?? this.boundsNorth,
    boundsSouth: boundsSouth ?? this.boundsSouth,
    boundsEast: boundsEast ?? this.boundsEast,
    boundsWest: boundsWest ?? this.boundsWest,
    layerType: layerType ?? this.layerType,
    minZoom: minZoom.present ? minZoom.value : this.minZoom,
    maxZoom: maxZoom.present ? maxZoom.value : this.maxZoom,
    opacity: opacity ?? this.opacity,
    sizeBytes: sizeBytes ?? this.sizeBytes,
  );
  ImportedOverlayMapData copyWithCompanion(ImportedOverlayMapsCompanion data) {
    return ImportedOverlayMapData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      dirPath: data.dirPath.present ? data.dirPath.value : this.dirPath,
      tileCount: data.tileCount.present ? data.tileCount.value : this.tileCount,
      importedAt:
          data.importedAt.present ? data.importedAt.value : this.importedAt,
      isVisible: data.isVisible.present ? data.isVisible.value : this.isVisible,
      boundsNorth:
          data.boundsNorth.present ? data.boundsNorth.value : this.boundsNorth,
      boundsSouth:
          data.boundsSouth.present ? data.boundsSouth.value : this.boundsSouth,
      boundsEast:
          data.boundsEast.present ? data.boundsEast.value : this.boundsEast,
      boundsWest:
          data.boundsWest.present ? data.boundsWest.value : this.boundsWest,
      layerType: data.layerType.present ? data.layerType.value : this.layerType,
      minZoom: data.minZoom.present ? data.minZoom.value : this.minZoom,
      maxZoom: data.maxZoom.present ? data.maxZoom.value : this.maxZoom,
      opacity: data.opacity.present ? data.opacity.value : this.opacity,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportedOverlayMapData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dirPath: $dirPath, ')
          ..write('tileCount: $tileCount, ')
          ..write('importedAt: $importedAt, ')
          ..write('isVisible: $isVisible, ')
          ..write('boundsNorth: $boundsNorth, ')
          ..write('boundsSouth: $boundsSouth, ')
          ..write('boundsEast: $boundsEast, ')
          ..write('boundsWest: $boundsWest, ')
          ..write('layerType: $layerType, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('opacity: $opacity, ')
          ..write('sizeBytes: $sizeBytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    dirPath,
    tileCount,
    importedAt,
    isVisible,
    boundsNorth,
    boundsSouth,
    boundsEast,
    boundsWest,
    layerType,
    minZoom,
    maxZoom,
    opacity,
    sizeBytes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportedOverlayMapData &&
          other.id == this.id &&
          other.name == this.name &&
          other.dirPath == this.dirPath &&
          other.tileCount == this.tileCount &&
          other.importedAt == this.importedAt &&
          other.isVisible == this.isVisible &&
          other.boundsNorth == this.boundsNorth &&
          other.boundsSouth == this.boundsSouth &&
          other.boundsEast == this.boundsEast &&
          other.boundsWest == this.boundsWest &&
          other.layerType == this.layerType &&
          other.minZoom == this.minZoom &&
          other.maxZoom == this.maxZoom &&
          other.opacity == this.opacity &&
          other.sizeBytes == this.sizeBytes);
}

class ImportedOverlayMapsCompanion
    extends UpdateCompanion<ImportedOverlayMapData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> dirPath;
  final Value<int> tileCount;
  final Value<int> importedAt;
  final Value<bool> isVisible;
  final Value<double> boundsNorth;
  final Value<double> boundsSouth;
  final Value<double> boundsEast;
  final Value<double> boundsWest;
  final Value<String> layerType;
  final Value<int?> minZoom;
  final Value<int?> maxZoom;
  final Value<double> opacity;
  final Value<int> sizeBytes;
  final Value<int> rowid;
  const ImportedOverlayMapsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.dirPath = const Value.absent(),
    this.tileCount = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.isVisible = const Value.absent(),
    this.boundsNorth = const Value.absent(),
    this.boundsSouth = const Value.absent(),
    this.boundsEast = const Value.absent(),
    this.boundsWest = const Value.absent(),
    this.layerType = const Value.absent(),
    this.minZoom = const Value.absent(),
    this.maxZoom = const Value.absent(),
    this.opacity = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportedOverlayMapsCompanion.insert({
    required String id,
    required String name,
    required String dirPath,
    required int tileCount,
    required int importedAt,
    this.isVisible = const Value.absent(),
    required double boundsNorth,
    required double boundsSouth,
    required double boundsEast,
    required double boundsWest,
    this.layerType = const Value.absent(),
    this.minZoom = const Value.absent(),
    this.maxZoom = const Value.absent(),
    this.opacity = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       dirPath = Value(dirPath),
       tileCount = Value(tileCount),
       importedAt = Value(importedAt),
       boundsNorth = Value(boundsNorth),
       boundsSouth = Value(boundsSouth),
       boundsEast = Value(boundsEast),
       boundsWest = Value(boundsWest);
  static Insertable<ImportedOverlayMapData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? dirPath,
    Expression<int>? tileCount,
    Expression<int>? importedAt,
    Expression<bool>? isVisible,
    Expression<double>? boundsNorth,
    Expression<double>? boundsSouth,
    Expression<double>? boundsEast,
    Expression<double>? boundsWest,
    Expression<String>? layerType,
    Expression<int>? minZoom,
    Expression<int>? maxZoom,
    Expression<double>? opacity,
    Expression<int>? sizeBytes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (dirPath != null) 'dir_path': dirPath,
      if (tileCount != null) 'tile_count': tileCount,
      if (importedAt != null) 'imported_at': importedAt,
      if (isVisible != null) 'is_visible': isVisible,
      if (boundsNorth != null) 'bounds_north': boundsNorth,
      if (boundsSouth != null) 'bounds_south': boundsSouth,
      if (boundsEast != null) 'bounds_east': boundsEast,
      if (boundsWest != null) 'bounds_west': boundsWest,
      if (layerType != null) 'layer_type': layerType,
      if (minZoom != null) 'min_zoom': minZoom,
      if (maxZoom != null) 'max_zoom': maxZoom,
      if (opacity != null) 'opacity': opacity,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportedOverlayMapsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? dirPath,
    Value<int>? tileCount,
    Value<int>? importedAt,
    Value<bool>? isVisible,
    Value<double>? boundsNorth,
    Value<double>? boundsSouth,
    Value<double>? boundsEast,
    Value<double>? boundsWest,
    Value<String>? layerType,
    Value<int?>? minZoom,
    Value<int?>? maxZoom,
    Value<double>? opacity,
    Value<int>? sizeBytes,
    Value<int>? rowid,
  }) {
    return ImportedOverlayMapsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      dirPath: dirPath ?? this.dirPath,
      tileCount: tileCount ?? this.tileCount,
      importedAt: importedAt ?? this.importedAt,
      isVisible: isVisible ?? this.isVisible,
      boundsNorth: boundsNorth ?? this.boundsNorth,
      boundsSouth: boundsSouth ?? this.boundsSouth,
      boundsEast: boundsEast ?? this.boundsEast,
      boundsWest: boundsWest ?? this.boundsWest,
      layerType: layerType ?? this.layerType,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      opacity: opacity ?? this.opacity,
      sizeBytes: sizeBytes ?? this.sizeBytes,
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
    if (dirPath.present) {
      map['dir_path'] = Variable<String>(dirPath.value);
    }
    if (tileCount.present) {
      map['tile_count'] = Variable<int>(tileCount.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<int>(importedAt.value);
    }
    if (isVisible.present) {
      map['is_visible'] = Variable<bool>(isVisible.value);
    }
    if (boundsNorth.present) {
      map['bounds_north'] = Variable<double>(boundsNorth.value);
    }
    if (boundsSouth.present) {
      map['bounds_south'] = Variable<double>(boundsSouth.value);
    }
    if (boundsEast.present) {
      map['bounds_east'] = Variable<double>(boundsEast.value);
    }
    if (boundsWest.present) {
      map['bounds_west'] = Variable<double>(boundsWest.value);
    }
    if (layerType.present) {
      map['layer_type'] = Variable<String>(layerType.value);
    }
    if (minZoom.present) {
      map['min_zoom'] = Variable<int>(minZoom.value);
    }
    if (maxZoom.present) {
      map['max_zoom'] = Variable<int>(maxZoom.value);
    }
    if (opacity.present) {
      map['opacity'] = Variable<double>(opacity.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportedOverlayMapsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dirPath: $dirPath, ')
          ..write('tileCount: $tileCount, ')
          ..write('importedAt: $importedAt, ')
          ..write('isVisible: $isVisible, ')
          ..write('boundsNorth: $boundsNorth, ')
          ..write('boundsSouth: $boundsSouth, ')
          ..write('boundsEast: $boundsEast, ')
          ..write('boundsWest: $boundsWest, ')
          ..write('layerType: $layerType, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('opacity: $opacity, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  late final $ChannelsTable channels = $ChannelsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $WaypointsTable waypoints = $WaypointsTable(this);
  late final $CompanionDevicesTable companionDevices = $CompanionDevicesTable(
    this,
  );
  late final $PeersTable peers = $PeersTable(this);
  late final $PeerLocationsTable peerLocations = $PeerLocationsTable(this);
  late final $PeerPositionHistoryTable peerPositionHistory =
      $PeerPositionHistoryTable(this);
  late final $AckRecordsTable ackRecords = $AckRecordsTable(this);
  late final $OfflineMapAreasTable offlineMapAreas = $OfflineMapAreasTable(
    this,
  );
  late final $ImportedOverlayMapsTable importedOverlayMaps =
      $ImportedOverlayMapsTable(this);
  late final ContactsDao contactsDao = ContactsDao(this as AppDatabase);
  late final ChannelsDao channelsDao = ChannelsDao(this as AppDatabase);
  late final MessagesDao messagesDao = MessagesDao(this as AppDatabase);
  late final WaypointsDao waypointsDao = WaypointsDao(this as AppDatabase);
  late final AckRecordsDao ackRecordsDao = AckRecordsDao(this as AppDatabase);
  late final CompanionDevicesDao companionDevicesDao = CompanionDevicesDao(
    this as AppDatabase,
  );
  late final OfflineMapAreasDao offlineMapAreasDao = OfflineMapAreasDao(
    this as AppDatabase,
  );
  late final ImportedOverlayMapsDao importedOverlayMapsDao =
      ImportedOverlayMapsDao(this as AppDatabase);
  late final PeersDao peersDao = PeersDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    contacts,
    channels,
    messages,
    waypoints,
    companionDevices,
    peers,
    peerLocations,
    peerPositionHistory,
    ackRecords,
    offlineMapAreas,
    importedOverlayMaps,
  ];
}

typedef $$ContactsTableCreateCompanionBuilder =
    ContactsCompanion Function({
      required Uint8List publicKey,
      required int hash,
      Value<String?> name,
      Value<double?> latitude,
      Value<double?> longitude,
      required int lastSeen,
      Value<int?> companionBatteryMilliVolts,
      Value<int?> phoneBatteryMilliVolts,
      Value<bool> isRepeater,
      Value<bool> isRoomServer,
      Value<bool> isDirect,
      Value<int> hopCount,
      Value<int?> lastTelemetryChannelIdx,
      Value<int?> lastTelemetryTimestamp,
      Value<bool> isOutOfRange,
      Value<bool> isAutonomousDevice,
      Value<String?> companionDeviceKey,
      Value<bool> isFavorite,
      Value<int> rowid,
    });
typedef $$ContactsTableUpdateCompanionBuilder =
    ContactsCompanion Function({
      Value<Uint8List> publicKey,
      Value<int> hash,
      Value<String?> name,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<int> lastSeen,
      Value<int?> companionBatteryMilliVolts,
      Value<int?> phoneBatteryMilliVolts,
      Value<bool> isRepeater,
      Value<bool> isRoomServer,
      Value<bool> isDirect,
      Value<int> hopCount,
      Value<int?> lastTelemetryChannelIdx,
      Value<int?> lastTelemetryTimestamp,
      Value<bool> isOutOfRange,
      Value<bool> isAutonomousDevice,
      Value<String?> companionDeviceKey,
      Value<bool> isFavorite,
      Value<int> rowid,
    });

class $$ContactsTableFilterComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<Uint8List> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get companionBatteryMilliVolts => $composableBuilder(
    column: $table.companionBatteryMilliVolts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get phoneBatteryMilliVolts => $composableBuilder(
    column: $table.phoneBatteryMilliVolts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRepeater => $composableBuilder(
    column: $table.isRepeater,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRoomServer => $composableBuilder(
    column: $table.isRoomServer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirect => $composableBuilder(
    column: $table.isDirect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hopCount => $composableBuilder(
    column: $table.hopCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastTelemetryChannelIdx => $composableBuilder(
    column: $table.lastTelemetryChannelIdx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastTelemetryTimestamp => $composableBuilder(
    column: $table.lastTelemetryTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOutOfRange => $composableBuilder(
    column: $table.isOutOfRange,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAutonomousDevice => $composableBuilder(
    column: $table.isAutonomousDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companionDeviceKey => $composableBuilder(
    column: $table.companionDeviceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContactsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get companionBatteryMilliVolts => $composableBuilder(
    column: $table.companionBatteryMilliVolts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get phoneBatteryMilliVolts => $composableBuilder(
    column: $table.phoneBatteryMilliVolts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRepeater => $composableBuilder(
    column: $table.isRepeater,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRoomServer => $composableBuilder(
    column: $table.isRoomServer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirect => $composableBuilder(
    column: $table.isDirect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hopCount => $composableBuilder(
    column: $table.hopCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastTelemetryChannelIdx => $composableBuilder(
    column: $table.lastTelemetryChannelIdx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastTelemetryTimestamp => $composableBuilder(
    column: $table.lastTelemetryTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOutOfRange => $composableBuilder(
    column: $table.isOutOfRange,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAutonomousDevice => $composableBuilder(
    column: $table.isAutonomousDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companionDeviceKey => $composableBuilder(
    column: $table.companionDeviceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<Uint8List> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);

  GeneratedColumn<int> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<int> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);

  GeneratedColumn<int> get companionBatteryMilliVolts => $composableBuilder(
    column: $table.companionBatteryMilliVolts,
    builder: (column) => column,
  );

  GeneratedColumn<int> get phoneBatteryMilliVolts => $composableBuilder(
    column: $table.phoneBatteryMilliVolts,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRepeater => $composableBuilder(
    column: $table.isRepeater,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRoomServer => $composableBuilder(
    column: $table.isRoomServer,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDirect =>
      $composableBuilder(column: $table.isDirect, builder: (column) => column);

  GeneratedColumn<int> get hopCount =>
      $composableBuilder(column: $table.hopCount, builder: (column) => column);

  GeneratedColumn<int> get lastTelemetryChannelIdx => $composableBuilder(
    column: $table.lastTelemetryChannelIdx,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastTelemetryTimestamp => $composableBuilder(
    column: $table.lastTelemetryTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOutOfRange => $composableBuilder(
    column: $table.isOutOfRange,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAutonomousDevice => $composableBuilder(
    column: $table.isAutonomousDevice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get companionDeviceKey => $composableBuilder(
    column: $table.companionDeviceKey,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );
}

class $$ContactsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContactsTable,
          ContactData,
          $$ContactsTableFilterComposer,
          $$ContactsTableOrderingComposer,
          $$ContactsTableAnnotationComposer,
          $$ContactsTableCreateCompanionBuilder,
          $$ContactsTableUpdateCompanionBuilder,
          (
            ContactData,
            BaseReferences<_$AppDatabase, $ContactsTable, ContactData>,
          ),
          ContactData,
          PrefetchHooks Function()
        > {
  $$ContactsTableTableManager(_$AppDatabase db, $ContactsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Uint8List> publicKey = const Value.absent(),
                Value<int> hash = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<int> lastSeen = const Value.absent(),
                Value<int?> companionBatteryMilliVolts = const Value.absent(),
                Value<int?> phoneBatteryMilliVolts = const Value.absent(),
                Value<bool> isRepeater = const Value.absent(),
                Value<bool> isRoomServer = const Value.absent(),
                Value<bool> isDirect = const Value.absent(),
                Value<int> hopCount = const Value.absent(),
                Value<int?> lastTelemetryChannelIdx = const Value.absent(),
                Value<int?> lastTelemetryTimestamp = const Value.absent(),
                Value<bool> isOutOfRange = const Value.absent(),
                Value<bool> isAutonomousDevice = const Value.absent(),
                Value<String?> companionDeviceKey = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactsCompanion(
                publicKey: publicKey,
                hash: hash,
                name: name,
                latitude: latitude,
                longitude: longitude,
                lastSeen: lastSeen,
                companionBatteryMilliVolts: companionBatteryMilliVolts,
                phoneBatteryMilliVolts: phoneBatteryMilliVolts,
                isRepeater: isRepeater,
                isRoomServer: isRoomServer,
                isDirect: isDirect,
                hopCount: hopCount,
                lastTelemetryChannelIdx: lastTelemetryChannelIdx,
                lastTelemetryTimestamp: lastTelemetryTimestamp,
                isOutOfRange: isOutOfRange,
                isAutonomousDevice: isAutonomousDevice,
                companionDeviceKey: companionDeviceKey,
                isFavorite: isFavorite,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uint8List publicKey,
                required int hash,
                Value<String?> name = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                required int lastSeen,
                Value<int?> companionBatteryMilliVolts = const Value.absent(),
                Value<int?> phoneBatteryMilliVolts = const Value.absent(),
                Value<bool> isRepeater = const Value.absent(),
                Value<bool> isRoomServer = const Value.absent(),
                Value<bool> isDirect = const Value.absent(),
                Value<int> hopCount = const Value.absent(),
                Value<int?> lastTelemetryChannelIdx = const Value.absent(),
                Value<int?> lastTelemetryTimestamp = const Value.absent(),
                Value<bool> isOutOfRange = const Value.absent(),
                Value<bool> isAutonomousDevice = const Value.absent(),
                Value<String?> companionDeviceKey = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactsCompanion.insert(
                publicKey: publicKey,
                hash: hash,
                name: name,
                latitude: latitude,
                longitude: longitude,
                lastSeen: lastSeen,
                companionBatteryMilliVolts: companionBatteryMilliVolts,
                phoneBatteryMilliVolts: phoneBatteryMilliVolts,
                isRepeater: isRepeater,
                isRoomServer: isRoomServer,
                isDirect: isDirect,
                hopCount: hopCount,
                lastTelemetryChannelIdx: lastTelemetryChannelIdx,
                lastTelemetryTimestamp: lastTelemetryTimestamp,
                isOutOfRange: isOutOfRange,
                isAutonomousDevice: isAutonomousDevice,
                companionDeviceKey: companionDeviceKey,
                isFavorite: isFavorite,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContactsTable,
      ContactData,
      $$ContactsTableFilterComposer,
      $$ContactsTableOrderingComposer,
      $$ContactsTableAnnotationComposer,
      $$ContactsTableCreateCompanionBuilder,
      $$ContactsTableUpdateCompanionBuilder,
      (ContactData, BaseReferences<_$AppDatabase, $ContactsTable, ContactData>),
      ContactData,
      PrefetchHooks Function()
    >;
typedef $$ChannelsTableCreateCompanionBuilder =
    ChannelsCompanion Function({
      Value<int> hash,
      required String name,
      required Uint8List sharedKey,
      required bool isPublic,
      Value<bool> shareLocation,
      required int channelIndex,
      required int createdAt,
      Value<String> notificationMode,
      Value<bool> isFavorite,
      Value<String?> companionDeviceKey,
    });
typedef $$ChannelsTableUpdateCompanionBuilder =
    ChannelsCompanion Function({
      Value<int> hash,
      Value<String> name,
      Value<Uint8List> sharedKey,
      Value<bool> isPublic,
      Value<bool> shareLocation,
      Value<int> channelIndex,
      Value<int> createdAt,
      Value<String> notificationMode,
      Value<bool> isFavorite,
      Value<String?> companionDeviceKey,
    });

class $$ChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get sharedKey => $composableBuilder(
    column: $table.sharedKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPublic => $composableBuilder(
    column: $table.isPublic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get shareLocation => $composableBuilder(
    column: $table.shareLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get channelIndex => $composableBuilder(
    column: $table.channelIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notificationMode => $composableBuilder(
    column: $table.notificationMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companionDeviceKey => $composableBuilder(
    column: $table.companionDeviceKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get sharedKey => $composableBuilder(
    column: $table.sharedKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPublic => $composableBuilder(
    column: $table.isPublic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get shareLocation => $composableBuilder(
    column: $table.shareLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get channelIndex => $composableBuilder(
    column: $table.channelIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notificationMode => $composableBuilder(
    column: $table.notificationMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companionDeviceKey => $composableBuilder(
    column: $table.companionDeviceKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<Uint8List> get sharedKey =>
      $composableBuilder(column: $table.sharedKey, builder: (column) => column);

  GeneratedColumn<bool> get isPublic =>
      $composableBuilder(column: $table.isPublic, builder: (column) => column);

  GeneratedColumn<bool> get shareLocation => $composableBuilder(
    column: $table.shareLocation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get channelIndex => $composableBuilder(
    column: $table.channelIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get notificationMode => $composableBuilder(
    column: $table.notificationMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get companionDeviceKey => $composableBuilder(
    column: $table.companionDeviceKey,
    builder: (column) => column,
  );
}

class $$ChannelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChannelsTable,
          ChannelData,
          $$ChannelsTableFilterComposer,
          $$ChannelsTableOrderingComposer,
          $$ChannelsTableAnnotationComposer,
          $$ChannelsTableCreateCompanionBuilder,
          $$ChannelsTableUpdateCompanionBuilder,
          (
            ChannelData,
            BaseReferences<_$AppDatabase, $ChannelsTable, ChannelData>,
          ),
          ChannelData,
          PrefetchHooks Function()
        > {
  $$ChannelsTableTableManager(_$AppDatabase db, $ChannelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> hash = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<Uint8List> sharedKey = const Value.absent(),
                Value<bool> isPublic = const Value.absent(),
                Value<bool> shareLocation = const Value.absent(),
                Value<int> channelIndex = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> notificationMode = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> companionDeviceKey = const Value.absent(),
              }) => ChannelsCompanion(
                hash: hash,
                name: name,
                sharedKey: sharedKey,
                isPublic: isPublic,
                shareLocation: shareLocation,
                channelIndex: channelIndex,
                createdAt: createdAt,
                notificationMode: notificationMode,
                isFavorite: isFavorite,
                companionDeviceKey: companionDeviceKey,
              ),
          createCompanionCallback:
              ({
                Value<int> hash = const Value.absent(),
                required String name,
                required Uint8List sharedKey,
                required bool isPublic,
                Value<bool> shareLocation = const Value.absent(),
                required int channelIndex,
                required int createdAt,
                Value<String> notificationMode = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> companionDeviceKey = const Value.absent(),
              }) => ChannelsCompanion.insert(
                hash: hash,
                name: name,
                sharedKey: sharedKey,
                isPublic: isPublic,
                shareLocation: shareLocation,
                channelIndex: channelIndex,
                createdAt: createdAt,
                notificationMode: notificationMode,
                isFavorite: isFavorite,
                companionDeviceKey: companionDeviceKey,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChannelsTable,
      ChannelData,
      $$ChannelsTableFilterComposer,
      $$ChannelsTableOrderingComposer,
      $$ChannelsTableAnnotationComposer,
      $$ChannelsTableCreateCompanionBuilder,
      $$ChannelsTableUpdateCompanionBuilder,
      (ChannelData, BaseReferences<_$AppDatabase, $ChannelsTable, ChannelData>),
      ChannelData,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      required String id,
      required Uint8List senderId,
      Value<String?> senderName,
      required int channelHash,
      required String content,
      required int timestamp,
      required bool isPrivate,
      Value<Uint8List?> ackChecksum,
      required String deliveryStatus,
      Value<int> heardByCount,
      Value<int> attempt,
      required bool isSentByMe,
      Value<bool> isRead,
      Value<String?> companionDeviceKey,
      Value<int?> senderPeerId,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> id,
      Value<Uint8List> senderId,
      Value<String?> senderName,
      Value<int> channelHash,
      Value<String> content,
      Value<int> timestamp,
      Value<bool> isPrivate,
      Value<Uint8List?> ackChecksum,
      Value<String> deliveryStatus,
      Value<int> heardByCount,
      Value<int> attempt,
      Value<bool> isSentByMe,
      Value<bool> isRead,
      Value<String?> companionDeviceKey,
      Value<int?> senderPeerId,
      Value<int> rowid,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get channelHash => $composableBuilder(
    column: $table.channelHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrivate => $composableBuilder(
    column: $table.isPrivate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get ackChecksum => $composableBuilder(
    column: $table.ackChecksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryStatus => $composableBuilder(
    column: $table.deliveryStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heardByCount => $composableBuilder(
    column: $table.heardByCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSentByMe => $composableBuilder(
    column: $table.isSentByMe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companionDeviceKey => $composableBuilder(
    column: $table.companionDeviceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get senderPeerId => $composableBuilder(
    column: $table.senderPeerId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get channelHash => $composableBuilder(
    column: $table.channelHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrivate => $composableBuilder(
    column: $table.isPrivate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get ackChecksum => $composableBuilder(
    column: $table.ackChecksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryStatus => $composableBuilder(
    column: $table.deliveryStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heardByCount => $composableBuilder(
    column: $table.heardByCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSentByMe => $composableBuilder(
    column: $table.isSentByMe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companionDeviceKey => $composableBuilder(
    column: $table.companionDeviceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get senderPeerId => $composableBuilder(
    column: $table.senderPeerId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<Uint8List> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get channelHash => $composableBuilder(
    column: $table.channelHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get isPrivate =>
      $composableBuilder(column: $table.isPrivate, builder: (column) => column);

  GeneratedColumn<Uint8List> get ackChecksum => $composableBuilder(
    column: $table.ackChecksum,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryStatus => $composableBuilder(
    column: $table.deliveryStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get heardByCount => $composableBuilder(
    column: $table.heardByCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempt =>
      $composableBuilder(column: $table.attempt, builder: (column) => column);

  GeneratedColumn<bool> get isSentByMe => $composableBuilder(
    column: $table.isSentByMe,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<String> get companionDeviceKey => $composableBuilder(
    column: $table.companionDeviceKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get senderPeerId => $composableBuilder(
    column: $table.senderPeerId,
    builder: (column) => column,
  );
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          MessageData,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (
            MessageData,
            BaseReferences<_$AppDatabase, $MessagesTable, MessageData>,
          ),
          MessageData,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<Uint8List> senderId = const Value.absent(),
                Value<String?> senderName = const Value.absent(),
                Value<int> channelHash = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<bool> isPrivate = const Value.absent(),
                Value<Uint8List?> ackChecksum = const Value.absent(),
                Value<String> deliveryStatus = const Value.absent(),
                Value<int> heardByCount = const Value.absent(),
                Value<int> attempt = const Value.absent(),
                Value<bool> isSentByMe = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<String?> companionDeviceKey = const Value.absent(),
                Value<int?> senderPeerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                senderId: senderId,
                senderName: senderName,
                channelHash: channelHash,
                content: content,
                timestamp: timestamp,
                isPrivate: isPrivate,
                ackChecksum: ackChecksum,
                deliveryStatus: deliveryStatus,
                heardByCount: heardByCount,
                attempt: attempt,
                isSentByMe: isSentByMe,
                isRead: isRead,
                companionDeviceKey: companionDeviceKey,
                senderPeerId: senderPeerId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required Uint8List senderId,
                Value<String?> senderName = const Value.absent(),
                required int channelHash,
                required String content,
                required int timestamp,
                required bool isPrivate,
                Value<Uint8List?> ackChecksum = const Value.absent(),
                required String deliveryStatus,
                Value<int> heardByCount = const Value.absent(),
                Value<int> attempt = const Value.absent(),
                required bool isSentByMe,
                Value<bool> isRead = const Value.absent(),
                Value<String?> companionDeviceKey = const Value.absent(),
                Value<int?> senderPeerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                senderId: senderId,
                senderName: senderName,
                channelHash: channelHash,
                content: content,
                timestamp: timestamp,
                isPrivate: isPrivate,
                ackChecksum: ackChecksum,
                deliveryStatus: deliveryStatus,
                heardByCount: heardByCount,
                attempt: attempt,
                isSentByMe: isSentByMe,
                isRead: isRead,
                companionDeviceKey: companionDeviceKey,
                senderPeerId: senderPeerId,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      MessageData,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (MessageData, BaseReferences<_$AppDatabase, $MessagesTable, MessageData>),
      MessageData,
      PrefetchHooks Function()
    >;
typedef $$WaypointsTableCreateCompanionBuilder =
    WaypointsCompanion Function({
      required String id,
      Value<String?> meshId,
      required String name,
      Value<String> description,
      required double latitude,
      required double longitude,
      required String waypointType,
      required String creatorNodeId,
      required int createdAt,
      Value<bool> isReceived,
      Value<bool> isVisible,
      Value<bool> isNew,
      Value<int> rowid,
    });
typedef $$WaypointsTableUpdateCompanionBuilder =
    WaypointsCompanion Function({
      Value<String> id,
      Value<String?> meshId,
      Value<String> name,
      Value<String> description,
      Value<double> latitude,
      Value<double> longitude,
      Value<String> waypointType,
      Value<String> creatorNodeId,
      Value<int> createdAt,
      Value<bool> isReceived,
      Value<bool> isVisible,
      Value<bool> isNew,
      Value<int> rowid,
    });

class $$WaypointsTableFilterComposer
    extends Composer<_$AppDatabase, $WaypointsTable> {
  $$WaypointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meshId => $composableBuilder(
    column: $table.meshId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get waypointType => $composableBuilder(
    column: $table.waypointType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creatorNodeId => $composableBuilder(
    column: $table.creatorNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isReceived => $composableBuilder(
    column: $table.isReceived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVisible => $composableBuilder(
    column: $table.isVisible,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isNew => $composableBuilder(
    column: $table.isNew,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WaypointsTableOrderingComposer
    extends Composer<_$AppDatabase, $WaypointsTable> {
  $$WaypointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meshId => $composableBuilder(
    column: $table.meshId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waypointType => $composableBuilder(
    column: $table.waypointType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorNodeId => $composableBuilder(
    column: $table.creatorNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isReceived => $composableBuilder(
    column: $table.isReceived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVisible => $composableBuilder(
    column: $table.isVisible,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isNew => $composableBuilder(
    column: $table.isNew,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WaypointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WaypointsTable> {
  $$WaypointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get meshId =>
      $composableBuilder(column: $table.meshId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get waypointType => $composableBuilder(
    column: $table.waypointType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get creatorNodeId => $composableBuilder(
    column: $table.creatorNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isReceived => $composableBuilder(
    column: $table.isReceived,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isVisible =>
      $composableBuilder(column: $table.isVisible, builder: (column) => column);

  GeneratedColumn<bool> get isNew =>
      $composableBuilder(column: $table.isNew, builder: (column) => column);
}

class $$WaypointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WaypointsTable,
          WaypointData,
          $$WaypointsTableFilterComposer,
          $$WaypointsTableOrderingComposer,
          $$WaypointsTableAnnotationComposer,
          $$WaypointsTableCreateCompanionBuilder,
          $$WaypointsTableUpdateCompanionBuilder,
          (
            WaypointData,
            BaseReferences<_$AppDatabase, $WaypointsTable, WaypointData>,
          ),
          WaypointData,
          PrefetchHooks Function()
        > {
  $$WaypointsTableTableManager(_$AppDatabase db, $WaypointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$WaypointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$WaypointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$WaypointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> meshId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<String> waypointType = const Value.absent(),
                Value<String> creatorNodeId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<bool> isReceived = const Value.absent(),
                Value<bool> isVisible = const Value.absent(),
                Value<bool> isNew = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WaypointsCompanion(
                id: id,
                meshId: meshId,
                name: name,
                description: description,
                latitude: latitude,
                longitude: longitude,
                waypointType: waypointType,
                creatorNodeId: creatorNodeId,
                createdAt: createdAt,
                isReceived: isReceived,
                isVisible: isVisible,
                isNew: isNew,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> meshId = const Value.absent(),
                required String name,
                Value<String> description = const Value.absent(),
                required double latitude,
                required double longitude,
                required String waypointType,
                required String creatorNodeId,
                required int createdAt,
                Value<bool> isReceived = const Value.absent(),
                Value<bool> isVisible = const Value.absent(),
                Value<bool> isNew = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WaypointsCompanion.insert(
                id: id,
                meshId: meshId,
                name: name,
                description: description,
                latitude: latitude,
                longitude: longitude,
                waypointType: waypointType,
                creatorNodeId: creatorNodeId,
                createdAt: createdAt,
                isReceived: isReceived,
                isVisible: isVisible,
                isNew: isNew,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WaypointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WaypointsTable,
      WaypointData,
      $$WaypointsTableFilterComposer,
      $$WaypointsTableOrderingComposer,
      $$WaypointsTableAnnotationComposer,
      $$WaypointsTableCreateCompanionBuilder,
      $$WaypointsTableUpdateCompanionBuilder,
      (
        WaypointData,
        BaseReferences<_$AppDatabase, $WaypointsTable, WaypointData>,
      ),
      WaypointData,
      PrefetchHooks Function()
    >;
typedef $$CompanionDevicesTableCreateCompanionBuilder =
    CompanionDevicesCompanion Function({
      required String publicKeyHex,
      required String name,
      required int firstConnected,
      required int lastConnected,
      Value<int> connectionCount,
      Value<int> rowid,
    });
typedef $$CompanionDevicesTableUpdateCompanionBuilder =
    CompanionDevicesCompanion Function({
      Value<String> publicKeyHex,
      Value<String> name,
      Value<int> firstConnected,
      Value<int> lastConnected,
      Value<int> connectionCount,
      Value<int> rowid,
    });

class $$CompanionDevicesTableFilterComposer
    extends Composer<_$AppDatabase, $CompanionDevicesTable> {
  $$CompanionDevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get publicKeyHex => $composableBuilder(
    column: $table.publicKeyHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstConnected => $composableBuilder(
    column: $table.firstConnected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastConnected => $composableBuilder(
    column: $table.lastConnected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get connectionCount => $composableBuilder(
    column: $table.connectionCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CompanionDevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $CompanionDevicesTable> {
  $$CompanionDevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get publicKeyHex => $composableBuilder(
    column: $table.publicKeyHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstConnected => $composableBuilder(
    column: $table.firstConnected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastConnected => $composableBuilder(
    column: $table.lastConnected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get connectionCount => $composableBuilder(
    column: $table.connectionCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CompanionDevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompanionDevicesTable> {
  $$CompanionDevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get publicKeyHex => $composableBuilder(
    column: $table.publicKeyHex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get firstConnected => $composableBuilder(
    column: $table.firstConnected,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastConnected => $composableBuilder(
    column: $table.lastConnected,
    builder: (column) => column,
  );

  GeneratedColumn<int> get connectionCount => $composableBuilder(
    column: $table.connectionCount,
    builder: (column) => column,
  );
}

class $$CompanionDevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompanionDevicesTable,
          CompanionDeviceData,
          $$CompanionDevicesTableFilterComposer,
          $$CompanionDevicesTableOrderingComposer,
          $$CompanionDevicesTableAnnotationComposer,
          $$CompanionDevicesTableCreateCompanionBuilder,
          $$CompanionDevicesTableUpdateCompanionBuilder,
          (
            CompanionDeviceData,
            BaseReferences<
              _$AppDatabase,
              $CompanionDevicesTable,
              CompanionDeviceData
            >,
          ),
          CompanionDeviceData,
          PrefetchHooks Function()
        > {
  $$CompanionDevicesTableTableManager(
    _$AppDatabase db,
    $CompanionDevicesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$CompanionDevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CompanionDevicesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$CompanionDevicesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> publicKeyHex = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> firstConnected = const Value.absent(),
                Value<int> lastConnected = const Value.absent(),
                Value<int> connectionCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompanionDevicesCompanion(
                publicKeyHex: publicKeyHex,
                name: name,
                firstConnected: firstConnected,
                lastConnected: lastConnected,
                connectionCount: connectionCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String publicKeyHex,
                required String name,
                required int firstConnected,
                required int lastConnected,
                Value<int> connectionCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompanionDevicesCompanion.insert(
                publicKeyHex: publicKeyHex,
                name: name,
                firstConnected: firstConnected,
                lastConnected: lastConnected,
                connectionCount: connectionCount,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CompanionDevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompanionDevicesTable,
      CompanionDeviceData,
      $$CompanionDevicesTableFilterComposer,
      $$CompanionDevicesTableOrderingComposer,
      $$CompanionDevicesTableAnnotationComposer,
      $$CompanionDevicesTableCreateCompanionBuilder,
      $$CompanionDevicesTableUpdateCompanionBuilder,
      (
        CompanionDeviceData,
        BaseReferences<
          _$AppDatabase,
          $CompanionDevicesTable,
          CompanionDeviceData
        >,
      ),
      CompanionDeviceData,
      PrefetchHooks Function()
    >;
typedef $$PeersTableCreateCompanionBuilder =
    PeersCompanion Function({
      Value<int> id,
      Value<Uint8List?> radioPublicKey,
      Value<String?> radioKeyPrefix,
      Value<String?> appIdentityId,
      Value<String?> radioName,
      Value<String?> alias,
      Value<int?> aliasUpdatedAt,
      Value<int?> capFlags,
      Value<int?> capObservedAt,
      Value<bool> isTeamMember,
      Value<int?> lastTeamChannelHash,
      required int firstSeen,
      required int lastSeen,
    });
typedef $$PeersTableUpdateCompanionBuilder =
    PeersCompanion Function({
      Value<int> id,
      Value<Uint8List?> radioPublicKey,
      Value<String?> radioKeyPrefix,
      Value<String?> appIdentityId,
      Value<String?> radioName,
      Value<String?> alias,
      Value<int?> aliasUpdatedAt,
      Value<int?> capFlags,
      Value<int?> capObservedAt,
      Value<bool> isTeamMember,
      Value<int?> lastTeamChannelHash,
      Value<int> firstSeen,
      Value<int> lastSeen,
    });

final class $$PeersTableReferences
    extends BaseReferences<_$AppDatabase, $PeersTable, PeerData> {
  $$PeersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PeerLocationsTable, List<PeerLocationData>>
  _peerLocationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.peerLocations,
    aliasName: $_aliasNameGenerator(db.peers.id, db.peerLocations.peerId),
  );

  $$PeerLocationsTableProcessedTableManager get peerLocationsRefs {
    final manager = $$PeerLocationsTableTableManager(
      $_db,
      $_db.peerLocations,
    ).filter((f) => f.peerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_peerLocationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PeerPositionHistoryTable, List<PeerPositionData>>
  _peerPositionHistoryRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.peerPositionHistory,
        aliasName: $_aliasNameGenerator(
          db.peers.id,
          db.peerPositionHistory.peerId,
        ),
      );

  $$PeerPositionHistoryTableProcessedTableManager get peerPositionHistoryRefs {
    final manager = $$PeerPositionHistoryTableTableManager(
      $_db,
      $_db.peerPositionHistory,
    ).filter((f) => f.peerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _peerPositionHistoryRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PeersTableFilterComposer extends Composer<_$AppDatabase, $PeersTable> {
  $$PeersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get radioPublicKey => $composableBuilder(
    column: $table.radioPublicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get radioKeyPrefix => $composableBuilder(
    column: $table.radioKeyPrefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appIdentityId => $composableBuilder(
    column: $table.appIdentityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get radioName => $composableBuilder(
    column: $table.radioName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get aliasUpdatedAt => $composableBuilder(
    column: $table.aliasUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get capFlags => $composableBuilder(
    column: $table.capFlags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get capObservedAt => $composableBuilder(
    column: $table.capObservedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTeamMember => $composableBuilder(
    column: $table.isTeamMember,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastTeamChannelHash => $composableBuilder(
    column: $table.lastTeamChannelHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstSeen => $composableBuilder(
    column: $table.firstSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> peerLocationsRefs(
    Expression<bool> Function($$PeerLocationsTableFilterComposer f) f,
  ) {
    final $$PeerLocationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.peerLocations,
      getReferencedColumn: (t) => t.peerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeerLocationsTableFilterComposer(
            $db: $db,
            $table: $db.peerLocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> peerPositionHistoryRefs(
    Expression<bool> Function($$PeerPositionHistoryTableFilterComposer f) f,
  ) {
    final $$PeerPositionHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.peerPositionHistory,
      getReferencedColumn: (t) => t.peerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeerPositionHistoryTableFilterComposer(
            $db: $db,
            $table: $db.peerPositionHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeersTableOrderingComposer
    extends Composer<_$AppDatabase, $PeersTable> {
  $$PeersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get radioPublicKey => $composableBuilder(
    column: $table.radioPublicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get radioKeyPrefix => $composableBuilder(
    column: $table.radioKeyPrefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appIdentityId => $composableBuilder(
    column: $table.appIdentityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get radioName => $composableBuilder(
    column: $table.radioName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get aliasUpdatedAt => $composableBuilder(
    column: $table.aliasUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get capFlags => $composableBuilder(
    column: $table.capFlags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get capObservedAt => $composableBuilder(
    column: $table.capObservedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTeamMember => $composableBuilder(
    column: $table.isTeamMember,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastTeamChannelHash => $composableBuilder(
    column: $table.lastTeamChannelHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstSeen => $composableBuilder(
    column: $table.firstSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeersTable> {
  $$PeersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<Uint8List> get radioPublicKey => $composableBuilder(
    column: $table.radioPublicKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get radioKeyPrefix => $composableBuilder(
    column: $table.radioKeyPrefix,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appIdentityId => $composableBuilder(
    column: $table.appIdentityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get radioName =>
      $composableBuilder(column: $table.radioName, builder: (column) => column);

  GeneratedColumn<String> get alias =>
      $composableBuilder(column: $table.alias, builder: (column) => column);

  GeneratedColumn<int> get aliasUpdatedAt => $composableBuilder(
    column: $table.aliasUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get capFlags =>
      $composableBuilder(column: $table.capFlags, builder: (column) => column);

  GeneratedColumn<int> get capObservedAt => $composableBuilder(
    column: $table.capObservedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTeamMember => $composableBuilder(
    column: $table.isTeamMember,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastTeamChannelHash => $composableBuilder(
    column: $table.lastTeamChannelHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get firstSeen =>
      $composableBuilder(column: $table.firstSeen, builder: (column) => column);

  GeneratedColumn<int> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);

  Expression<T> peerLocationsRefs<T extends Object>(
    Expression<T> Function($$PeerLocationsTableAnnotationComposer a) f,
  ) {
    final $$PeerLocationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.peerLocations,
      getReferencedColumn: (t) => t.peerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeerLocationsTableAnnotationComposer(
            $db: $db,
            $table: $db.peerLocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> peerPositionHistoryRefs<T extends Object>(
    Expression<T> Function($$PeerPositionHistoryTableAnnotationComposer a) f,
  ) {
    final $$PeerPositionHistoryTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.peerPositionHistory,
          getReferencedColumn: (t) => t.peerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PeerPositionHistoryTableAnnotationComposer(
                $db: $db,
                $table: $db.peerPositionHistory,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PeersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeersTable,
          PeerData,
          $$PeersTableFilterComposer,
          $$PeersTableOrderingComposer,
          $$PeersTableAnnotationComposer,
          $$PeersTableCreateCompanionBuilder,
          $$PeersTableUpdateCompanionBuilder,
          (PeerData, $$PeersTableReferences),
          PeerData,
          PrefetchHooks Function({
            bool peerLocationsRefs,
            bool peerPositionHistoryRefs,
          })
        > {
  $$PeersTableTableManager(_$AppDatabase db, $PeersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PeersTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$PeersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$PeersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<Uint8List?> radioPublicKey = const Value.absent(),
                Value<String?> radioKeyPrefix = const Value.absent(),
                Value<String?> appIdentityId = const Value.absent(),
                Value<String?> radioName = const Value.absent(),
                Value<String?> alias = const Value.absent(),
                Value<int?> aliasUpdatedAt = const Value.absent(),
                Value<int?> capFlags = const Value.absent(),
                Value<int?> capObservedAt = const Value.absent(),
                Value<bool> isTeamMember = const Value.absent(),
                Value<int?> lastTeamChannelHash = const Value.absent(),
                Value<int> firstSeen = const Value.absent(),
                Value<int> lastSeen = const Value.absent(),
              }) => PeersCompanion(
                id: id,
                radioPublicKey: radioPublicKey,
                radioKeyPrefix: radioKeyPrefix,
                appIdentityId: appIdentityId,
                radioName: radioName,
                alias: alias,
                aliasUpdatedAt: aliasUpdatedAt,
                capFlags: capFlags,
                capObservedAt: capObservedAt,
                isTeamMember: isTeamMember,
                lastTeamChannelHash: lastTeamChannelHash,
                firstSeen: firstSeen,
                lastSeen: lastSeen,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<Uint8List?> radioPublicKey = const Value.absent(),
                Value<String?> radioKeyPrefix = const Value.absent(),
                Value<String?> appIdentityId = const Value.absent(),
                Value<String?> radioName = const Value.absent(),
                Value<String?> alias = const Value.absent(),
                Value<int?> aliasUpdatedAt = const Value.absent(),
                Value<int?> capFlags = const Value.absent(),
                Value<int?> capObservedAt = const Value.absent(),
                Value<bool> isTeamMember = const Value.absent(),
                Value<int?> lastTeamChannelHash = const Value.absent(),
                required int firstSeen,
                required int lastSeen,
              }) => PeersCompanion.insert(
                id: id,
                radioPublicKey: radioPublicKey,
                radioKeyPrefix: radioKeyPrefix,
                appIdentityId: appIdentityId,
                radioName: radioName,
                alias: alias,
                aliasUpdatedAt: aliasUpdatedAt,
                capFlags: capFlags,
                capObservedAt: capObservedAt,
                isTeamMember: isTeamMember,
                lastTeamChannelHash: lastTeamChannelHash,
                firstSeen: firstSeen,
                lastSeen: lastSeen,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$PeersTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({
            peerLocationsRefs = false,
            peerPositionHistoryRefs = false,
          }) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (peerLocationsRefs) db.peerLocations,
                if (peerPositionHistoryRefs) db.peerPositionHistory,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (peerLocationsRefs)
                    await $_getPrefetchedData<
                      PeerData,
                      $PeersTable,
                      PeerLocationData
                    >(
                      currentTable: table,
                      referencedTable: $$PeersTableReferences
                          ._peerLocationsRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$PeersTableReferences(
                                db,
                                table,
                                p0,
                              ).peerLocationsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) =>
                              referencedItems.where((e) => e.peerId == item.id),
                      typedResults: items,
                    ),
                  if (peerPositionHistoryRefs)
                    await $_getPrefetchedData<
                      PeerData,
                      $PeersTable,
                      PeerPositionData
                    >(
                      currentTable: table,
                      referencedTable: $$PeersTableReferences
                          ._peerPositionHistoryRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$PeersTableReferences(
                                db,
                                table,
                                p0,
                              ).peerPositionHistoryRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) =>
                              referencedItems.where((e) => e.peerId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PeersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeersTable,
      PeerData,
      $$PeersTableFilterComposer,
      $$PeersTableOrderingComposer,
      $$PeersTableAnnotationComposer,
      $$PeersTableCreateCompanionBuilder,
      $$PeersTableUpdateCompanionBuilder,
      (PeerData, $$PeersTableReferences),
      PeerData,
      PrefetchHooks Function({
        bool peerLocationsRefs,
        bool peerPositionHistoryRefs,
      })
    >;
typedef $$PeerLocationsTableCreateCompanionBuilder =
    PeerLocationsCompanion Function({
      Value<int> peerId,
      required int lastSeen,
      Value<double?> lastLatitude,
      Value<double?> lastLongitude,
      required int lastChannelHash,
      required int lastPathLen,
      Value<int?> companionBatteryMilliVolts,
      Value<int?> phoneBatteryMilliVolts,
      Value<bool> isAutonomousDevice,
      Value<bool> isManuallyHidden,
      Value<int?> hiddenAt,
      required int firstSeen,
      Value<int> totalTelemetryReceived,
    });
typedef $$PeerLocationsTableUpdateCompanionBuilder =
    PeerLocationsCompanion Function({
      Value<int> peerId,
      Value<int> lastSeen,
      Value<double?> lastLatitude,
      Value<double?> lastLongitude,
      Value<int> lastChannelHash,
      Value<int> lastPathLen,
      Value<int?> companionBatteryMilliVolts,
      Value<int?> phoneBatteryMilliVolts,
      Value<bool> isAutonomousDevice,
      Value<bool> isManuallyHidden,
      Value<int?> hiddenAt,
      Value<int> firstSeen,
      Value<int> totalTelemetryReceived,
    });

final class $$PeerLocationsTableReferences
    extends
        BaseReferences<_$AppDatabase, $PeerLocationsTable, PeerLocationData> {
  $$PeerLocationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PeersTable _peerIdTable(_$AppDatabase db) => db.peers.createAlias(
    $_aliasNameGenerator(db.peerLocations.peerId, db.peers.id),
  );

  $$PeersTableProcessedTableManager get peerId {
    final $_column = $_itemColumn<int>('peer_id')!;

    final manager = $$PeersTableTableManager(
      $_db,
      $_db.peers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_peerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PeerLocationsTableFilterComposer
    extends Composer<_$AppDatabase, $PeerLocationsTable> {
  $$PeerLocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lastLatitude => $composableBuilder(
    column: $table.lastLatitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lastLongitude => $composableBuilder(
    column: $table.lastLongitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastChannelHash => $composableBuilder(
    column: $table.lastChannelHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPathLen => $composableBuilder(
    column: $table.lastPathLen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get companionBatteryMilliVolts => $composableBuilder(
    column: $table.companionBatteryMilliVolts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get phoneBatteryMilliVolts => $composableBuilder(
    column: $table.phoneBatteryMilliVolts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAutonomousDevice => $composableBuilder(
    column: $table.isAutonomousDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isManuallyHidden => $composableBuilder(
    column: $table.isManuallyHidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hiddenAt => $composableBuilder(
    column: $table.hiddenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstSeen => $composableBuilder(
    column: $table.firstSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalTelemetryReceived => $composableBuilder(
    column: $table.totalTelemetryReceived,
    builder: (column) => ColumnFilters(column),
  );

  $$PeersTableFilterComposer get peerId {
    final $$PeersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.peerId,
      referencedTable: $db.peers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeersTableFilterComposer(
            $db: $db,
            $table: $db.peers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeerLocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PeerLocationsTable> {
  $$PeerLocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lastLatitude => $composableBuilder(
    column: $table.lastLatitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lastLongitude => $composableBuilder(
    column: $table.lastLongitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastChannelHash => $composableBuilder(
    column: $table.lastChannelHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPathLen => $composableBuilder(
    column: $table.lastPathLen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get companionBatteryMilliVolts => $composableBuilder(
    column: $table.companionBatteryMilliVolts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get phoneBatteryMilliVolts => $composableBuilder(
    column: $table.phoneBatteryMilliVolts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAutonomousDevice => $composableBuilder(
    column: $table.isAutonomousDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isManuallyHidden => $composableBuilder(
    column: $table.isManuallyHidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hiddenAt => $composableBuilder(
    column: $table.hiddenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstSeen => $composableBuilder(
    column: $table.firstSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalTelemetryReceived => $composableBuilder(
    column: $table.totalTelemetryReceived,
    builder: (column) => ColumnOrderings(column),
  );

  $$PeersTableOrderingComposer get peerId {
    final $$PeersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.peerId,
      referencedTable: $db.peers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeersTableOrderingComposer(
            $db: $db,
            $table: $db.peers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeerLocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeerLocationsTable> {
  $$PeerLocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);

  GeneratedColumn<double> get lastLatitude => $composableBuilder(
    column: $table.lastLatitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lastLongitude => $composableBuilder(
    column: $table.lastLongitude,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastChannelHash => $composableBuilder(
    column: $table.lastChannelHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastPathLen => $composableBuilder(
    column: $table.lastPathLen,
    builder: (column) => column,
  );

  GeneratedColumn<int> get companionBatteryMilliVolts => $composableBuilder(
    column: $table.companionBatteryMilliVolts,
    builder: (column) => column,
  );

  GeneratedColumn<int> get phoneBatteryMilliVolts => $composableBuilder(
    column: $table.phoneBatteryMilliVolts,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAutonomousDevice => $composableBuilder(
    column: $table.isAutonomousDevice,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isManuallyHidden => $composableBuilder(
    column: $table.isManuallyHidden,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hiddenAt =>
      $composableBuilder(column: $table.hiddenAt, builder: (column) => column);

  GeneratedColumn<int> get firstSeen =>
      $composableBuilder(column: $table.firstSeen, builder: (column) => column);

  GeneratedColumn<int> get totalTelemetryReceived => $composableBuilder(
    column: $table.totalTelemetryReceived,
    builder: (column) => column,
  );

  $$PeersTableAnnotationComposer get peerId {
    final $$PeersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.peerId,
      referencedTable: $db.peers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeersTableAnnotationComposer(
            $db: $db,
            $table: $db.peers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeerLocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeerLocationsTable,
          PeerLocationData,
          $$PeerLocationsTableFilterComposer,
          $$PeerLocationsTableOrderingComposer,
          $$PeerLocationsTableAnnotationComposer,
          $$PeerLocationsTableCreateCompanionBuilder,
          $$PeerLocationsTableUpdateCompanionBuilder,
          (PeerLocationData, $$PeerLocationsTableReferences),
          PeerLocationData,
          PrefetchHooks Function({bool peerId})
        > {
  $$PeerLocationsTableTableManager(_$AppDatabase db, $PeerLocationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PeerLocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$PeerLocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$PeerLocationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> peerId = const Value.absent(),
                Value<int> lastSeen = const Value.absent(),
                Value<double?> lastLatitude = const Value.absent(),
                Value<double?> lastLongitude = const Value.absent(),
                Value<int> lastChannelHash = const Value.absent(),
                Value<int> lastPathLen = const Value.absent(),
                Value<int?> companionBatteryMilliVolts = const Value.absent(),
                Value<int?> phoneBatteryMilliVolts = const Value.absent(),
                Value<bool> isAutonomousDevice = const Value.absent(),
                Value<bool> isManuallyHidden = const Value.absent(),
                Value<int?> hiddenAt = const Value.absent(),
                Value<int> firstSeen = const Value.absent(),
                Value<int> totalTelemetryReceived = const Value.absent(),
              }) => PeerLocationsCompanion(
                peerId: peerId,
                lastSeen: lastSeen,
                lastLatitude: lastLatitude,
                lastLongitude: lastLongitude,
                lastChannelHash: lastChannelHash,
                lastPathLen: lastPathLen,
                companionBatteryMilliVolts: companionBatteryMilliVolts,
                phoneBatteryMilliVolts: phoneBatteryMilliVolts,
                isAutonomousDevice: isAutonomousDevice,
                isManuallyHidden: isManuallyHidden,
                hiddenAt: hiddenAt,
                firstSeen: firstSeen,
                totalTelemetryReceived: totalTelemetryReceived,
              ),
          createCompanionCallback:
              ({
                Value<int> peerId = const Value.absent(),
                required int lastSeen,
                Value<double?> lastLatitude = const Value.absent(),
                Value<double?> lastLongitude = const Value.absent(),
                required int lastChannelHash,
                required int lastPathLen,
                Value<int?> companionBatteryMilliVolts = const Value.absent(),
                Value<int?> phoneBatteryMilliVolts = const Value.absent(),
                Value<bool> isAutonomousDevice = const Value.absent(),
                Value<bool> isManuallyHidden = const Value.absent(),
                Value<int?> hiddenAt = const Value.absent(),
                required int firstSeen,
                Value<int> totalTelemetryReceived = const Value.absent(),
              }) => PeerLocationsCompanion.insert(
                peerId: peerId,
                lastSeen: lastSeen,
                lastLatitude: lastLatitude,
                lastLongitude: lastLongitude,
                lastChannelHash: lastChannelHash,
                lastPathLen: lastPathLen,
                companionBatteryMilliVolts: companionBatteryMilliVolts,
                phoneBatteryMilliVolts: phoneBatteryMilliVolts,
                isAutonomousDevice: isAutonomousDevice,
                isManuallyHidden: isManuallyHidden,
                hiddenAt: hiddenAt,
                firstSeen: firstSeen,
                totalTelemetryReceived: totalTelemetryReceived,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$PeerLocationsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({peerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (peerId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.peerId,
                            referencedTable: $$PeerLocationsTableReferences
                                ._peerIdTable(db),
                            referencedColumn:
                                $$PeerLocationsTableReferences
                                    ._peerIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PeerLocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeerLocationsTable,
      PeerLocationData,
      $$PeerLocationsTableFilterComposer,
      $$PeerLocationsTableOrderingComposer,
      $$PeerLocationsTableAnnotationComposer,
      $$PeerLocationsTableCreateCompanionBuilder,
      $$PeerLocationsTableUpdateCompanionBuilder,
      (PeerLocationData, $$PeerLocationsTableReferences),
      PeerLocationData,
      PrefetchHooks Function({bool peerId})
    >;
typedef $$PeerPositionHistoryTableCreateCompanionBuilder =
    PeerPositionHistoryCompanion Function({
      Value<int> id,
      required int peerId,
      required int timestamp,
      required double latitude,
      required double longitude,
      required int channelHash,
      required int pathLen,
    });
typedef $$PeerPositionHistoryTableUpdateCompanionBuilder =
    PeerPositionHistoryCompanion Function({
      Value<int> id,
      Value<int> peerId,
      Value<int> timestamp,
      Value<double> latitude,
      Value<double> longitude,
      Value<int> channelHash,
      Value<int> pathLen,
    });

final class $$PeerPositionHistoryTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PeerPositionHistoryTable,
          PeerPositionData
        > {
  $$PeerPositionHistoryTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PeersTable _peerIdTable(_$AppDatabase db) => db.peers.createAlias(
    $_aliasNameGenerator(db.peerPositionHistory.peerId, db.peers.id),
  );

  $$PeersTableProcessedTableManager get peerId {
    final $_column = $_itemColumn<int>('peer_id')!;

    final manager = $$PeersTableTableManager(
      $_db,
      $_db.peers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_peerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PeerPositionHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $PeerPositionHistoryTable> {
  $$PeerPositionHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get channelHash => $composableBuilder(
    column: $table.channelHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pathLen => $composableBuilder(
    column: $table.pathLen,
    builder: (column) => ColumnFilters(column),
  );

  $$PeersTableFilterComposer get peerId {
    final $$PeersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.peerId,
      referencedTable: $db.peers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeersTableFilterComposer(
            $db: $db,
            $table: $db.peers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeerPositionHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $PeerPositionHistoryTable> {
  $$PeerPositionHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get channelHash => $composableBuilder(
    column: $table.channelHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pathLen => $composableBuilder(
    column: $table.pathLen,
    builder: (column) => ColumnOrderings(column),
  );

  $$PeersTableOrderingComposer get peerId {
    final $$PeersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.peerId,
      referencedTable: $db.peers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeersTableOrderingComposer(
            $db: $db,
            $table: $db.peers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeerPositionHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeerPositionHistoryTable> {
  $$PeerPositionHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<int> get channelHash => $composableBuilder(
    column: $table.channelHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pathLen =>
      $composableBuilder(column: $table.pathLen, builder: (column) => column);

  $$PeersTableAnnotationComposer get peerId {
    final $$PeersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.peerId,
      referencedTable: $db.peers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeersTableAnnotationComposer(
            $db: $db,
            $table: $db.peers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeerPositionHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeerPositionHistoryTable,
          PeerPositionData,
          $$PeerPositionHistoryTableFilterComposer,
          $$PeerPositionHistoryTableOrderingComposer,
          $$PeerPositionHistoryTableAnnotationComposer,
          $$PeerPositionHistoryTableCreateCompanionBuilder,
          $$PeerPositionHistoryTableUpdateCompanionBuilder,
          (PeerPositionData, $$PeerPositionHistoryTableReferences),
          PeerPositionData,
          PrefetchHooks Function({bool peerId})
        > {
  $$PeerPositionHistoryTableTableManager(
    _$AppDatabase db,
    $PeerPositionHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PeerPositionHistoryTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$PeerPositionHistoryTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$PeerPositionHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> peerId = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<int> channelHash = const Value.absent(),
                Value<int> pathLen = const Value.absent(),
              }) => PeerPositionHistoryCompanion(
                id: id,
                peerId: peerId,
                timestamp: timestamp,
                latitude: latitude,
                longitude: longitude,
                channelHash: channelHash,
                pathLen: pathLen,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int peerId,
                required int timestamp,
                required double latitude,
                required double longitude,
                required int channelHash,
                required int pathLen,
              }) => PeerPositionHistoryCompanion.insert(
                id: id,
                peerId: peerId,
                timestamp: timestamp,
                latitude: latitude,
                longitude: longitude,
                channelHash: channelHash,
                pathLen: pathLen,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$PeerPositionHistoryTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({peerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (peerId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.peerId,
                            referencedTable:
                                $$PeerPositionHistoryTableReferences
                                    ._peerIdTable(db),
                            referencedColumn:
                                $$PeerPositionHistoryTableReferences
                                    ._peerIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PeerPositionHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeerPositionHistoryTable,
      PeerPositionData,
      $$PeerPositionHistoryTableFilterComposer,
      $$PeerPositionHistoryTableOrderingComposer,
      $$PeerPositionHistoryTableAnnotationComposer,
      $$PeerPositionHistoryTableCreateCompanionBuilder,
      $$PeerPositionHistoryTableUpdateCompanionBuilder,
      (PeerPositionData, $$PeerPositionHistoryTableReferences),
      PeerPositionData,
      PrefetchHooks Function({bool peerId})
    >;
typedef $$AckRecordsTableCreateCompanionBuilder =
    AckRecordsCompanion Function({
      required String messageId,
      required Uint8List ackerPublicKey,
      required int receivedAt,
      Value<int?> snr,
      Value<int?> rssi,
      Value<String?> companionDeviceKey,
      Value<int> rowid,
    });
typedef $$AckRecordsTableUpdateCompanionBuilder =
    AckRecordsCompanion Function({
      Value<String> messageId,
      Value<Uint8List> ackerPublicKey,
      Value<int> receivedAt,
      Value<int?> snr,
      Value<int?> rssi,
      Value<String?> companionDeviceKey,
      Value<int> rowid,
    });

class $$AckRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $AckRecordsTable> {
  $$AckRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get ackerPublicKey => $composableBuilder(
    column: $table.ackerPublicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snr => $composableBuilder(
    column: $table.snr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rssi => $composableBuilder(
    column: $table.rssi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companionDeviceKey => $composableBuilder(
    column: $table.companionDeviceKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AckRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $AckRecordsTable> {
  $$AckRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get ackerPublicKey => $composableBuilder(
    column: $table.ackerPublicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snr => $composableBuilder(
    column: $table.snr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rssi => $composableBuilder(
    column: $table.rssi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companionDeviceKey => $composableBuilder(
    column: $table.companionDeviceKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AckRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AckRecordsTable> {
  $$AckRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<Uint8List> get ackerPublicKey => $composableBuilder(
    column: $table.ackerPublicKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get snr =>
      $composableBuilder(column: $table.snr, builder: (column) => column);

  GeneratedColumn<int> get rssi =>
      $composableBuilder(column: $table.rssi, builder: (column) => column);

  GeneratedColumn<String> get companionDeviceKey => $composableBuilder(
    column: $table.companionDeviceKey,
    builder: (column) => column,
  );
}

class $$AckRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AckRecordsTable,
          AckRecordData,
          $$AckRecordsTableFilterComposer,
          $$AckRecordsTableOrderingComposer,
          $$AckRecordsTableAnnotationComposer,
          $$AckRecordsTableCreateCompanionBuilder,
          $$AckRecordsTableUpdateCompanionBuilder,
          (
            AckRecordData,
            BaseReferences<_$AppDatabase, $AckRecordsTable, AckRecordData>,
          ),
          AckRecordData,
          PrefetchHooks Function()
        > {
  $$AckRecordsTableTableManager(_$AppDatabase db, $AckRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$AckRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$AckRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$AckRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<Uint8List> ackerPublicKey = const Value.absent(),
                Value<int> receivedAt = const Value.absent(),
                Value<int?> snr = const Value.absent(),
                Value<int?> rssi = const Value.absent(),
                Value<String?> companionDeviceKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AckRecordsCompanion(
                messageId: messageId,
                ackerPublicKey: ackerPublicKey,
                receivedAt: receivedAt,
                snr: snr,
                rssi: rssi,
                companionDeviceKey: companionDeviceKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                required Uint8List ackerPublicKey,
                required int receivedAt,
                Value<int?> snr = const Value.absent(),
                Value<int?> rssi = const Value.absent(),
                Value<String?> companionDeviceKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AckRecordsCompanion.insert(
                messageId: messageId,
                ackerPublicKey: ackerPublicKey,
                receivedAt: receivedAt,
                snr: snr,
                rssi: rssi,
                companionDeviceKey: companionDeviceKey,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AckRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AckRecordsTable,
      AckRecordData,
      $$AckRecordsTableFilterComposer,
      $$AckRecordsTableOrderingComposer,
      $$AckRecordsTableAnnotationComposer,
      $$AckRecordsTableCreateCompanionBuilder,
      $$AckRecordsTableUpdateCompanionBuilder,
      (
        AckRecordData,
        BaseReferences<_$AppDatabase, $AckRecordsTable, AckRecordData>,
      ),
      AckRecordData,
      PrefetchHooks Function()
    >;
typedef $$OfflineMapAreasTableCreateCompanionBuilder =
    OfflineMapAreasCompanion Function({
      required String id,
      required String name,
      required String providerId,
      required double north,
      required double south,
      required double east,
      required double west,
      required int minZoom,
      required int maxZoom,
      required int tileCount,
      required int downloadedAt,
      required int sizeBytes,
      Value<int> rowid,
    });
typedef $$OfflineMapAreasTableUpdateCompanionBuilder =
    OfflineMapAreasCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> providerId,
      Value<double> north,
      Value<double> south,
      Value<double> east,
      Value<double> west,
      Value<int> minZoom,
      Value<int> maxZoom,
      Value<int> tileCount,
      Value<int> downloadedAt,
      Value<int> sizeBytes,
      Value<int> rowid,
    });

class $$OfflineMapAreasTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineMapAreasTable> {
  $$OfflineMapAreasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get north => $composableBuilder(
    column: $table.north,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get south => $composableBuilder(
    column: $table.south,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get east => $composableBuilder(
    column: $table.east,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get west => $composableBuilder(
    column: $table.west,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minZoom => $composableBuilder(
    column: $table.minZoom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxZoom => $composableBuilder(
    column: $table.maxZoom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tileCount => $composableBuilder(
    column: $table.tileCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineMapAreasTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineMapAreasTable> {
  $$OfflineMapAreasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get north => $composableBuilder(
    column: $table.north,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get south => $composableBuilder(
    column: $table.south,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get east => $composableBuilder(
    column: $table.east,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get west => $composableBuilder(
    column: $table.west,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minZoom => $composableBuilder(
    column: $table.minZoom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxZoom => $composableBuilder(
    column: $table.maxZoom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tileCount => $composableBuilder(
    column: $table.tileCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineMapAreasTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineMapAreasTable> {
  $$OfflineMapAreasTableAnnotationComposer({
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

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get north =>
      $composableBuilder(column: $table.north, builder: (column) => column);

  GeneratedColumn<double> get south =>
      $composableBuilder(column: $table.south, builder: (column) => column);

  GeneratedColumn<double> get east =>
      $composableBuilder(column: $table.east, builder: (column) => column);

  GeneratedColumn<double> get west =>
      $composableBuilder(column: $table.west, builder: (column) => column);

  GeneratedColumn<int> get minZoom =>
      $composableBuilder(column: $table.minZoom, builder: (column) => column);

  GeneratedColumn<int> get maxZoom =>
      $composableBuilder(column: $table.maxZoom, builder: (column) => column);

  GeneratedColumn<int> get tileCount =>
      $composableBuilder(column: $table.tileCount, builder: (column) => column);

  GeneratedColumn<int> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);
}

class $$OfflineMapAreasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineMapAreasTable,
          OfflineMapAreaData,
          $$OfflineMapAreasTableFilterComposer,
          $$OfflineMapAreasTableOrderingComposer,
          $$OfflineMapAreasTableAnnotationComposer,
          $$OfflineMapAreasTableCreateCompanionBuilder,
          $$OfflineMapAreasTableUpdateCompanionBuilder,
          (
            OfflineMapAreaData,
            BaseReferences<
              _$AppDatabase,
              $OfflineMapAreasTable,
              OfflineMapAreaData
            >,
          ),
          OfflineMapAreaData,
          PrefetchHooks Function()
        > {
  $$OfflineMapAreasTableTableManager(
    _$AppDatabase db,
    $OfflineMapAreasTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$OfflineMapAreasTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$OfflineMapAreasTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$OfflineMapAreasTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<double> north = const Value.absent(),
                Value<double> south = const Value.absent(),
                Value<double> east = const Value.absent(),
                Value<double> west = const Value.absent(),
                Value<int> minZoom = const Value.absent(),
                Value<int> maxZoom = const Value.absent(),
                Value<int> tileCount = const Value.absent(),
                Value<int> downloadedAt = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineMapAreasCompanion(
                id: id,
                name: name,
                providerId: providerId,
                north: north,
                south: south,
                east: east,
                west: west,
                minZoom: minZoom,
                maxZoom: maxZoom,
                tileCount: tileCount,
                downloadedAt: downloadedAt,
                sizeBytes: sizeBytes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String providerId,
                required double north,
                required double south,
                required double east,
                required double west,
                required int minZoom,
                required int maxZoom,
                required int tileCount,
                required int downloadedAt,
                required int sizeBytes,
                Value<int> rowid = const Value.absent(),
              }) => OfflineMapAreasCompanion.insert(
                id: id,
                name: name,
                providerId: providerId,
                north: north,
                south: south,
                east: east,
                west: west,
                minZoom: minZoom,
                maxZoom: maxZoom,
                tileCount: tileCount,
                downloadedAt: downloadedAt,
                sizeBytes: sizeBytes,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineMapAreasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineMapAreasTable,
      OfflineMapAreaData,
      $$OfflineMapAreasTableFilterComposer,
      $$OfflineMapAreasTableOrderingComposer,
      $$OfflineMapAreasTableAnnotationComposer,
      $$OfflineMapAreasTableCreateCompanionBuilder,
      $$OfflineMapAreasTableUpdateCompanionBuilder,
      (
        OfflineMapAreaData,
        BaseReferences<
          _$AppDatabase,
          $OfflineMapAreasTable,
          OfflineMapAreaData
        >,
      ),
      OfflineMapAreaData,
      PrefetchHooks Function()
    >;
typedef $$ImportedOverlayMapsTableCreateCompanionBuilder =
    ImportedOverlayMapsCompanion Function({
      required String id,
      required String name,
      required String dirPath,
      required int tileCount,
      required int importedAt,
      Value<bool> isVisible,
      required double boundsNorth,
      required double boundsSouth,
      required double boundsEast,
      required double boundsWest,
      Value<String> layerType,
      Value<int?> minZoom,
      Value<int?> maxZoom,
      Value<double> opacity,
      Value<int> sizeBytes,
      Value<int> rowid,
    });
typedef $$ImportedOverlayMapsTableUpdateCompanionBuilder =
    ImportedOverlayMapsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> dirPath,
      Value<int> tileCount,
      Value<int> importedAt,
      Value<bool> isVisible,
      Value<double> boundsNorth,
      Value<double> boundsSouth,
      Value<double> boundsEast,
      Value<double> boundsWest,
      Value<String> layerType,
      Value<int?> minZoom,
      Value<int?> maxZoom,
      Value<double> opacity,
      Value<int> sizeBytes,
      Value<int> rowid,
    });

class $$ImportedOverlayMapsTableFilterComposer
    extends Composer<_$AppDatabase, $ImportedOverlayMapsTable> {
  $$ImportedOverlayMapsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dirPath => $composableBuilder(
    column: $table.dirPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tileCount => $composableBuilder(
    column: $table.tileCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVisible => $composableBuilder(
    column: $table.isVisible,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundsNorth => $composableBuilder(
    column: $table.boundsNorth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundsSouth => $composableBuilder(
    column: $table.boundsSouth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundsEast => $composableBuilder(
    column: $table.boundsEast,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundsWest => $composableBuilder(
    column: $table.boundsWest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get layerType => $composableBuilder(
    column: $table.layerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minZoom => $composableBuilder(
    column: $table.minZoom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxZoom => $composableBuilder(
    column: $table.maxZoom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get opacity => $composableBuilder(
    column: $table.opacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportedOverlayMapsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportedOverlayMapsTable> {
  $$ImportedOverlayMapsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dirPath => $composableBuilder(
    column: $table.dirPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tileCount => $composableBuilder(
    column: $table.tileCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVisible => $composableBuilder(
    column: $table.isVisible,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundsNorth => $composableBuilder(
    column: $table.boundsNorth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundsSouth => $composableBuilder(
    column: $table.boundsSouth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundsEast => $composableBuilder(
    column: $table.boundsEast,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundsWest => $composableBuilder(
    column: $table.boundsWest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get layerType => $composableBuilder(
    column: $table.layerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minZoom => $composableBuilder(
    column: $table.minZoom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxZoom => $composableBuilder(
    column: $table.maxZoom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get opacity => $composableBuilder(
    column: $table.opacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportedOverlayMapsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportedOverlayMapsTable> {
  $$ImportedOverlayMapsTableAnnotationComposer({
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

  GeneratedColumn<String> get dirPath =>
      $composableBuilder(column: $table.dirPath, builder: (column) => column);

  GeneratedColumn<int> get tileCount =>
      $composableBuilder(column: $table.tileCount, builder: (column) => column);

  GeneratedColumn<int> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isVisible =>
      $composableBuilder(column: $table.isVisible, builder: (column) => column);

  GeneratedColumn<double> get boundsNorth => $composableBuilder(
    column: $table.boundsNorth,
    builder: (column) => column,
  );

  GeneratedColumn<double> get boundsSouth => $composableBuilder(
    column: $table.boundsSouth,
    builder: (column) => column,
  );

  GeneratedColumn<double> get boundsEast => $composableBuilder(
    column: $table.boundsEast,
    builder: (column) => column,
  );

  GeneratedColumn<double> get boundsWest => $composableBuilder(
    column: $table.boundsWest,
    builder: (column) => column,
  );

  GeneratedColumn<String> get layerType =>
      $composableBuilder(column: $table.layerType, builder: (column) => column);

  GeneratedColumn<int> get minZoom =>
      $composableBuilder(column: $table.minZoom, builder: (column) => column);

  GeneratedColumn<int> get maxZoom =>
      $composableBuilder(column: $table.maxZoom, builder: (column) => column);

  GeneratedColumn<double> get opacity =>
      $composableBuilder(column: $table.opacity, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);
}

class $$ImportedOverlayMapsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportedOverlayMapsTable,
          ImportedOverlayMapData,
          $$ImportedOverlayMapsTableFilterComposer,
          $$ImportedOverlayMapsTableOrderingComposer,
          $$ImportedOverlayMapsTableAnnotationComposer,
          $$ImportedOverlayMapsTableCreateCompanionBuilder,
          $$ImportedOverlayMapsTableUpdateCompanionBuilder,
          (
            ImportedOverlayMapData,
            BaseReferences<
              _$AppDatabase,
              $ImportedOverlayMapsTable,
              ImportedOverlayMapData
            >,
          ),
          ImportedOverlayMapData,
          PrefetchHooks Function()
        > {
  $$ImportedOverlayMapsTableTableManager(
    _$AppDatabase db,
    $ImportedOverlayMapsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ImportedOverlayMapsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$ImportedOverlayMapsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$ImportedOverlayMapsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> dirPath = const Value.absent(),
                Value<int> tileCount = const Value.absent(),
                Value<int> importedAt = const Value.absent(),
                Value<bool> isVisible = const Value.absent(),
                Value<double> boundsNorth = const Value.absent(),
                Value<double> boundsSouth = const Value.absent(),
                Value<double> boundsEast = const Value.absent(),
                Value<double> boundsWest = const Value.absent(),
                Value<String> layerType = const Value.absent(),
                Value<int?> minZoom = const Value.absent(),
                Value<int?> maxZoom = const Value.absent(),
                Value<double> opacity = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportedOverlayMapsCompanion(
                id: id,
                name: name,
                dirPath: dirPath,
                tileCount: tileCount,
                importedAt: importedAt,
                isVisible: isVisible,
                boundsNorth: boundsNorth,
                boundsSouth: boundsSouth,
                boundsEast: boundsEast,
                boundsWest: boundsWest,
                layerType: layerType,
                minZoom: minZoom,
                maxZoom: maxZoom,
                opacity: opacity,
                sizeBytes: sizeBytes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String dirPath,
                required int tileCount,
                required int importedAt,
                Value<bool> isVisible = const Value.absent(),
                required double boundsNorth,
                required double boundsSouth,
                required double boundsEast,
                required double boundsWest,
                Value<String> layerType = const Value.absent(),
                Value<int?> minZoom = const Value.absent(),
                Value<int?> maxZoom = const Value.absent(),
                Value<double> opacity = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportedOverlayMapsCompanion.insert(
                id: id,
                name: name,
                dirPath: dirPath,
                tileCount: tileCount,
                importedAt: importedAt,
                isVisible: isVisible,
                boundsNorth: boundsNorth,
                boundsSouth: boundsSouth,
                boundsEast: boundsEast,
                boundsWest: boundsWest,
                layerType: layerType,
                minZoom: minZoom,
                maxZoom: maxZoom,
                opacity: opacity,
                sizeBytes: sizeBytes,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportedOverlayMapsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportedOverlayMapsTable,
      ImportedOverlayMapData,
      $$ImportedOverlayMapsTableFilterComposer,
      $$ImportedOverlayMapsTableOrderingComposer,
      $$ImportedOverlayMapsTableAnnotationComposer,
      $$ImportedOverlayMapsTableCreateCompanionBuilder,
      $$ImportedOverlayMapsTableUpdateCompanionBuilder,
      (
        ImportedOverlayMapData,
        BaseReferences<
          _$AppDatabase,
          $ImportedOverlayMapsTable,
          ImportedOverlayMapData
        >,
      ),
      ImportedOverlayMapData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db, _db.contacts);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db, _db.channels);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$WaypointsTableTableManager get waypoints =>
      $$WaypointsTableTableManager(_db, _db.waypoints);
  $$CompanionDevicesTableTableManager get companionDevices =>
      $$CompanionDevicesTableTableManager(_db, _db.companionDevices);
  $$PeersTableTableManager get peers =>
      $$PeersTableTableManager(_db, _db.peers);
  $$PeerLocationsTableTableManager get peerLocations =>
      $$PeerLocationsTableTableManager(_db, _db.peerLocations);
  $$PeerPositionHistoryTableTableManager get peerPositionHistory =>
      $$PeerPositionHistoryTableTableManager(_db, _db.peerPositionHistory);
  $$AckRecordsTableTableManager get ackRecords =>
      $$AckRecordsTableTableManager(_db, _db.ackRecords);
  $$OfflineMapAreasTableTableManager get offlineMapAreas =>
      $$OfflineMapAreasTableTableManager(_db, _db.offlineMapAreas);
  $$ImportedOverlayMapsTableTableManager get importedOverlayMaps =>
      $$ImportedOverlayMapsTableTableManager(_db, _db.importedOverlayMaps);
}
