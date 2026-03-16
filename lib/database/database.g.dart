// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ContactsTable extends Contacts
    with TableInfo<$ContactsTable, ContactData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _publicKeyMeta =
      const VerificationMeta('publicKey');
  @override
  late final GeneratedColumn<Uint8List> publicKey = GeneratedColumn<Uint8List>(
      'public_key', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<int> hash = GeneratedColumn<int>(
      'hash', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _lastSeenMeta =
      const VerificationMeta('lastSeen');
  @override
  late final GeneratedColumn<int> lastSeen = GeneratedColumn<int>(
      'last_seen', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _companionBatteryMilliVoltsMeta =
      const VerificationMeta('companionBatteryMilliVolts');
  @override
  late final GeneratedColumn<int> companionBatteryMilliVolts =
      GeneratedColumn<int>('companion_battery_milli_volts', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _phoneBatteryMilliVoltsMeta =
      const VerificationMeta('phoneBatteryMilliVolts');
  @override
  late final GeneratedColumn<int> phoneBatteryMilliVolts = GeneratedColumn<int>(
      'phone_battery_milli_volts', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isRepeaterMeta =
      const VerificationMeta('isRepeater');
  @override
  late final GeneratedColumn<bool> isRepeater = GeneratedColumn<bool>(
      'is_repeater', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_repeater" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isRoomServerMeta =
      const VerificationMeta('isRoomServer');
  @override
  late final GeneratedColumn<bool> isRoomServer = GeneratedColumn<bool>(
      'is_room_server', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_room_server" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isDirectMeta =
      const VerificationMeta('isDirect');
  @override
  late final GeneratedColumn<bool> isDirect = GeneratedColumn<bool>(
      'is_direct', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_direct" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _hopCountMeta =
      const VerificationMeta('hopCount');
  @override
  late final GeneratedColumn<int> hopCount = GeneratedColumn<int>(
      'hop_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(-1));
  static const VerificationMeta _lastTelemetryChannelIdxMeta =
      const VerificationMeta('lastTelemetryChannelIdx');
  @override
  late final GeneratedColumn<int> lastTelemetryChannelIdx =
      GeneratedColumn<int>('last_telemetry_channel_idx', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastTelemetryTimestampMeta =
      const VerificationMeta('lastTelemetryTimestamp');
  @override
  late final GeneratedColumn<int> lastTelemetryTimestamp = GeneratedColumn<int>(
      'last_telemetry_timestamp', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isOutOfRangeMeta =
      const VerificationMeta('isOutOfRange');
  @override
  late final GeneratedColumn<bool> isOutOfRange = GeneratedColumn<bool>(
      'is_out_of_range', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_out_of_range" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isAutonomousDeviceMeta =
      const VerificationMeta('isAutonomousDevice');
  @override
  late final GeneratedColumn<bool> isAutonomousDevice = GeneratedColumn<bool>(
      'is_autonomous_device', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_autonomous_device" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _companionDeviceKeyMeta =
      const VerificationMeta('companionDeviceKey');
  @override
  late final GeneratedColumn<String> companionDeviceKey =
      GeneratedColumn<String>('companion_device_key', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
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
        companionDeviceKey
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(Insertable<ContactData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('public_key')) {
      context.handle(_publicKeyMeta,
          publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta));
    } else if (isInserting) {
      context.missing(_publicKeyMeta);
    }
    if (data.containsKey('hash')) {
      context.handle(
          _hashMeta, hash.isAcceptableOrUnknown(data['hash']!, _hashMeta));
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    }
    if (data.containsKey('last_seen')) {
      context.handle(_lastSeenMeta,
          lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta));
    } else if (isInserting) {
      context.missing(_lastSeenMeta);
    }
    if (data.containsKey('companion_battery_milli_volts')) {
      context.handle(
          _companionBatteryMilliVoltsMeta,
          companionBatteryMilliVolts.isAcceptableOrUnknown(
              data['companion_battery_milli_volts']!,
              _companionBatteryMilliVoltsMeta));
    }
    if (data.containsKey('phone_battery_milli_volts')) {
      context.handle(
          _phoneBatteryMilliVoltsMeta,
          phoneBatteryMilliVolts.isAcceptableOrUnknown(
              data['phone_battery_milli_volts']!, _phoneBatteryMilliVoltsMeta));
    }
    if (data.containsKey('is_repeater')) {
      context.handle(
          _isRepeaterMeta,
          isRepeater.isAcceptableOrUnknown(
              data['is_repeater']!, _isRepeaterMeta));
    }
    if (data.containsKey('is_room_server')) {
      context.handle(
          _isRoomServerMeta,
          isRoomServer.isAcceptableOrUnknown(
              data['is_room_server']!, _isRoomServerMeta));
    }
    if (data.containsKey('is_direct')) {
      context.handle(_isDirectMeta,
          isDirect.isAcceptableOrUnknown(data['is_direct']!, _isDirectMeta));
    }
    if (data.containsKey('hop_count')) {
      context.handle(_hopCountMeta,
          hopCount.isAcceptableOrUnknown(data['hop_count']!, _hopCountMeta));
    }
    if (data.containsKey('last_telemetry_channel_idx')) {
      context.handle(
          _lastTelemetryChannelIdxMeta,
          lastTelemetryChannelIdx.isAcceptableOrUnknown(
              data['last_telemetry_channel_idx']!,
              _lastTelemetryChannelIdxMeta));
    }
    if (data.containsKey('last_telemetry_timestamp')) {
      context.handle(
          _lastTelemetryTimestampMeta,
          lastTelemetryTimestamp.isAcceptableOrUnknown(
              data['last_telemetry_timestamp']!, _lastTelemetryTimestampMeta));
    }
    if (data.containsKey('is_out_of_range')) {
      context.handle(
          _isOutOfRangeMeta,
          isOutOfRange.isAcceptableOrUnknown(
              data['is_out_of_range']!, _isOutOfRangeMeta));
    }
    if (data.containsKey('is_autonomous_device')) {
      context.handle(
          _isAutonomousDeviceMeta,
          isAutonomousDevice.isAcceptableOrUnknown(
              data['is_autonomous_device']!, _isAutonomousDeviceMeta));
    }
    if (data.containsKey('companion_device_key')) {
      context.handle(
          _companionDeviceKeyMeta,
          companionDeviceKey.isAcceptableOrUnknown(
              data['companion_device_key']!, _companionDeviceKeyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {publicKey};
  @override
  ContactData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactData(
      publicKey: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}public_key'])!,
      hash: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hash'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude']),
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude']),
      lastSeen: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_seen'])!,
      companionBatteryMilliVolts: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}companion_battery_milli_volts']),
      phoneBatteryMilliVolts: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}phone_battery_milli_volts']),
      isRepeater: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_repeater'])!,
      isRoomServer: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_room_server'])!,
      isDirect: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_direct'])!,
      hopCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hop_count'])!,
      lastTelemetryChannelIdx: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_telemetry_channel_idx']),
      lastTelemetryTimestamp: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}last_telemetry_timestamp']),
      isOutOfRange: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_out_of_range'])!,
      isAutonomousDevice: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_autonomous_device'])!,
      companionDeviceKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}companion_device_key']),
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
  const ContactData(
      {required this.publicKey,
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
      this.companionDeviceKey});
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
      map['companion_battery_milli_volts'] =
          Variable<int>(companionBatteryMilliVolts);
    }
    if (!nullToAbsent || phoneBatteryMilliVolts != null) {
      map['phone_battery_milli_volts'] = Variable<int>(phoneBatteryMilliVolts);
    }
    map['is_repeater'] = Variable<bool>(isRepeater);
    map['is_room_server'] = Variable<bool>(isRoomServer);
    map['is_direct'] = Variable<bool>(isDirect);
    map['hop_count'] = Variable<int>(hopCount);
    if (!nullToAbsent || lastTelemetryChannelIdx != null) {
      map['last_telemetry_channel_idx'] =
          Variable<int>(lastTelemetryChannelIdx);
    }
    if (!nullToAbsent || lastTelemetryTimestamp != null) {
      map['last_telemetry_timestamp'] = Variable<int>(lastTelemetryTimestamp);
    }
    map['is_out_of_range'] = Variable<bool>(isOutOfRange);
    map['is_autonomous_device'] = Variable<bool>(isAutonomousDevice);
    if (!nullToAbsent || companionDeviceKey != null) {
      map['companion_device_key'] = Variable<String>(companionDeviceKey);
    }
    return map;
  }

  ContactsCompanion toCompanion(bool nullToAbsent) {
    return ContactsCompanion(
      publicKey: Value(publicKey),
      hash: Value(hash),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      lastSeen: Value(lastSeen),
      companionBatteryMilliVolts:
          companionBatteryMilliVolts == null && nullToAbsent
              ? const Value.absent()
              : Value(companionBatteryMilliVolts),
      phoneBatteryMilliVolts: phoneBatteryMilliVolts == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneBatteryMilliVolts),
      isRepeater: Value(isRepeater),
      isRoomServer: Value(isRoomServer),
      isDirect: Value(isDirect),
      hopCount: Value(hopCount),
      lastTelemetryChannelIdx: lastTelemetryChannelIdx == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTelemetryChannelIdx),
      lastTelemetryTimestamp: lastTelemetryTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTelemetryTimestamp),
      isOutOfRange: Value(isOutOfRange),
      isAutonomousDevice: Value(isAutonomousDevice),
      companionDeviceKey: companionDeviceKey == null && nullToAbsent
          ? const Value.absent()
          : Value(companionDeviceKey),
    );
  }

  factory ContactData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactData(
      publicKey: serializer.fromJson<Uint8List>(json['publicKey']),
      hash: serializer.fromJson<int>(json['hash']),
      name: serializer.fromJson<String?>(json['name']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      lastSeen: serializer.fromJson<int>(json['lastSeen']),
      companionBatteryMilliVolts:
          serializer.fromJson<int?>(json['companionBatteryMilliVolts']),
      phoneBatteryMilliVolts:
          serializer.fromJson<int?>(json['phoneBatteryMilliVolts']),
      isRepeater: serializer.fromJson<bool>(json['isRepeater']),
      isRoomServer: serializer.fromJson<bool>(json['isRoomServer']),
      isDirect: serializer.fromJson<bool>(json['isDirect']),
      hopCount: serializer.fromJson<int>(json['hopCount']),
      lastTelemetryChannelIdx:
          serializer.fromJson<int?>(json['lastTelemetryChannelIdx']),
      lastTelemetryTimestamp:
          serializer.fromJson<int?>(json['lastTelemetryTimestamp']),
      isOutOfRange: serializer.fromJson<bool>(json['isOutOfRange']),
      isAutonomousDevice: serializer.fromJson<bool>(json['isAutonomousDevice']),
      companionDeviceKey:
          serializer.fromJson<String?>(json['companionDeviceKey']),
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
      'companionBatteryMilliVolts':
          serializer.toJson<int?>(companionBatteryMilliVolts),
      'phoneBatteryMilliVolts': serializer.toJson<int?>(phoneBatteryMilliVolts),
      'isRepeater': serializer.toJson<bool>(isRepeater),
      'isRoomServer': serializer.toJson<bool>(isRoomServer),
      'isDirect': serializer.toJson<bool>(isDirect),
      'hopCount': serializer.toJson<int>(hopCount),
      'lastTelemetryChannelIdx':
          serializer.toJson<int?>(lastTelemetryChannelIdx),
      'lastTelemetryTimestamp': serializer.toJson<int?>(lastTelemetryTimestamp),
      'isOutOfRange': serializer.toJson<bool>(isOutOfRange),
      'isAutonomousDevice': serializer.toJson<bool>(isAutonomousDevice),
      'companionDeviceKey': serializer.toJson<String?>(companionDeviceKey),
    };
  }

  ContactData copyWith(
          {Uint8List? publicKey,
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
          Value<String?> companionDeviceKey = const Value.absent()}) =>
      ContactData(
        publicKey: publicKey ?? this.publicKey,
        hash: hash ?? this.hash,
        name: name.present ? name.value : this.name,
        latitude: latitude.present ? latitude.value : this.latitude,
        longitude: longitude.present ? longitude.value : this.longitude,
        lastSeen: lastSeen ?? this.lastSeen,
        companionBatteryMilliVolts: companionBatteryMilliVolts.present
            ? companionBatteryMilliVolts.value
            : this.companionBatteryMilliVolts,
        phoneBatteryMilliVolts: phoneBatteryMilliVolts.present
            ? phoneBatteryMilliVolts.value
            : this.phoneBatteryMilliVolts,
        isRepeater: isRepeater ?? this.isRepeater,
        isRoomServer: isRoomServer ?? this.isRoomServer,
        isDirect: isDirect ?? this.isDirect,
        hopCount: hopCount ?? this.hopCount,
        lastTelemetryChannelIdx: lastTelemetryChannelIdx.present
            ? lastTelemetryChannelIdx.value
            : this.lastTelemetryChannelIdx,
        lastTelemetryTimestamp: lastTelemetryTimestamp.present
            ? lastTelemetryTimestamp.value
            : this.lastTelemetryTimestamp,
        isOutOfRange: isOutOfRange ?? this.isOutOfRange,
        isAutonomousDevice: isAutonomousDevice ?? this.isAutonomousDevice,
        companionDeviceKey: companionDeviceKey.present
            ? companionDeviceKey.value
            : this.companionDeviceKey,
      );
  ContactData copyWithCompanion(ContactsCompanion data) {
    return ContactData(
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      hash: data.hash.present ? data.hash.value : this.hash,
      name: data.name.present ? data.name.value : this.name,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
      companionBatteryMilliVolts: data.companionBatteryMilliVolts.present
          ? data.companionBatteryMilliVolts.value
          : this.companionBatteryMilliVolts,
      phoneBatteryMilliVolts: data.phoneBatteryMilliVolts.present
          ? data.phoneBatteryMilliVolts.value
          : this.phoneBatteryMilliVolts,
      isRepeater:
          data.isRepeater.present ? data.isRepeater.value : this.isRepeater,
      isRoomServer: data.isRoomServer.present
          ? data.isRoomServer.value
          : this.isRoomServer,
      isDirect: data.isDirect.present ? data.isDirect.value : this.isDirect,
      hopCount: data.hopCount.present ? data.hopCount.value : this.hopCount,
      lastTelemetryChannelIdx: data.lastTelemetryChannelIdx.present
          ? data.lastTelemetryChannelIdx.value
          : this.lastTelemetryChannelIdx,
      lastTelemetryTimestamp: data.lastTelemetryTimestamp.present
          ? data.lastTelemetryTimestamp.value
          : this.lastTelemetryTimestamp,
      isOutOfRange: data.isOutOfRange.present
          ? data.isOutOfRange.value
          : this.isOutOfRange,
      isAutonomousDevice: data.isAutonomousDevice.present
          ? data.isAutonomousDevice.value
          : this.isAutonomousDevice,
      companionDeviceKey: data.companionDeviceKey.present
          ? data.companionDeviceKey.value
          : this.companionDeviceKey,
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
          ..write('companionDeviceKey: $companionDeviceKey')
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
      companionDeviceKey);
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
          other.companionDeviceKey == this.companionDeviceKey);
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
    this.rowid = const Value.absent(),
  })  : publicKey = Value(publicKey),
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
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactsCompanion copyWith(
      {Value<Uint8List>? publicKey,
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
      Value<int>? rowid}) {
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
      map['companion_battery_milli_volts'] =
          Variable<int>(companionBatteryMilliVolts.value);
    }
    if (phoneBatteryMilliVolts.present) {
      map['phone_battery_milli_volts'] =
          Variable<int>(phoneBatteryMilliVolts.value);
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
      map['last_telemetry_channel_idx'] =
          Variable<int>(lastTelemetryChannelIdx.value);
    }
    if (lastTelemetryTimestamp.present) {
      map['last_telemetry_timestamp'] =
          Variable<int>(lastTelemetryTimestamp.value);
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
      'hash', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sharedKeyMeta =
      const VerificationMeta('sharedKey');
  @override
  late final GeneratedColumn<Uint8List> sharedKey = GeneratedColumn<Uint8List>(
      'shared_key', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _isPublicMeta =
      const VerificationMeta('isPublic');
  @override
  late final GeneratedColumn<bool> isPublic = GeneratedColumn<bool>(
      'is_public', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_public" IN (0, 1))'));
  static const VerificationMeta _shareLocationMeta =
      const VerificationMeta('shareLocation');
  @override
  late final GeneratedColumn<bool> shareLocation = GeneratedColumn<bool>(
      'share_location', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("share_location" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _channelIndexMeta =
      const VerificationMeta('channelIndex');
  @override
  late final GeneratedColumn<int> channelIndex = GeneratedColumn<int>(
      'channel_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _muteNotificationsMeta =
      const VerificationMeta('muteNotifications');
  @override
  late final GeneratedColumn<bool> muteNotifications = GeneratedColumn<bool>(
      'mute_notifications', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("mute_notifications" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _companionDeviceKeyMeta =
      const VerificationMeta('companionDeviceKey');
  @override
  late final GeneratedColumn<String> companionDeviceKey =
      GeneratedColumn<String>('companion_device_key', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        hash,
        name,
        sharedKey,
        isPublic,
        shareLocation,
        channelIndex,
        createdAt,
        muteNotifications,
        companionDeviceKey
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channels';
  @override
  VerificationContext validateIntegrity(Insertable<ChannelData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('hash')) {
      context.handle(
          _hashMeta, hash.isAcceptableOrUnknown(data['hash']!, _hashMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('shared_key')) {
      context.handle(_sharedKeyMeta,
          sharedKey.isAcceptableOrUnknown(data['shared_key']!, _sharedKeyMeta));
    } else if (isInserting) {
      context.missing(_sharedKeyMeta);
    }
    if (data.containsKey('is_public')) {
      context.handle(_isPublicMeta,
          isPublic.isAcceptableOrUnknown(data['is_public']!, _isPublicMeta));
    } else if (isInserting) {
      context.missing(_isPublicMeta);
    }
    if (data.containsKey('share_location')) {
      context.handle(
          _shareLocationMeta,
          shareLocation.isAcceptableOrUnknown(
              data['share_location']!, _shareLocationMeta));
    }
    if (data.containsKey('channel_index')) {
      context.handle(
          _channelIndexMeta,
          channelIndex.isAcceptableOrUnknown(
              data['channel_index']!, _channelIndexMeta));
    } else if (isInserting) {
      context.missing(_channelIndexMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('mute_notifications')) {
      context.handle(
          _muteNotificationsMeta,
          muteNotifications.isAcceptableOrUnknown(
              data['mute_notifications']!, _muteNotificationsMeta));
    }
    if (data.containsKey('companion_device_key')) {
      context.handle(
          _companionDeviceKeyMeta,
          companionDeviceKey.isAcceptableOrUnknown(
              data['companion_device_key']!, _companionDeviceKeyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {hash};
  @override
  ChannelData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChannelData(
      hash: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hash'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sharedKey: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}shared_key'])!,
      isPublic: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_public'])!,
      shareLocation: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}share_location'])!,
      channelIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}channel_index'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      muteNotifications: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}mute_notifications'])!,
      companionDeviceKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}companion_device_key']),
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
  final bool muteNotifications;
  final String? companionDeviceKey;
  const ChannelData(
      {required this.hash,
      required this.name,
      required this.sharedKey,
      required this.isPublic,
      required this.shareLocation,
      required this.channelIndex,
      required this.createdAt,
      required this.muteNotifications,
      this.companionDeviceKey});
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
    map['mute_notifications'] = Variable<bool>(muteNotifications);
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
      muteNotifications: Value(muteNotifications),
      companionDeviceKey: companionDeviceKey == null && nullToAbsent
          ? const Value.absent()
          : Value(companionDeviceKey),
    );
  }

  factory ChannelData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChannelData(
      hash: serializer.fromJson<int>(json['hash']),
      name: serializer.fromJson<String>(json['name']),
      sharedKey: serializer.fromJson<Uint8List>(json['sharedKey']),
      isPublic: serializer.fromJson<bool>(json['isPublic']),
      shareLocation: serializer.fromJson<bool>(json['shareLocation']),
      channelIndex: serializer.fromJson<int>(json['channelIndex']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      muteNotifications: serializer.fromJson<bool>(json['muteNotifications']),
      companionDeviceKey:
          serializer.fromJson<String?>(json['companionDeviceKey']),
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
      'muteNotifications': serializer.toJson<bool>(muteNotifications),
      'companionDeviceKey': serializer.toJson<String?>(companionDeviceKey),
    };
  }

  ChannelData copyWith(
          {int? hash,
          String? name,
          Uint8List? sharedKey,
          bool? isPublic,
          bool? shareLocation,
          int? channelIndex,
          int? createdAt,
          bool? muteNotifications,
          Value<String?> companionDeviceKey = const Value.absent()}) =>
      ChannelData(
        hash: hash ?? this.hash,
        name: name ?? this.name,
        sharedKey: sharedKey ?? this.sharedKey,
        isPublic: isPublic ?? this.isPublic,
        shareLocation: shareLocation ?? this.shareLocation,
        channelIndex: channelIndex ?? this.channelIndex,
        createdAt: createdAt ?? this.createdAt,
        muteNotifications: muteNotifications ?? this.muteNotifications,
        companionDeviceKey: companionDeviceKey.present
            ? companionDeviceKey.value
            : this.companionDeviceKey,
      );
  ChannelData copyWithCompanion(ChannelsCompanion data) {
    return ChannelData(
      hash: data.hash.present ? data.hash.value : this.hash,
      name: data.name.present ? data.name.value : this.name,
      sharedKey: data.sharedKey.present ? data.sharedKey.value : this.sharedKey,
      isPublic: data.isPublic.present ? data.isPublic.value : this.isPublic,
      shareLocation: data.shareLocation.present
          ? data.shareLocation.value
          : this.shareLocation,
      channelIndex: data.channelIndex.present
          ? data.channelIndex.value
          : this.channelIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      muteNotifications: data.muteNotifications.present
          ? data.muteNotifications.value
          : this.muteNotifications,
      companionDeviceKey: data.companionDeviceKey.present
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
          ..write('muteNotifications: $muteNotifications, ')
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
      muteNotifications,
      companionDeviceKey);
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
          other.muteNotifications == this.muteNotifications &&
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
  final Value<bool> muteNotifications;
  final Value<String?> companionDeviceKey;
  const ChannelsCompanion({
    this.hash = const Value.absent(),
    this.name = const Value.absent(),
    this.sharedKey = const Value.absent(),
    this.isPublic = const Value.absent(),
    this.shareLocation = const Value.absent(),
    this.channelIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.muteNotifications = const Value.absent(),
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
    this.muteNotifications = const Value.absent(),
    this.companionDeviceKey = const Value.absent(),
  })  : name = Value(name),
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
    Expression<bool>? muteNotifications,
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
      if (muteNotifications != null) 'mute_notifications': muteNotifications,
      if (companionDeviceKey != null)
        'companion_device_key': companionDeviceKey,
    });
  }

  ChannelsCompanion copyWith(
      {Value<int>? hash,
      Value<String>? name,
      Value<Uint8List>? sharedKey,
      Value<bool>? isPublic,
      Value<bool>? shareLocation,
      Value<int>? channelIndex,
      Value<int>? createdAt,
      Value<bool>? muteNotifications,
      Value<String?>? companionDeviceKey}) {
    return ChannelsCompanion(
      hash: hash ?? this.hash,
      name: name ?? this.name,
      sharedKey: sharedKey ?? this.sharedKey,
      isPublic: isPublic ?? this.isPublic,
      shareLocation: shareLocation ?? this.shareLocation,
      channelIndex: channelIndex ?? this.channelIndex,
      createdAt: createdAt ?? this.createdAt,
      muteNotifications: muteNotifications ?? this.muteNotifications,
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
    if (muteNotifications.present) {
      map['mute_notifications'] = Variable<bool>(muteNotifications.value);
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
          ..write('muteNotifications: $muteNotifications, ')
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
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _senderIdMeta =
      const VerificationMeta('senderId');
  @override
  late final GeneratedColumn<Uint8List> senderId = GeneratedColumn<Uint8List>(
      'sender_id', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _senderNameMeta =
      const VerificationMeta('senderName');
  @override
  late final GeneratedColumn<String> senderName = GeneratedColumn<String>(
      'sender_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _channelHashMeta =
      const VerificationMeta('channelHash');
  @override
  late final GeneratedColumn<int> channelHash = GeneratedColumn<int>(
      'channel_hash', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isPrivateMeta =
      const VerificationMeta('isPrivate');
  @override
  late final GeneratedColumn<bool> isPrivate = GeneratedColumn<bool>(
      'is_private', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_private" IN (0, 1))'));
  static const VerificationMeta _ackChecksumMeta =
      const VerificationMeta('ackChecksum');
  @override
  late final GeneratedColumn<Uint8List> ackChecksum =
      GeneratedColumn<Uint8List>('ack_checksum', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _deliveryStatusMeta =
      const VerificationMeta('deliveryStatus');
  @override
  late final GeneratedColumn<String> deliveryStatus = GeneratedColumn<String>(
      'delivery_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _heardByCountMeta =
      const VerificationMeta('heardByCount');
  @override
  late final GeneratedColumn<int> heardByCount = GeneratedColumn<int>(
      'heard_by_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _attemptMeta =
      const VerificationMeta('attempt');
  @override
  late final GeneratedColumn<int> attempt = GeneratedColumn<int>(
      'attempt', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isSentByMeMeta =
      const VerificationMeta('isSentByMe');
  @override
  late final GeneratedColumn<bool> isSentByMe = GeneratedColumn<bool>(
      'is_sent_by_me', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_sent_by_me" IN (0, 1))'));
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _companionDeviceKeyMeta =
      const VerificationMeta('companionDeviceKey');
  @override
  late final GeneratedColumn<String> companionDeviceKey =
      GeneratedColumn<String>('companion_device_key', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
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
        companionDeviceKey
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(Insertable<MessageData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(_senderIdMeta,
          senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta));
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('sender_name')) {
      context.handle(
          _senderNameMeta,
          senderName.isAcceptableOrUnknown(
              data['sender_name']!, _senderNameMeta));
    }
    if (data.containsKey('channel_hash')) {
      context.handle(
          _channelHashMeta,
          channelHash.isAcceptableOrUnknown(
              data['channel_hash']!, _channelHashMeta));
    } else if (isInserting) {
      context.missing(_channelHashMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('is_private')) {
      context.handle(_isPrivateMeta,
          isPrivate.isAcceptableOrUnknown(data['is_private']!, _isPrivateMeta));
    } else if (isInserting) {
      context.missing(_isPrivateMeta);
    }
    if (data.containsKey('ack_checksum')) {
      context.handle(
          _ackChecksumMeta,
          ackChecksum.isAcceptableOrUnknown(
              data['ack_checksum']!, _ackChecksumMeta));
    }
    if (data.containsKey('delivery_status')) {
      context.handle(
          _deliveryStatusMeta,
          deliveryStatus.isAcceptableOrUnknown(
              data['delivery_status']!, _deliveryStatusMeta));
    } else if (isInserting) {
      context.missing(_deliveryStatusMeta);
    }
    if (data.containsKey('heard_by_count')) {
      context.handle(
          _heardByCountMeta,
          heardByCount.isAcceptableOrUnknown(
              data['heard_by_count']!, _heardByCountMeta));
    }
    if (data.containsKey('attempt')) {
      context.handle(_attemptMeta,
          attempt.isAcceptableOrUnknown(data['attempt']!, _attemptMeta));
    }
    if (data.containsKey('is_sent_by_me')) {
      context.handle(
          _isSentByMeMeta,
          isSentByMe.isAcceptableOrUnknown(
              data['is_sent_by_me']!, _isSentByMeMeta));
    } else if (isInserting) {
      context.missing(_isSentByMeMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    if (data.containsKey('companion_device_key')) {
      context.handle(
          _companionDeviceKeyMeta,
          companionDeviceKey.isAcceptableOrUnknown(
              data['companion_device_key']!, _companionDeviceKeyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      senderId: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}sender_id'])!,
      senderName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_name']),
      channelHash: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}channel_hash'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
      isPrivate: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_private'])!,
      ackChecksum: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}ack_checksum']),
      deliveryStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}delivery_status'])!,
      heardByCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}heard_by_count'])!,
      attempt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt'])!,
      isSentByMe: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_sent_by_me'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
      companionDeviceKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}companion_device_key']),
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
  const MessageData(
      {required this.id,
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
      this.companionDeviceKey});
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
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      senderId: Value(senderId),
      senderName: senderName == null && nullToAbsent
          ? const Value.absent()
          : Value(senderName),
      channelHash: Value(channelHash),
      content: Value(content),
      timestamp: Value(timestamp),
      isPrivate: Value(isPrivate),
      ackChecksum: ackChecksum == null && nullToAbsent
          ? const Value.absent()
          : Value(ackChecksum),
      deliveryStatus: Value(deliveryStatus),
      heardByCount: Value(heardByCount),
      attempt: Value(attempt),
      isSentByMe: Value(isSentByMe),
      isRead: Value(isRead),
      companionDeviceKey: companionDeviceKey == null && nullToAbsent
          ? const Value.absent()
          : Value(companionDeviceKey),
    );
  }

  factory MessageData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
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
      companionDeviceKey:
          serializer.fromJson<String?>(json['companionDeviceKey']),
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
    };
  }

  MessageData copyWith(
          {String? id,
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
          Value<String?> companionDeviceKey = const Value.absent()}) =>
      MessageData(
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
        companionDeviceKey: companionDeviceKey.present
            ? companionDeviceKey.value
            : this.companionDeviceKey,
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
      deliveryStatus: data.deliveryStatus.present
          ? data.deliveryStatus.value
          : this.deliveryStatus,
      heardByCount: data.heardByCount.present
          ? data.heardByCount.value
          : this.heardByCount,
      attempt: data.attempt.present ? data.attempt.value : this.attempt,
      isSentByMe:
          data.isSentByMe.present ? data.isSentByMe.value : this.isSentByMe,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      companionDeviceKey: data.companionDeviceKey.present
          ? data.companionDeviceKey.value
          : this.companionDeviceKey,
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
          ..write('companionDeviceKey: $companionDeviceKey')
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
      companionDeviceKey);
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
          other.companionDeviceKey == this.companionDeviceKey);
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
    this.rowid = const Value.absent(),
  })  : id = Value(id),
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
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith(
      {Value<String>? id,
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
      Value<int>? rowid}) {
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
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _meshIdMeta = const VerificationMeta('meshId');
  @override
  late final GeneratedColumn<String> meshId = GeneratedColumn<String>(
      'mesh_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _waypointTypeMeta =
      const VerificationMeta('waypointType');
  @override
  late final GeneratedColumn<String> waypointType = GeneratedColumn<String>(
      'waypoint_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _creatorNodeIdMeta =
      const VerificationMeta('creatorNodeId');
  @override
  late final GeneratedColumn<String> creatorNodeId = GeneratedColumn<String>(
      'creator_node_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isReceivedMeta =
      const VerificationMeta('isReceived');
  @override
  late final GeneratedColumn<bool> isReceived = GeneratedColumn<bool>(
      'is_received', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_received" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isVisibleMeta =
      const VerificationMeta('isVisible');
  @override
  late final GeneratedColumn<bool> isVisible = GeneratedColumn<bool>(
      'is_visible', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_visible" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isNewMeta = const VerificationMeta('isNew');
  @override
  late final GeneratedColumn<bool> isNew = GeneratedColumn<bool>(
      'is_new', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_new" IN (0, 1))'),
      defaultValue: const Constant(false));
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
        isNew
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'waypoints';
  @override
  VerificationContext validateIntegrity(Insertable<WaypointData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('mesh_id')) {
      context.handle(_meshIdMeta,
          meshId.isAcceptableOrUnknown(data['mesh_id']!, _meshIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('waypoint_type')) {
      context.handle(
          _waypointTypeMeta,
          waypointType.isAcceptableOrUnknown(
              data['waypoint_type']!, _waypointTypeMeta));
    } else if (isInserting) {
      context.missing(_waypointTypeMeta);
    }
    if (data.containsKey('creator_node_id')) {
      context.handle(
          _creatorNodeIdMeta,
          creatorNodeId.isAcceptableOrUnknown(
              data['creator_node_id']!, _creatorNodeIdMeta));
    } else if (isInserting) {
      context.missing(_creatorNodeIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_received')) {
      context.handle(
          _isReceivedMeta,
          isReceived.isAcceptableOrUnknown(
              data['is_received']!, _isReceivedMeta));
    }
    if (data.containsKey('is_visible')) {
      context.handle(_isVisibleMeta,
          isVisible.isAcceptableOrUnknown(data['is_visible']!, _isVisibleMeta));
    }
    if (data.containsKey('is_new')) {
      context.handle(
          _isNewMeta, isNew.isAcceptableOrUnknown(data['is_new']!, _isNewMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WaypointData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaypointData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      meshId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mesh_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      waypointType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}waypoint_type'])!,
      creatorNodeId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}creator_node_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      isReceived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_received'])!,
      isVisible: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_visible'])!,
      isNew: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_new'])!,
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
  const WaypointData(
      {required this.id,
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
      required this.isNew});
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

  factory WaypointData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
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

  WaypointData copyWith(
          {String? id,
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
          bool? isNew}) =>
      WaypointData(
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
      waypointType: data.waypointType.present
          ? data.waypointType.value
          : this.waypointType,
      creatorNodeId: data.creatorNodeId.present
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
      isNew);
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
  })  : id = Value(id),
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

  WaypointsCompanion copyWith(
      {Value<String>? id,
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
      Value<int>? rowid}) {
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
  static const VerificationMeta _publicKeyHexMeta =
      const VerificationMeta('publicKeyHex');
  @override
  late final GeneratedColumn<String> publicKeyHex = GeneratedColumn<String>(
      'public_key_hex', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _firstConnectedMeta =
      const VerificationMeta('firstConnected');
  @override
  late final GeneratedColumn<int> firstConnected = GeneratedColumn<int>(
      'first_connected', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastConnectedMeta =
      const VerificationMeta('lastConnected');
  @override
  late final GeneratedColumn<int> lastConnected = GeneratedColumn<int>(
      'last_connected', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _connectionCountMeta =
      const VerificationMeta('connectionCount');
  @override
  late final GeneratedColumn<int> connectionCount = GeneratedColumn<int>(
      'connection_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns =>
      [publicKeyHex, name, firstConnected, lastConnected, connectionCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'companion_devices';
  @override
  VerificationContext validateIntegrity(
      Insertable<CompanionDeviceData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('public_key_hex')) {
      context.handle(
          _publicKeyHexMeta,
          publicKeyHex.isAcceptableOrUnknown(
              data['public_key_hex']!, _publicKeyHexMeta));
    } else if (isInserting) {
      context.missing(_publicKeyHexMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('first_connected')) {
      context.handle(
          _firstConnectedMeta,
          firstConnected.isAcceptableOrUnknown(
              data['first_connected']!, _firstConnectedMeta));
    } else if (isInserting) {
      context.missing(_firstConnectedMeta);
    }
    if (data.containsKey('last_connected')) {
      context.handle(
          _lastConnectedMeta,
          lastConnected.isAcceptableOrUnknown(
              data['last_connected']!, _lastConnectedMeta));
    } else if (isInserting) {
      context.missing(_lastConnectedMeta);
    }
    if (data.containsKey('connection_count')) {
      context.handle(
          _connectionCountMeta,
          connectionCount.isAcceptableOrUnknown(
              data['connection_count']!, _connectionCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {publicKeyHex};
  @override
  CompanionDeviceData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompanionDeviceData(
      publicKeyHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}public_key_hex'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      firstConnected: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}first_connected'])!,
      lastConnected: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_connected'])!,
      connectionCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}connection_count'])!,
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
  const CompanionDeviceData(
      {required this.publicKeyHex,
      required this.name,
      required this.firstConnected,
      required this.lastConnected,
      required this.connectionCount});
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

  factory CompanionDeviceData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
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

  CompanionDeviceData copyWith(
          {String? publicKeyHex,
          String? name,
          int? firstConnected,
          int? lastConnected,
          int? connectionCount}) =>
      CompanionDeviceData(
        publicKeyHex: publicKeyHex ?? this.publicKeyHex,
        name: name ?? this.name,
        firstConnected: firstConnected ?? this.firstConnected,
        lastConnected: lastConnected ?? this.lastConnected,
        connectionCount: connectionCount ?? this.connectionCount,
      );
  CompanionDeviceData copyWithCompanion(CompanionDevicesCompanion data) {
    return CompanionDeviceData(
      publicKeyHex: data.publicKeyHex.present
          ? data.publicKeyHex.value
          : this.publicKeyHex,
      name: data.name.present ? data.name.value : this.name,
      firstConnected: data.firstConnected.present
          ? data.firstConnected.value
          : this.firstConnected,
      lastConnected: data.lastConnected.present
          ? data.lastConnected.value
          : this.lastConnected,
      connectionCount: data.connectionCount.present
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
      publicKeyHex, name, firstConnected, lastConnected, connectionCount);
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
  })  : publicKeyHex = Value(publicKeyHex),
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

  CompanionDevicesCompanion copyWith(
      {Value<String>? publicKeyHex,
      Value<String>? name,
      Value<int>? firstConnected,
      Value<int>? lastConnected,
      Value<int>? connectionCount,
      Value<int>? rowid}) {
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

class $ContactDisplayStatesTable extends ContactDisplayStates
    with TableInfo<$ContactDisplayStatesTable, ContactDisplayStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactDisplayStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _publicKeyHexMeta =
      const VerificationMeta('publicKeyHex');
  @override
  late final GeneratedColumn<String> publicKeyHex = GeneratedColumn<String>(
      'public_key_hex', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _companionDeviceKeyMeta =
      const VerificationMeta('companionDeviceKey');
  @override
  late final GeneratedColumn<String> companionDeviceKey =
      GeneratedColumn<String>('companion_device_key', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastSeenMeta =
      const VerificationMeta('lastSeen');
  @override
  late final GeneratedColumn<int> lastSeen = GeneratedColumn<int>(
      'last_seen', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastLatitudeMeta =
      const VerificationMeta('lastLatitude');
  @override
  late final GeneratedColumn<double> lastLatitude = GeneratedColumn<double>(
      'last_latitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _lastLongitudeMeta =
      const VerificationMeta('lastLongitude');
  @override
  late final GeneratedColumn<double> lastLongitude = GeneratedColumn<double>(
      'last_longitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _lastChannelIdxMeta =
      const VerificationMeta('lastChannelIdx');
  @override
  late final GeneratedColumn<int> lastChannelIdx = GeneratedColumn<int>(
      'last_channel_idx', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastPathLenMeta =
      const VerificationMeta('lastPathLen');
  @override
  late final GeneratedColumn<int> lastPathLen = GeneratedColumn<int>(
      'last_path_len', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isManuallyHiddenMeta =
      const VerificationMeta('isManuallyHidden');
  @override
  late final GeneratedColumn<bool> isManuallyHidden = GeneratedColumn<bool>(
      'is_manually_hidden', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_manually_hidden" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _hiddenAtMeta =
      const VerificationMeta('hiddenAt');
  @override
  late final GeneratedColumn<int> hiddenAt = GeneratedColumn<int>(
      'hidden_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _firstSeenMeta =
      const VerificationMeta('firstSeen');
  @override
  late final GeneratedColumn<int> firstSeen = GeneratedColumn<int>(
      'first_seen', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _totalTelemetryReceivedMeta =
      const VerificationMeta('totalTelemetryReceived');
  @override
  late final GeneratedColumn<int> totalTelemetryReceived = GeneratedColumn<int>(
      'total_telemetry_received', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isAutonomousDeviceMeta =
      const VerificationMeta('isAutonomousDevice');
  @override
  late final GeneratedColumn<bool> isAutonomousDevice = GeneratedColumn<bool>(
      'is_autonomous_device', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_autonomous_device" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        publicKeyHex,
        companionDeviceKey,
        lastSeen,
        lastLatitude,
        lastLongitude,
        lastChannelIdx,
        lastPathLen,
        isManuallyHidden,
        hiddenAt,
        name,
        firstSeen,
        totalTelemetryReceived,
        isAutonomousDevice
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contact_display_states';
  @override
  VerificationContext validateIntegrity(
      Insertable<ContactDisplayStateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('public_key_hex')) {
      context.handle(
          _publicKeyHexMeta,
          publicKeyHex.isAcceptableOrUnknown(
              data['public_key_hex']!, _publicKeyHexMeta));
    } else if (isInserting) {
      context.missing(_publicKeyHexMeta);
    }
    if (data.containsKey('companion_device_key')) {
      context.handle(
          _companionDeviceKeyMeta,
          companionDeviceKey.isAcceptableOrUnknown(
              data['companion_device_key']!, _companionDeviceKeyMeta));
    } else if (isInserting) {
      context.missing(_companionDeviceKeyMeta);
    }
    if (data.containsKey('last_seen')) {
      context.handle(_lastSeenMeta,
          lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta));
    } else if (isInserting) {
      context.missing(_lastSeenMeta);
    }
    if (data.containsKey('last_latitude')) {
      context.handle(
          _lastLatitudeMeta,
          lastLatitude.isAcceptableOrUnknown(
              data['last_latitude']!, _lastLatitudeMeta));
    }
    if (data.containsKey('last_longitude')) {
      context.handle(
          _lastLongitudeMeta,
          lastLongitude.isAcceptableOrUnknown(
              data['last_longitude']!, _lastLongitudeMeta));
    }
    if (data.containsKey('last_channel_idx')) {
      context.handle(
          _lastChannelIdxMeta,
          lastChannelIdx.isAcceptableOrUnknown(
              data['last_channel_idx']!, _lastChannelIdxMeta));
    } else if (isInserting) {
      context.missing(_lastChannelIdxMeta);
    }
    if (data.containsKey('last_path_len')) {
      context.handle(
          _lastPathLenMeta,
          lastPathLen.isAcceptableOrUnknown(
              data['last_path_len']!, _lastPathLenMeta));
    } else if (isInserting) {
      context.missing(_lastPathLenMeta);
    }
    if (data.containsKey('is_manually_hidden')) {
      context.handle(
          _isManuallyHiddenMeta,
          isManuallyHidden.isAcceptableOrUnknown(
              data['is_manually_hidden']!, _isManuallyHiddenMeta));
    }
    if (data.containsKey('hidden_at')) {
      context.handle(_hiddenAtMeta,
          hiddenAt.isAcceptableOrUnknown(data['hidden_at']!, _hiddenAtMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('first_seen')) {
      context.handle(_firstSeenMeta,
          firstSeen.isAcceptableOrUnknown(data['first_seen']!, _firstSeenMeta));
    } else if (isInserting) {
      context.missing(_firstSeenMeta);
    }
    if (data.containsKey('total_telemetry_received')) {
      context.handle(
          _totalTelemetryReceivedMeta,
          totalTelemetryReceived.isAcceptableOrUnknown(
              data['total_telemetry_received']!, _totalTelemetryReceivedMeta));
    }
    if (data.containsKey('is_autonomous_device')) {
      context.handle(
          _isAutonomousDeviceMeta,
          isAutonomousDevice.isAcceptableOrUnknown(
              data['is_autonomous_device']!, _isAutonomousDeviceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {publicKeyHex};
  @override
  ContactDisplayStateData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactDisplayStateData(
      publicKeyHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}public_key_hex'])!,
      companionDeviceKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}companion_device_key'])!,
      lastSeen: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_seen'])!,
      lastLatitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}last_latitude']),
      lastLongitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}last_longitude']),
      lastChannelIdx: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_channel_idx'])!,
      lastPathLen: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_path_len'])!,
      isManuallyHidden: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_manually_hidden'])!,
      hiddenAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hidden_at']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      firstSeen: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}first_seen'])!,
      totalTelemetryReceived: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}total_telemetry_received'])!,
      isAutonomousDevice: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_autonomous_device'])!,
    );
  }

  @override
  $ContactDisplayStatesTable createAlias(String alias) {
    return $ContactDisplayStatesTable(attachedDatabase, alias);
  }
}

class ContactDisplayStateData extends DataClass
    implements Insertable<ContactDisplayStateData> {
  final String publicKeyHex;
  final String companionDeviceKey;
  final int lastSeen;
  final double? lastLatitude;
  final double? lastLongitude;
  final int lastChannelIdx;
  final int lastPathLen;
  final bool isManuallyHidden;
  final int? hiddenAt;
  final String? name;
  final int firstSeen;
  final int totalTelemetryReceived;
  final bool isAutonomousDevice;
  const ContactDisplayStateData(
      {required this.publicKeyHex,
      required this.companionDeviceKey,
      required this.lastSeen,
      this.lastLatitude,
      this.lastLongitude,
      required this.lastChannelIdx,
      required this.lastPathLen,
      required this.isManuallyHidden,
      this.hiddenAt,
      this.name,
      required this.firstSeen,
      required this.totalTelemetryReceived,
      required this.isAutonomousDevice});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['public_key_hex'] = Variable<String>(publicKeyHex);
    map['companion_device_key'] = Variable<String>(companionDeviceKey);
    map['last_seen'] = Variable<int>(lastSeen);
    if (!nullToAbsent || lastLatitude != null) {
      map['last_latitude'] = Variable<double>(lastLatitude);
    }
    if (!nullToAbsent || lastLongitude != null) {
      map['last_longitude'] = Variable<double>(lastLongitude);
    }
    map['last_channel_idx'] = Variable<int>(lastChannelIdx);
    map['last_path_len'] = Variable<int>(lastPathLen);
    map['is_manually_hidden'] = Variable<bool>(isManuallyHidden);
    if (!nullToAbsent || hiddenAt != null) {
      map['hidden_at'] = Variable<int>(hiddenAt);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['first_seen'] = Variable<int>(firstSeen);
    map['total_telemetry_received'] = Variable<int>(totalTelemetryReceived);
    map['is_autonomous_device'] = Variable<bool>(isAutonomousDevice);
    return map;
  }

  ContactDisplayStatesCompanion toCompanion(bool nullToAbsent) {
    return ContactDisplayStatesCompanion(
      publicKeyHex: Value(publicKeyHex),
      companionDeviceKey: Value(companionDeviceKey),
      lastSeen: Value(lastSeen),
      lastLatitude: lastLatitude == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLatitude),
      lastLongitude: lastLongitude == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLongitude),
      lastChannelIdx: Value(lastChannelIdx),
      lastPathLen: Value(lastPathLen),
      isManuallyHidden: Value(isManuallyHidden),
      hiddenAt: hiddenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(hiddenAt),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      firstSeen: Value(firstSeen),
      totalTelemetryReceived: Value(totalTelemetryReceived),
      isAutonomousDevice: Value(isAutonomousDevice),
    );
  }

  factory ContactDisplayStateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactDisplayStateData(
      publicKeyHex: serializer.fromJson<String>(json['publicKeyHex']),
      companionDeviceKey:
          serializer.fromJson<String>(json['companionDeviceKey']),
      lastSeen: serializer.fromJson<int>(json['lastSeen']),
      lastLatitude: serializer.fromJson<double?>(json['lastLatitude']),
      lastLongitude: serializer.fromJson<double?>(json['lastLongitude']),
      lastChannelIdx: serializer.fromJson<int>(json['lastChannelIdx']),
      lastPathLen: serializer.fromJson<int>(json['lastPathLen']),
      isManuallyHidden: serializer.fromJson<bool>(json['isManuallyHidden']),
      hiddenAt: serializer.fromJson<int?>(json['hiddenAt']),
      name: serializer.fromJson<String?>(json['name']),
      firstSeen: serializer.fromJson<int>(json['firstSeen']),
      totalTelemetryReceived:
          serializer.fromJson<int>(json['totalTelemetryReceived']),
      isAutonomousDevice: serializer.fromJson<bool>(json['isAutonomousDevice']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'publicKeyHex': serializer.toJson<String>(publicKeyHex),
      'companionDeviceKey': serializer.toJson<String>(companionDeviceKey),
      'lastSeen': serializer.toJson<int>(lastSeen),
      'lastLatitude': serializer.toJson<double?>(lastLatitude),
      'lastLongitude': serializer.toJson<double?>(lastLongitude),
      'lastChannelIdx': serializer.toJson<int>(lastChannelIdx),
      'lastPathLen': serializer.toJson<int>(lastPathLen),
      'isManuallyHidden': serializer.toJson<bool>(isManuallyHidden),
      'hiddenAt': serializer.toJson<int?>(hiddenAt),
      'name': serializer.toJson<String?>(name),
      'firstSeen': serializer.toJson<int>(firstSeen),
      'totalTelemetryReceived': serializer.toJson<int>(totalTelemetryReceived),
      'isAutonomousDevice': serializer.toJson<bool>(isAutonomousDevice),
    };
  }

  ContactDisplayStateData copyWith(
          {String? publicKeyHex,
          String? companionDeviceKey,
          int? lastSeen,
          Value<double?> lastLatitude = const Value.absent(),
          Value<double?> lastLongitude = const Value.absent(),
          int? lastChannelIdx,
          int? lastPathLen,
          bool? isManuallyHidden,
          Value<int?> hiddenAt = const Value.absent(),
          Value<String?> name = const Value.absent(),
          int? firstSeen,
          int? totalTelemetryReceived,
          bool? isAutonomousDevice}) =>
      ContactDisplayStateData(
        publicKeyHex: publicKeyHex ?? this.publicKeyHex,
        companionDeviceKey: companionDeviceKey ?? this.companionDeviceKey,
        lastSeen: lastSeen ?? this.lastSeen,
        lastLatitude:
            lastLatitude.present ? lastLatitude.value : this.lastLatitude,
        lastLongitude:
            lastLongitude.present ? lastLongitude.value : this.lastLongitude,
        lastChannelIdx: lastChannelIdx ?? this.lastChannelIdx,
        lastPathLen: lastPathLen ?? this.lastPathLen,
        isManuallyHidden: isManuallyHidden ?? this.isManuallyHidden,
        hiddenAt: hiddenAt.present ? hiddenAt.value : this.hiddenAt,
        name: name.present ? name.value : this.name,
        firstSeen: firstSeen ?? this.firstSeen,
        totalTelemetryReceived:
            totalTelemetryReceived ?? this.totalTelemetryReceived,
        isAutonomousDevice: isAutonomousDevice ?? this.isAutonomousDevice,
      );
  ContactDisplayStateData copyWithCompanion(
      ContactDisplayStatesCompanion data) {
    return ContactDisplayStateData(
      publicKeyHex: data.publicKeyHex.present
          ? data.publicKeyHex.value
          : this.publicKeyHex,
      companionDeviceKey: data.companionDeviceKey.present
          ? data.companionDeviceKey.value
          : this.companionDeviceKey,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
      lastLatitude: data.lastLatitude.present
          ? data.lastLatitude.value
          : this.lastLatitude,
      lastLongitude: data.lastLongitude.present
          ? data.lastLongitude.value
          : this.lastLongitude,
      lastChannelIdx: data.lastChannelIdx.present
          ? data.lastChannelIdx.value
          : this.lastChannelIdx,
      lastPathLen:
          data.lastPathLen.present ? data.lastPathLen.value : this.lastPathLen,
      isManuallyHidden: data.isManuallyHidden.present
          ? data.isManuallyHidden.value
          : this.isManuallyHidden,
      hiddenAt: data.hiddenAt.present ? data.hiddenAt.value : this.hiddenAt,
      name: data.name.present ? data.name.value : this.name,
      firstSeen: data.firstSeen.present ? data.firstSeen.value : this.firstSeen,
      totalTelemetryReceived: data.totalTelemetryReceived.present
          ? data.totalTelemetryReceived.value
          : this.totalTelemetryReceived,
      isAutonomousDevice: data.isAutonomousDevice.present
          ? data.isAutonomousDevice.value
          : this.isAutonomousDevice,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactDisplayStateData(')
          ..write('publicKeyHex: $publicKeyHex, ')
          ..write('companionDeviceKey: $companionDeviceKey, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('lastLatitude: $lastLatitude, ')
          ..write('lastLongitude: $lastLongitude, ')
          ..write('lastChannelIdx: $lastChannelIdx, ')
          ..write('lastPathLen: $lastPathLen, ')
          ..write('isManuallyHidden: $isManuallyHidden, ')
          ..write('hiddenAt: $hiddenAt, ')
          ..write('name: $name, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('totalTelemetryReceived: $totalTelemetryReceived, ')
          ..write('isAutonomousDevice: $isAutonomousDevice')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      publicKeyHex,
      companionDeviceKey,
      lastSeen,
      lastLatitude,
      lastLongitude,
      lastChannelIdx,
      lastPathLen,
      isManuallyHidden,
      hiddenAt,
      name,
      firstSeen,
      totalTelemetryReceived,
      isAutonomousDevice);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactDisplayStateData &&
          other.publicKeyHex == this.publicKeyHex &&
          other.companionDeviceKey == this.companionDeviceKey &&
          other.lastSeen == this.lastSeen &&
          other.lastLatitude == this.lastLatitude &&
          other.lastLongitude == this.lastLongitude &&
          other.lastChannelIdx == this.lastChannelIdx &&
          other.lastPathLen == this.lastPathLen &&
          other.isManuallyHidden == this.isManuallyHidden &&
          other.hiddenAt == this.hiddenAt &&
          other.name == this.name &&
          other.firstSeen == this.firstSeen &&
          other.totalTelemetryReceived == this.totalTelemetryReceived &&
          other.isAutonomousDevice == this.isAutonomousDevice);
}

class ContactDisplayStatesCompanion
    extends UpdateCompanion<ContactDisplayStateData> {
  final Value<String> publicKeyHex;
  final Value<String> companionDeviceKey;
  final Value<int> lastSeen;
  final Value<double?> lastLatitude;
  final Value<double?> lastLongitude;
  final Value<int> lastChannelIdx;
  final Value<int> lastPathLen;
  final Value<bool> isManuallyHidden;
  final Value<int?> hiddenAt;
  final Value<String?> name;
  final Value<int> firstSeen;
  final Value<int> totalTelemetryReceived;
  final Value<bool> isAutonomousDevice;
  final Value<int> rowid;
  const ContactDisplayStatesCompanion({
    this.publicKeyHex = const Value.absent(),
    this.companionDeviceKey = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.lastLatitude = const Value.absent(),
    this.lastLongitude = const Value.absent(),
    this.lastChannelIdx = const Value.absent(),
    this.lastPathLen = const Value.absent(),
    this.isManuallyHidden = const Value.absent(),
    this.hiddenAt = const Value.absent(),
    this.name = const Value.absent(),
    this.firstSeen = const Value.absent(),
    this.totalTelemetryReceived = const Value.absent(),
    this.isAutonomousDevice = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactDisplayStatesCompanion.insert({
    required String publicKeyHex,
    required String companionDeviceKey,
    required int lastSeen,
    this.lastLatitude = const Value.absent(),
    this.lastLongitude = const Value.absent(),
    required int lastChannelIdx,
    required int lastPathLen,
    this.isManuallyHidden = const Value.absent(),
    this.hiddenAt = const Value.absent(),
    this.name = const Value.absent(),
    required int firstSeen,
    this.totalTelemetryReceived = const Value.absent(),
    this.isAutonomousDevice = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : publicKeyHex = Value(publicKeyHex),
        companionDeviceKey = Value(companionDeviceKey),
        lastSeen = Value(lastSeen),
        lastChannelIdx = Value(lastChannelIdx),
        lastPathLen = Value(lastPathLen),
        firstSeen = Value(firstSeen);
  static Insertable<ContactDisplayStateData> custom({
    Expression<String>? publicKeyHex,
    Expression<String>? companionDeviceKey,
    Expression<int>? lastSeen,
    Expression<double>? lastLatitude,
    Expression<double>? lastLongitude,
    Expression<int>? lastChannelIdx,
    Expression<int>? lastPathLen,
    Expression<bool>? isManuallyHidden,
    Expression<int>? hiddenAt,
    Expression<String>? name,
    Expression<int>? firstSeen,
    Expression<int>? totalTelemetryReceived,
    Expression<bool>? isAutonomousDevice,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (publicKeyHex != null) 'public_key_hex': publicKeyHex,
      if (companionDeviceKey != null)
        'companion_device_key': companionDeviceKey,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (lastLatitude != null) 'last_latitude': lastLatitude,
      if (lastLongitude != null) 'last_longitude': lastLongitude,
      if (lastChannelIdx != null) 'last_channel_idx': lastChannelIdx,
      if (lastPathLen != null) 'last_path_len': lastPathLen,
      if (isManuallyHidden != null) 'is_manually_hidden': isManuallyHidden,
      if (hiddenAt != null) 'hidden_at': hiddenAt,
      if (name != null) 'name': name,
      if (firstSeen != null) 'first_seen': firstSeen,
      if (totalTelemetryReceived != null)
        'total_telemetry_received': totalTelemetryReceived,
      if (isAutonomousDevice != null)
        'is_autonomous_device': isAutonomousDevice,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactDisplayStatesCompanion copyWith(
      {Value<String>? publicKeyHex,
      Value<String>? companionDeviceKey,
      Value<int>? lastSeen,
      Value<double?>? lastLatitude,
      Value<double?>? lastLongitude,
      Value<int>? lastChannelIdx,
      Value<int>? lastPathLen,
      Value<bool>? isManuallyHidden,
      Value<int?>? hiddenAt,
      Value<String?>? name,
      Value<int>? firstSeen,
      Value<int>? totalTelemetryReceived,
      Value<bool>? isAutonomousDevice,
      Value<int>? rowid}) {
    return ContactDisplayStatesCompanion(
      publicKeyHex: publicKeyHex ?? this.publicKeyHex,
      companionDeviceKey: companionDeviceKey ?? this.companionDeviceKey,
      lastSeen: lastSeen ?? this.lastSeen,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      lastChannelIdx: lastChannelIdx ?? this.lastChannelIdx,
      lastPathLen: lastPathLen ?? this.lastPathLen,
      isManuallyHidden: isManuallyHidden ?? this.isManuallyHidden,
      hiddenAt: hiddenAt ?? this.hiddenAt,
      name: name ?? this.name,
      firstSeen: firstSeen ?? this.firstSeen,
      totalTelemetryReceived:
          totalTelemetryReceived ?? this.totalTelemetryReceived,
      isAutonomousDevice: isAutonomousDevice ?? this.isAutonomousDevice,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (publicKeyHex.present) {
      map['public_key_hex'] = Variable<String>(publicKeyHex.value);
    }
    if (companionDeviceKey.present) {
      map['companion_device_key'] = Variable<String>(companionDeviceKey.value);
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
    if (lastChannelIdx.present) {
      map['last_channel_idx'] = Variable<int>(lastChannelIdx.value);
    }
    if (lastPathLen.present) {
      map['last_path_len'] = Variable<int>(lastPathLen.value);
    }
    if (isManuallyHidden.present) {
      map['is_manually_hidden'] = Variable<bool>(isManuallyHidden.value);
    }
    if (hiddenAt.present) {
      map['hidden_at'] = Variable<int>(hiddenAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (firstSeen.present) {
      map['first_seen'] = Variable<int>(firstSeen.value);
    }
    if (totalTelemetryReceived.present) {
      map['total_telemetry_received'] =
          Variable<int>(totalTelemetryReceived.value);
    }
    if (isAutonomousDevice.present) {
      map['is_autonomous_device'] = Variable<bool>(isAutonomousDevice.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactDisplayStatesCompanion(')
          ..write('publicKeyHex: $publicKeyHex, ')
          ..write('companionDeviceKey: $companionDeviceKey, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('lastLatitude: $lastLatitude, ')
          ..write('lastLongitude: $lastLongitude, ')
          ..write('lastChannelIdx: $lastChannelIdx, ')
          ..write('lastPathLen: $lastPathLen, ')
          ..write('isManuallyHidden: $isManuallyHidden, ')
          ..write('hiddenAt: $hiddenAt, ')
          ..write('name: $name, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('totalTelemetryReceived: $totalTelemetryReceived, ')
          ..write('isAutonomousDevice: $isAutonomousDevice, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContactPositionHistoriesTable extends ContactPositionHistories
    with TableInfo<$ContactPositionHistoriesTable, ContactPositionHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactPositionHistoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _publicKeyHexMeta =
      const VerificationMeta('publicKeyHex');
  @override
  late final GeneratedColumn<String> publicKeyHex = GeneratedColumn<String>(
      'public_key_hex', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _companionDeviceKeyMeta =
      const VerificationMeta('companionDeviceKey');
  @override
  late final GeneratedColumn<String> companionDeviceKey =
      GeneratedColumn<String>('companion_device_key', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _accuracyMeta =
      const VerificationMeta('accuracy');
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
      'accuracy', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _channelIdxMeta =
      const VerificationMeta('channelIdx');
  @override
  late final GeneratedColumn<int> channelIdx = GeneratedColumn<int>(
      'channel_idx', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _pathLenMeta =
      const VerificationMeta('pathLen');
  @override
  late final GeneratedColumn<int> pathLen = GeneratedColumn<int>(
      'path_len', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _batteryVoltageMeta =
      const VerificationMeta('batteryVoltage');
  @override
  late final GeneratedColumn<double> batteryVoltage = GeneratedColumn<double>(
      'battery_voltage', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _binLevelMeta =
      const VerificationMeta('binLevel');
  @override
  late final GeneratedColumn<int> binLevel = GeneratedColumn<int>(
      'bin_level', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isAggregatedMeta =
      const VerificationMeta('isAggregated');
  @override
  late final GeneratedColumn<bool> isAggregated = GeneratedColumn<bool>(
      'is_aggregated', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_aggregated" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        publicKeyHex,
        companionDeviceKey,
        timestamp,
        latitude,
        longitude,
        accuracy,
        channelIdx,
        pathLen,
        batteryVoltage,
        binLevel,
        isAggregated
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contact_position_histories';
  @override
  VerificationContext validateIntegrity(
      Insertable<ContactPositionHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('public_key_hex')) {
      context.handle(
          _publicKeyHexMeta,
          publicKeyHex.isAcceptableOrUnknown(
              data['public_key_hex']!, _publicKeyHexMeta));
    } else if (isInserting) {
      context.missing(_publicKeyHexMeta);
    }
    if (data.containsKey('companion_device_key')) {
      context.handle(
          _companionDeviceKeyMeta,
          companionDeviceKey.isAcceptableOrUnknown(
              data['companion_device_key']!, _companionDeviceKeyMeta));
    } else if (isInserting) {
      context.missing(_companionDeviceKeyMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(_accuracyMeta,
          accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta));
    }
    if (data.containsKey('channel_idx')) {
      context.handle(
          _channelIdxMeta,
          channelIdx.isAcceptableOrUnknown(
              data['channel_idx']!, _channelIdxMeta));
    } else if (isInserting) {
      context.missing(_channelIdxMeta);
    }
    if (data.containsKey('path_len')) {
      context.handle(_pathLenMeta,
          pathLen.isAcceptableOrUnknown(data['path_len']!, _pathLenMeta));
    } else if (isInserting) {
      context.missing(_pathLenMeta);
    }
    if (data.containsKey('battery_voltage')) {
      context.handle(
          _batteryVoltageMeta,
          batteryVoltage.isAcceptableOrUnknown(
              data['battery_voltage']!, _batteryVoltageMeta));
    }
    if (data.containsKey('bin_level')) {
      context.handle(_binLevelMeta,
          binLevel.isAcceptableOrUnknown(data['bin_level']!, _binLevelMeta));
    } else if (isInserting) {
      context.missing(_binLevelMeta);
    }
    if (data.containsKey('is_aggregated')) {
      context.handle(
          _isAggregatedMeta,
          isAggregated.isAcceptableOrUnknown(
              data['is_aggregated']!, _isAggregatedMeta));
    } else if (isInserting) {
      context.missing(_isAggregatedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContactPositionHistoryData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactPositionHistoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      publicKeyHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}public_key_hex'])!,
      companionDeviceKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}companion_device_key'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      accuracy: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}accuracy']),
      channelIdx: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}channel_idx'])!,
      pathLen: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}path_len'])!,
      batteryVoltage: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}battery_voltage']),
      binLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bin_level'])!,
      isAggregated: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_aggregated'])!,
    );
  }

  @override
  $ContactPositionHistoriesTable createAlias(String alias) {
    return $ContactPositionHistoriesTable(attachedDatabase, alias);
  }
}

class ContactPositionHistoryData extends DataClass
    implements Insertable<ContactPositionHistoryData> {
  final int id;
  final String publicKeyHex;
  final String companionDeviceKey;
  final int timestamp;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final int channelIdx;
  final int pathLen;
  final double? batteryVoltage;
  final int binLevel;
  final bool isAggregated;
  const ContactPositionHistoryData(
      {required this.id,
      required this.publicKeyHex,
      required this.companionDeviceKey,
      required this.timestamp,
      required this.latitude,
      required this.longitude,
      this.accuracy,
      required this.channelIdx,
      required this.pathLen,
      this.batteryVoltage,
      required this.binLevel,
      required this.isAggregated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['public_key_hex'] = Variable<String>(publicKeyHex);
    map['companion_device_key'] = Variable<String>(companionDeviceKey);
    map['timestamp'] = Variable<int>(timestamp);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || accuracy != null) {
      map['accuracy'] = Variable<double>(accuracy);
    }
    map['channel_idx'] = Variable<int>(channelIdx);
    map['path_len'] = Variable<int>(pathLen);
    if (!nullToAbsent || batteryVoltage != null) {
      map['battery_voltage'] = Variable<double>(batteryVoltage);
    }
    map['bin_level'] = Variable<int>(binLevel);
    map['is_aggregated'] = Variable<bool>(isAggregated);
    return map;
  }

  ContactPositionHistoriesCompanion toCompanion(bool nullToAbsent) {
    return ContactPositionHistoriesCompanion(
      id: Value(id),
      publicKeyHex: Value(publicKeyHex),
      companionDeviceKey: Value(companionDeviceKey),
      timestamp: Value(timestamp),
      latitude: Value(latitude),
      longitude: Value(longitude),
      accuracy: accuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracy),
      channelIdx: Value(channelIdx),
      pathLen: Value(pathLen),
      batteryVoltage: batteryVoltage == null && nullToAbsent
          ? const Value.absent()
          : Value(batteryVoltage),
      binLevel: Value(binLevel),
      isAggregated: Value(isAggregated),
    );
  }

  factory ContactPositionHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactPositionHistoryData(
      id: serializer.fromJson<int>(json['id']),
      publicKeyHex: serializer.fromJson<String>(json['publicKeyHex']),
      companionDeviceKey:
          serializer.fromJson<String>(json['companionDeviceKey']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      accuracy: serializer.fromJson<double?>(json['accuracy']),
      channelIdx: serializer.fromJson<int>(json['channelIdx']),
      pathLen: serializer.fromJson<int>(json['pathLen']),
      batteryVoltage: serializer.fromJson<double?>(json['batteryVoltage']),
      binLevel: serializer.fromJson<int>(json['binLevel']),
      isAggregated: serializer.fromJson<bool>(json['isAggregated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'publicKeyHex': serializer.toJson<String>(publicKeyHex),
      'companionDeviceKey': serializer.toJson<String>(companionDeviceKey),
      'timestamp': serializer.toJson<int>(timestamp),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'accuracy': serializer.toJson<double?>(accuracy),
      'channelIdx': serializer.toJson<int>(channelIdx),
      'pathLen': serializer.toJson<int>(pathLen),
      'batteryVoltage': serializer.toJson<double?>(batteryVoltage),
      'binLevel': serializer.toJson<int>(binLevel),
      'isAggregated': serializer.toJson<bool>(isAggregated),
    };
  }

  ContactPositionHistoryData copyWith(
          {int? id,
          String? publicKeyHex,
          String? companionDeviceKey,
          int? timestamp,
          double? latitude,
          double? longitude,
          Value<double?> accuracy = const Value.absent(),
          int? channelIdx,
          int? pathLen,
          Value<double?> batteryVoltage = const Value.absent(),
          int? binLevel,
          bool? isAggregated}) =>
      ContactPositionHistoryData(
        id: id ?? this.id,
        publicKeyHex: publicKeyHex ?? this.publicKeyHex,
        companionDeviceKey: companionDeviceKey ?? this.companionDeviceKey,
        timestamp: timestamp ?? this.timestamp,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        accuracy: accuracy.present ? accuracy.value : this.accuracy,
        channelIdx: channelIdx ?? this.channelIdx,
        pathLen: pathLen ?? this.pathLen,
        batteryVoltage:
            batteryVoltage.present ? batteryVoltage.value : this.batteryVoltage,
        binLevel: binLevel ?? this.binLevel,
        isAggregated: isAggregated ?? this.isAggregated,
      );
  ContactPositionHistoryData copyWithCompanion(
      ContactPositionHistoriesCompanion data) {
    return ContactPositionHistoryData(
      id: data.id.present ? data.id.value : this.id,
      publicKeyHex: data.publicKeyHex.present
          ? data.publicKeyHex.value
          : this.publicKeyHex,
      companionDeviceKey: data.companionDeviceKey.present
          ? data.companionDeviceKey.value
          : this.companionDeviceKey,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      channelIdx:
          data.channelIdx.present ? data.channelIdx.value : this.channelIdx,
      pathLen: data.pathLen.present ? data.pathLen.value : this.pathLen,
      batteryVoltage: data.batteryVoltage.present
          ? data.batteryVoltage.value
          : this.batteryVoltage,
      binLevel: data.binLevel.present ? data.binLevel.value : this.binLevel,
      isAggregated: data.isAggregated.present
          ? data.isAggregated.value
          : this.isAggregated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactPositionHistoryData(')
          ..write('id: $id, ')
          ..write('publicKeyHex: $publicKeyHex, ')
          ..write('companionDeviceKey: $companionDeviceKey, ')
          ..write('timestamp: $timestamp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('channelIdx: $channelIdx, ')
          ..write('pathLen: $pathLen, ')
          ..write('batteryVoltage: $batteryVoltage, ')
          ..write('binLevel: $binLevel, ')
          ..write('isAggregated: $isAggregated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      publicKeyHex,
      companionDeviceKey,
      timestamp,
      latitude,
      longitude,
      accuracy,
      channelIdx,
      pathLen,
      batteryVoltage,
      binLevel,
      isAggregated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactPositionHistoryData &&
          other.id == this.id &&
          other.publicKeyHex == this.publicKeyHex &&
          other.companionDeviceKey == this.companionDeviceKey &&
          other.timestamp == this.timestamp &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.accuracy == this.accuracy &&
          other.channelIdx == this.channelIdx &&
          other.pathLen == this.pathLen &&
          other.batteryVoltage == this.batteryVoltage &&
          other.binLevel == this.binLevel &&
          other.isAggregated == this.isAggregated);
}

class ContactPositionHistoriesCompanion
    extends UpdateCompanion<ContactPositionHistoryData> {
  final Value<int> id;
  final Value<String> publicKeyHex;
  final Value<String> companionDeviceKey;
  final Value<int> timestamp;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double?> accuracy;
  final Value<int> channelIdx;
  final Value<int> pathLen;
  final Value<double?> batteryVoltage;
  final Value<int> binLevel;
  final Value<bool> isAggregated;
  const ContactPositionHistoriesCompanion({
    this.id = const Value.absent(),
    this.publicKeyHex = const Value.absent(),
    this.companionDeviceKey = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.channelIdx = const Value.absent(),
    this.pathLen = const Value.absent(),
    this.batteryVoltage = const Value.absent(),
    this.binLevel = const Value.absent(),
    this.isAggregated = const Value.absent(),
  });
  ContactPositionHistoriesCompanion.insert({
    this.id = const Value.absent(),
    required String publicKeyHex,
    required String companionDeviceKey,
    required int timestamp,
    required double latitude,
    required double longitude,
    this.accuracy = const Value.absent(),
    required int channelIdx,
    required int pathLen,
    this.batteryVoltage = const Value.absent(),
    required int binLevel,
    required bool isAggregated,
  })  : publicKeyHex = Value(publicKeyHex),
        companionDeviceKey = Value(companionDeviceKey),
        timestamp = Value(timestamp),
        latitude = Value(latitude),
        longitude = Value(longitude),
        channelIdx = Value(channelIdx),
        pathLen = Value(pathLen),
        binLevel = Value(binLevel),
        isAggregated = Value(isAggregated);
  static Insertable<ContactPositionHistoryData> custom({
    Expression<int>? id,
    Expression<String>? publicKeyHex,
    Expression<String>? companionDeviceKey,
    Expression<int>? timestamp,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? accuracy,
    Expression<int>? channelIdx,
    Expression<int>? pathLen,
    Expression<double>? batteryVoltage,
    Expression<int>? binLevel,
    Expression<bool>? isAggregated,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (publicKeyHex != null) 'public_key_hex': publicKeyHex,
      if (companionDeviceKey != null)
        'companion_device_key': companionDeviceKey,
      if (timestamp != null) 'timestamp': timestamp,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (channelIdx != null) 'channel_idx': channelIdx,
      if (pathLen != null) 'path_len': pathLen,
      if (batteryVoltage != null) 'battery_voltage': batteryVoltage,
      if (binLevel != null) 'bin_level': binLevel,
      if (isAggregated != null) 'is_aggregated': isAggregated,
    });
  }

  ContactPositionHistoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? publicKeyHex,
      Value<String>? companionDeviceKey,
      Value<int>? timestamp,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<double?>? accuracy,
      Value<int>? channelIdx,
      Value<int>? pathLen,
      Value<double?>? batteryVoltage,
      Value<int>? binLevel,
      Value<bool>? isAggregated}) {
    return ContactPositionHistoriesCompanion(
      id: id ?? this.id,
      publicKeyHex: publicKeyHex ?? this.publicKeyHex,
      companionDeviceKey: companionDeviceKey ?? this.companionDeviceKey,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      channelIdx: channelIdx ?? this.channelIdx,
      pathLen: pathLen ?? this.pathLen,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      binLevel: binLevel ?? this.binLevel,
      isAggregated: isAggregated ?? this.isAggregated,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (publicKeyHex.present) {
      map['public_key_hex'] = Variable<String>(publicKeyHex.value);
    }
    if (companionDeviceKey.present) {
      map['companion_device_key'] = Variable<String>(companionDeviceKey.value);
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
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (channelIdx.present) {
      map['channel_idx'] = Variable<int>(channelIdx.value);
    }
    if (pathLen.present) {
      map['path_len'] = Variable<int>(pathLen.value);
    }
    if (batteryVoltage.present) {
      map['battery_voltage'] = Variable<double>(batteryVoltage.value);
    }
    if (binLevel.present) {
      map['bin_level'] = Variable<int>(binLevel.value);
    }
    if (isAggregated.present) {
      map['is_aggregated'] = Variable<bool>(isAggregated.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactPositionHistoriesCompanion(')
          ..write('id: $id, ')
          ..write('publicKeyHex: $publicKeyHex, ')
          ..write('companionDeviceKey: $companionDeviceKey, ')
          ..write('timestamp: $timestamp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('channelIdx: $channelIdx, ')
          ..write('pathLen: $pathLen, ')
          ..write('batteryVoltage: $batteryVoltage, ')
          ..write('binLevel: $binLevel, ')
          ..write('isAggregated: $isAggregated')
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
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ackerPublicKeyMeta =
      const VerificationMeta('ackerPublicKey');
  @override
  late final GeneratedColumn<Uint8List> ackerPublicKey =
      GeneratedColumn<Uint8List>('acker_public_key', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _receivedAtMeta =
      const VerificationMeta('receivedAt');
  @override
  late final GeneratedColumn<int> receivedAt = GeneratedColumn<int>(
      'received_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _snrMeta = const VerificationMeta('snr');
  @override
  late final GeneratedColumn<int> snr = GeneratedColumn<int>(
      'snr', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _rssiMeta = const VerificationMeta('rssi');
  @override
  late final GeneratedColumn<int> rssi = GeneratedColumn<int>(
      'rssi', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _companionDeviceKeyMeta =
      const VerificationMeta('companionDeviceKey');
  @override
  late final GeneratedColumn<String> companionDeviceKey =
      GeneratedColumn<String>('companion_device_key', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [messageId, ackerPublicKey, receivedAt, snr, rssi, companionDeviceKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ack_records';
  @override
  VerificationContext validateIntegrity(Insertable<AckRecordData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('acker_public_key')) {
      context.handle(
          _ackerPublicKeyMeta,
          ackerPublicKey.isAcceptableOrUnknown(
              data['acker_public_key']!, _ackerPublicKeyMeta));
    } else if (isInserting) {
      context.missing(_ackerPublicKeyMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
          _receivedAtMeta,
          receivedAt.isAcceptableOrUnknown(
              data['received_at']!, _receivedAtMeta));
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('snr')) {
      context.handle(
          _snrMeta, snr.isAcceptableOrUnknown(data['snr']!, _snrMeta));
    }
    if (data.containsKey('rssi')) {
      context.handle(
          _rssiMeta, rssi.isAcceptableOrUnknown(data['rssi']!, _rssiMeta));
    }
    if (data.containsKey('companion_device_key')) {
      context.handle(
          _companionDeviceKeyMeta,
          companionDeviceKey.isAcceptableOrUnknown(
              data['companion_device_key']!, _companionDeviceKeyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId, ackerPublicKey};
  @override
  AckRecordData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AckRecordData(
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      ackerPublicKey: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}acker_public_key'])!,
      receivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}received_at'])!,
      snr: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}snr']),
      rssi: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rssi']),
      companionDeviceKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}companion_device_key']),
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
  const AckRecordData(
      {required this.messageId,
      required this.ackerPublicKey,
      required this.receivedAt,
      this.snr,
      this.rssi,
      this.companionDeviceKey});
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
      companionDeviceKey: companionDeviceKey == null && nullToAbsent
          ? const Value.absent()
          : Value(companionDeviceKey),
    );
  }

  factory AckRecordData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AckRecordData(
      messageId: serializer.fromJson<String>(json['messageId']),
      ackerPublicKey: serializer.fromJson<Uint8List>(json['ackerPublicKey']),
      receivedAt: serializer.fromJson<int>(json['receivedAt']),
      snr: serializer.fromJson<int?>(json['snr']),
      rssi: serializer.fromJson<int?>(json['rssi']),
      companionDeviceKey:
          serializer.fromJson<String?>(json['companionDeviceKey']),
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

  AckRecordData copyWith(
          {String? messageId,
          Uint8List? ackerPublicKey,
          int? receivedAt,
          Value<int?> snr = const Value.absent(),
          Value<int?> rssi = const Value.absent(),
          Value<String?> companionDeviceKey = const Value.absent()}) =>
      AckRecordData(
        messageId: messageId ?? this.messageId,
        ackerPublicKey: ackerPublicKey ?? this.ackerPublicKey,
        receivedAt: receivedAt ?? this.receivedAt,
        snr: snr.present ? snr.value : this.snr,
        rssi: rssi.present ? rssi.value : this.rssi,
        companionDeviceKey: companionDeviceKey.present
            ? companionDeviceKey.value
            : this.companionDeviceKey,
      );
  AckRecordData copyWithCompanion(AckRecordsCompanion data) {
    return AckRecordData(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      ackerPublicKey: data.ackerPublicKey.present
          ? data.ackerPublicKey.value
          : this.ackerPublicKey,
      receivedAt:
          data.receivedAt.present ? data.receivedAt.value : this.receivedAt,
      snr: data.snr.present ? data.snr.value : this.snr,
      rssi: data.rssi.present ? data.rssi.value : this.rssi,
      companionDeviceKey: data.companionDeviceKey.present
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
      companionDeviceKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AckRecordData &&
          other.messageId == this.messageId &&
          $driftBlobEquality.equals(
              other.ackerPublicKey, this.ackerPublicKey) &&
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
  })  : messageId = Value(messageId),
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

  AckRecordsCompanion copyWith(
      {Value<String>? messageId,
      Value<Uint8List>? ackerPublicKey,
      Value<int>? receivedAt,
      Value<int?>? snr,
      Value<int?>? rssi,
      Value<String?>? companionDeviceKey,
      Value<int>? rowid}) {
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
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _northMeta = const VerificationMeta('north');
  @override
  late final GeneratedColumn<double> north = GeneratedColumn<double>(
      'north', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _southMeta = const VerificationMeta('south');
  @override
  late final GeneratedColumn<double> south = GeneratedColumn<double>(
      'south', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _eastMeta = const VerificationMeta('east');
  @override
  late final GeneratedColumn<double> east = GeneratedColumn<double>(
      'east', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _westMeta = const VerificationMeta('west');
  @override
  late final GeneratedColumn<double> west = GeneratedColumn<double>(
      'west', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _minZoomMeta =
      const VerificationMeta('minZoom');
  @override
  late final GeneratedColumn<int> minZoom = GeneratedColumn<int>(
      'min_zoom', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _maxZoomMeta =
      const VerificationMeta('maxZoom');
  @override
  late final GeneratedColumn<int> maxZoom = GeneratedColumn<int>(
      'max_zoom', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tileCountMeta =
      const VerificationMeta('tileCount');
  @override
  late final GeneratedColumn<int> tileCount = GeneratedColumn<int>(
      'tile_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _downloadedAtMeta =
      const VerificationMeta('downloadedAt');
  @override
  late final GeneratedColumn<int> downloadedAt = GeneratedColumn<int>(
      'downloaded_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sizeBytesMeta =
      const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
      'size_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
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
        sizeBytes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_map_areas';
  @override
  VerificationContext validateIntegrity(Insertable<OfflineMapAreaData> instance,
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
    if (data.containsKey('provider_id')) {
      context.handle(
          _providerIdMeta,
          providerId.isAcceptableOrUnknown(
              data['provider_id']!, _providerIdMeta));
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('north')) {
      context.handle(
          _northMeta, north.isAcceptableOrUnknown(data['north']!, _northMeta));
    } else if (isInserting) {
      context.missing(_northMeta);
    }
    if (data.containsKey('south')) {
      context.handle(
          _southMeta, south.isAcceptableOrUnknown(data['south']!, _southMeta));
    } else if (isInserting) {
      context.missing(_southMeta);
    }
    if (data.containsKey('east')) {
      context.handle(
          _eastMeta, east.isAcceptableOrUnknown(data['east']!, _eastMeta));
    } else if (isInserting) {
      context.missing(_eastMeta);
    }
    if (data.containsKey('west')) {
      context.handle(
          _westMeta, west.isAcceptableOrUnknown(data['west']!, _westMeta));
    } else if (isInserting) {
      context.missing(_westMeta);
    }
    if (data.containsKey('min_zoom')) {
      context.handle(_minZoomMeta,
          minZoom.isAcceptableOrUnknown(data['min_zoom']!, _minZoomMeta));
    } else if (isInserting) {
      context.missing(_minZoomMeta);
    }
    if (data.containsKey('max_zoom')) {
      context.handle(_maxZoomMeta,
          maxZoom.isAcceptableOrUnknown(data['max_zoom']!, _maxZoomMeta));
    } else if (isInserting) {
      context.missing(_maxZoomMeta);
    }
    if (data.containsKey('tile_count')) {
      context.handle(_tileCountMeta,
          tileCount.isAcceptableOrUnknown(data['tile_count']!, _tileCountMeta));
    } else if (isInserting) {
      context.missing(_tileCountMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
          _downloadedAtMeta,
          downloadedAt.isAcceptableOrUnknown(
              data['downloaded_at']!, _downloadedAtMeta));
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta,
          sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
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
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id'])!,
      north: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}north'])!,
      south: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}south'])!,
      east: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}east'])!,
      west: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}west'])!,
      minZoom: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_zoom'])!,
      maxZoom: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_zoom'])!,
      tileCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tile_count'])!,
      downloadedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}downloaded_at'])!,
      sizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size_bytes'])!,
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
  const OfflineMapAreaData(
      {required this.id,
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
      required this.sizeBytes});
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

  factory OfflineMapAreaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
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

  OfflineMapAreaData copyWith(
          {String? id,
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
          int? sizeBytes}) =>
      OfflineMapAreaData(
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
      downloadedAt: data.downloadedAt.present
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
  int get hashCode => Object.hash(id, name, providerId, north, south, east,
      west, minZoom, maxZoom, tileCount, downloadedAt, sizeBytes);
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
  })  : id = Value(id),
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

  OfflineMapAreasCompanion copyWith(
      {Value<String>? id,
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
      Value<int>? rowid}) {
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  late final $ChannelsTable channels = $ChannelsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $WaypointsTable waypoints = $WaypointsTable(this);
  late final $CompanionDevicesTable companionDevices =
      $CompanionDevicesTable(this);
  late final $ContactDisplayStatesTable contactDisplayStates =
      $ContactDisplayStatesTable(this);
  late final $ContactPositionHistoriesTable contactPositionHistories =
      $ContactPositionHistoriesTable(this);
  late final $AckRecordsTable ackRecords = $AckRecordsTable(this);
  late final $OfflineMapAreasTable offlineMapAreas =
      $OfflineMapAreasTable(this);
  late final ContactsDao contactsDao = ContactsDao(this as AppDatabase);
  late final ChannelsDao channelsDao = ChannelsDao(this as AppDatabase);
  late final MessagesDao messagesDao = MessagesDao(this as AppDatabase);
  late final WaypointsDao waypointsDao = WaypointsDao(this as AppDatabase);
  late final AckRecordsDao ackRecordsDao = AckRecordsDao(this as AppDatabase);
  late final CompanionDevicesDao companionDevicesDao =
      CompanionDevicesDao(this as AppDatabase);
  late final OfflineMapAreasDao offlineMapAreasDao =
      OfflineMapAreasDao(this as AppDatabase);
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
        contactDisplayStates,
        contactPositionHistories,
        ackRecords,
        offlineMapAreas
      ];
}

typedef $$ContactsTableCreateCompanionBuilder = ContactsCompanion Function({
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
  Value<int> rowid,
});
typedef $$ContactsTableUpdateCompanionBuilder = ContactsCompanion Function({
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
      column: $table.publicKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hash => $composableBuilder(
      column: $table.hash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastSeen => $composableBuilder(
      column: $table.lastSeen, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get companionBatteryMilliVolts => $composableBuilder(
      column: $table.companionBatteryMilliVolts,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get phoneBatteryMilliVolts => $composableBuilder(
      column: $table.phoneBatteryMilliVolts,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRepeater => $composableBuilder(
      column: $table.isRepeater, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRoomServer => $composableBuilder(
      column: $table.isRoomServer, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDirect => $composableBuilder(
      column: $table.isDirect, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hopCount => $composableBuilder(
      column: $table.hopCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastTelemetryChannelIdx => $composableBuilder(
      column: $table.lastTelemetryChannelIdx,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastTelemetryTimestamp => $composableBuilder(
      column: $table.lastTelemetryTimestamp,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isOutOfRange => $composableBuilder(
      column: $table.isOutOfRange, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isAutonomousDevice => $composableBuilder(
      column: $table.isAutonomousDevice,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companionDeviceKey => $composableBuilder(
      column: $table.companionDeviceKey,
      builder: (column) => ColumnFilters(column));
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
      column: $table.publicKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hash => $composableBuilder(
      column: $table.hash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastSeen => $composableBuilder(
      column: $table.lastSeen, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get companionBatteryMilliVolts => $composableBuilder(
      column: $table.companionBatteryMilliVolts,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get phoneBatteryMilliVolts => $composableBuilder(
      column: $table.phoneBatteryMilliVolts,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRepeater => $composableBuilder(
      column: $table.isRepeater, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRoomServer => $composableBuilder(
      column: $table.isRoomServer,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDirect => $composableBuilder(
      column: $table.isDirect, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hopCount => $composableBuilder(
      column: $table.hopCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastTelemetryChannelIdx => $composableBuilder(
      column: $table.lastTelemetryChannelIdx,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastTelemetryTimestamp => $composableBuilder(
      column: $table.lastTelemetryTimestamp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isOutOfRange => $composableBuilder(
      column: $table.isOutOfRange,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isAutonomousDevice => $composableBuilder(
      column: $table.isAutonomousDevice,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companionDeviceKey => $composableBuilder(
      column: $table.companionDeviceKey,
      builder: (column) => ColumnOrderings(column));
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
      column: $table.companionBatteryMilliVolts, builder: (column) => column);

  GeneratedColumn<int> get phoneBatteryMilliVolts => $composableBuilder(
      column: $table.phoneBatteryMilliVolts, builder: (column) => column);

  GeneratedColumn<bool> get isRepeater => $composableBuilder(
      column: $table.isRepeater, builder: (column) => column);

  GeneratedColumn<bool> get isRoomServer => $composableBuilder(
      column: $table.isRoomServer, builder: (column) => column);

  GeneratedColumn<bool> get isDirect =>
      $composableBuilder(column: $table.isDirect, builder: (column) => column);

  GeneratedColumn<int> get hopCount =>
      $composableBuilder(column: $table.hopCount, builder: (column) => column);

  GeneratedColumn<int> get lastTelemetryChannelIdx => $composableBuilder(
      column: $table.lastTelemetryChannelIdx, builder: (column) => column);

  GeneratedColumn<int> get lastTelemetryTimestamp => $composableBuilder(
      column: $table.lastTelemetryTimestamp, builder: (column) => column);

  GeneratedColumn<bool> get isOutOfRange => $composableBuilder(
      column: $table.isOutOfRange, builder: (column) => column);

  GeneratedColumn<bool> get isAutonomousDevice => $composableBuilder(
      column: $table.isAutonomousDevice, builder: (column) => column);

  GeneratedColumn<String> get companionDeviceKey => $composableBuilder(
      column: $table.companionDeviceKey, builder: (column) => column);
}

class $$ContactsTableTableManager extends RootTableManager<
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
    PrefetchHooks Function()> {
  $$ContactsTableTableManager(_$AppDatabase db, $ContactsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
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
            Value<int> rowid = const Value.absent(),
          }) =>
              ContactsCompanion(
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
            rowid: rowid,
          ),
          createCompanionCallback: ({
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
            Value<int> rowid = const Value.absent(),
          }) =>
              ContactsCompanion.insert(
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
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ContactsTableProcessedTableManager = ProcessedTableManager<
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
    PrefetchHooks Function()>;
typedef $$ChannelsTableCreateCompanionBuilder = ChannelsCompanion Function({
  Value<int> hash,
  required String name,
  required Uint8List sharedKey,
  required bool isPublic,
  Value<bool> shareLocation,
  required int channelIndex,
  required int createdAt,
  Value<bool> muteNotifications,
  Value<String?> companionDeviceKey,
});
typedef $$ChannelsTableUpdateCompanionBuilder = ChannelsCompanion Function({
  Value<int> hash,
  Value<String> name,
  Value<Uint8List> sharedKey,
  Value<bool> isPublic,
  Value<bool> shareLocation,
  Value<int> channelIndex,
  Value<int> createdAt,
  Value<bool> muteNotifications,
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
      column: $table.hash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get sharedKey => $composableBuilder(
      column: $table.sharedKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPublic => $composableBuilder(
      column: $table.isPublic, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get shareLocation => $composableBuilder(
      column: $table.shareLocation, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get channelIndex => $composableBuilder(
      column: $table.channelIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get muteNotifications => $composableBuilder(
      column: $table.muteNotifications,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companionDeviceKey => $composableBuilder(
      column: $table.companionDeviceKey,
      builder: (column) => ColumnFilters(column));
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
      column: $table.hash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get sharedKey => $composableBuilder(
      column: $table.sharedKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPublic => $composableBuilder(
      column: $table.isPublic, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get shareLocation => $composableBuilder(
      column: $table.shareLocation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get channelIndex => $composableBuilder(
      column: $table.channelIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get muteNotifications => $composableBuilder(
      column: $table.muteNotifications,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companionDeviceKey => $composableBuilder(
      column: $table.companionDeviceKey,
      builder: (column) => ColumnOrderings(column));
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
      column: $table.shareLocation, builder: (column) => column);

  GeneratedColumn<int> get channelIndex => $composableBuilder(
      column: $table.channelIndex, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get muteNotifications => $composableBuilder(
      column: $table.muteNotifications, builder: (column) => column);

  GeneratedColumn<String> get companionDeviceKey => $composableBuilder(
      column: $table.companionDeviceKey, builder: (column) => column);
}

class $$ChannelsTableTableManager extends RootTableManager<
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
    PrefetchHooks Function()> {
  $$ChannelsTableTableManager(_$AppDatabase db, $ChannelsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> hash = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<Uint8List> sharedKey = const Value.absent(),
            Value<bool> isPublic = const Value.absent(),
            Value<bool> shareLocation = const Value.absent(),
            Value<int> channelIndex = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<bool> muteNotifications = const Value.absent(),
            Value<String?> companionDeviceKey = const Value.absent(),
          }) =>
              ChannelsCompanion(
            hash: hash,
            name: name,
            sharedKey: sharedKey,
            isPublic: isPublic,
            shareLocation: shareLocation,
            channelIndex: channelIndex,
            createdAt: createdAt,
            muteNotifications: muteNotifications,
            companionDeviceKey: companionDeviceKey,
          ),
          createCompanionCallback: ({
            Value<int> hash = const Value.absent(),
            required String name,
            required Uint8List sharedKey,
            required bool isPublic,
            Value<bool> shareLocation = const Value.absent(),
            required int channelIndex,
            required int createdAt,
            Value<bool> muteNotifications = const Value.absent(),
            Value<String?> companionDeviceKey = const Value.absent(),
          }) =>
              ChannelsCompanion.insert(
            hash: hash,
            name: name,
            sharedKey: sharedKey,
            isPublic: isPublic,
            shareLocation: shareLocation,
            channelIndex: channelIndex,
            createdAt: createdAt,
            muteNotifications: muteNotifications,
            companionDeviceKey: companionDeviceKey,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChannelsTableProcessedTableManager = ProcessedTableManager<
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
    PrefetchHooks Function()>;
typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
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
  Value<int> rowid,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
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
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get senderId => $composableBuilder(
      column: $table.senderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get senderName => $composableBuilder(
      column: $table.senderName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get channelHash => $composableBuilder(
      column: $table.channelHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPrivate => $composableBuilder(
      column: $table.isPrivate, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get ackChecksum => $composableBuilder(
      column: $table.ackChecksum, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deliveryStatus => $composableBuilder(
      column: $table.deliveryStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get heardByCount => $composableBuilder(
      column: $table.heardByCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempt => $composableBuilder(
      column: $table.attempt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSentByMe => $composableBuilder(
      column: $table.isSentByMe, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companionDeviceKey => $composableBuilder(
      column: $table.companionDeviceKey,
      builder: (column) => ColumnFilters(column));
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
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get senderId => $composableBuilder(
      column: $table.senderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get senderName => $composableBuilder(
      column: $table.senderName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get channelHash => $composableBuilder(
      column: $table.channelHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPrivate => $composableBuilder(
      column: $table.isPrivate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get ackChecksum => $composableBuilder(
      column: $table.ackChecksum, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deliveryStatus => $composableBuilder(
      column: $table.deliveryStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get heardByCount => $composableBuilder(
      column: $table.heardByCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempt => $composableBuilder(
      column: $table.attempt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSentByMe => $composableBuilder(
      column: $table.isSentByMe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companionDeviceKey => $composableBuilder(
      column: $table.companionDeviceKey,
      builder: (column) => ColumnOrderings(column));
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
      column: $table.senderName, builder: (column) => column);

  GeneratedColumn<int> get channelHash => $composableBuilder(
      column: $table.channelHash, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get isPrivate =>
      $composableBuilder(column: $table.isPrivate, builder: (column) => column);

  GeneratedColumn<Uint8List> get ackChecksum => $composableBuilder(
      column: $table.ackChecksum, builder: (column) => column);

  GeneratedColumn<String> get deliveryStatus => $composableBuilder(
      column: $table.deliveryStatus, builder: (column) => column);

  GeneratedColumn<int> get heardByCount => $composableBuilder(
      column: $table.heardByCount, builder: (column) => column);

  GeneratedColumn<int> get attempt =>
      $composableBuilder(column: $table.attempt, builder: (column) => column);

  GeneratedColumn<bool> get isSentByMe => $composableBuilder(
      column: $table.isSentByMe, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<String> get companionDeviceKey => $composableBuilder(
      column: $table.companionDeviceKey, builder: (column) => column);
}

class $$MessagesTableTableManager extends RootTableManager<
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
    PrefetchHooks Function()> {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
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
            Value<int> rowid = const Value.absent(),
          }) =>
              MessagesCompanion(
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
            rowid: rowid,
          ),
          createCompanionCallback: ({
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
            Value<int> rowid = const Value.absent(),
          }) =>
              MessagesCompanion.insert(
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
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MessagesTableProcessedTableManager = ProcessedTableManager<
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
    PrefetchHooks Function()>;
typedef $$WaypointsTableCreateCompanionBuilder = WaypointsCompanion Function({
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
typedef $$WaypointsTableUpdateCompanionBuilder = WaypointsCompanion Function({
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
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meshId => $composableBuilder(
      column: $table.meshId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get waypointType => $composableBuilder(
      column: $table.waypointType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get creatorNodeId => $composableBuilder(
      column: $table.creatorNodeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isReceived => $composableBuilder(
      column: $table.isReceived, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isVisible => $composableBuilder(
      column: $table.isVisible, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isNew => $composableBuilder(
      column: $table.isNew, builder: (column) => ColumnFilters(column));
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
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meshId => $composableBuilder(
      column: $table.meshId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get waypointType => $composableBuilder(
      column: $table.waypointType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get creatorNodeId => $composableBuilder(
      column: $table.creatorNodeId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isReceived => $composableBuilder(
      column: $table.isReceived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isVisible => $composableBuilder(
      column: $table.isVisible, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isNew => $composableBuilder(
      column: $table.isNew, builder: (column) => ColumnOrderings(column));
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
      column: $table.description, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get waypointType => $composableBuilder(
      column: $table.waypointType, builder: (column) => column);

  GeneratedColumn<String> get creatorNodeId => $composableBuilder(
      column: $table.creatorNodeId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isReceived => $composableBuilder(
      column: $table.isReceived, builder: (column) => column);

  GeneratedColumn<bool> get isVisible =>
      $composableBuilder(column: $table.isVisible, builder: (column) => column);

  GeneratedColumn<bool> get isNew =>
      $composableBuilder(column: $table.isNew, builder: (column) => column);
}

class $$WaypointsTableTableManager extends RootTableManager<
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
      BaseReferences<_$AppDatabase, $WaypointsTable, WaypointData>
    ),
    WaypointData,
    PrefetchHooks Function()> {
  $$WaypointsTableTableManager(_$AppDatabase db, $WaypointsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WaypointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WaypointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WaypointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
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
          }) =>
              WaypointsCompanion(
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
          createCompanionCallback: ({
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
          }) =>
              WaypointsCompanion.insert(
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
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WaypointsTableProcessedTableManager = ProcessedTableManager<
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
      BaseReferences<_$AppDatabase, $WaypointsTable, WaypointData>
    ),
    WaypointData,
    PrefetchHooks Function()>;
typedef $$CompanionDevicesTableCreateCompanionBuilder
    = CompanionDevicesCompanion Function({
  required String publicKeyHex,
  required String name,
  required int firstConnected,
  required int lastConnected,
  Value<int> connectionCount,
  Value<int> rowid,
});
typedef $$CompanionDevicesTableUpdateCompanionBuilder
    = CompanionDevicesCompanion Function({
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
      column: $table.publicKeyHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get firstConnected => $composableBuilder(
      column: $table.firstConnected,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastConnected => $composableBuilder(
      column: $table.lastConnected, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get connectionCount => $composableBuilder(
      column: $table.connectionCount,
      builder: (column) => ColumnFilters(column));
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
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get firstConnected => $composableBuilder(
      column: $table.firstConnected,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastConnected => $composableBuilder(
      column: $table.lastConnected,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get connectionCount => $composableBuilder(
      column: $table.connectionCount,
      builder: (column) => ColumnOrderings(column));
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
      column: $table.publicKeyHex, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get firstConnected => $composableBuilder(
      column: $table.firstConnected, builder: (column) => column);

  GeneratedColumn<int> get lastConnected => $composableBuilder(
      column: $table.lastConnected, builder: (column) => column);

  GeneratedColumn<int> get connectionCount => $composableBuilder(
      column: $table.connectionCount, builder: (column) => column);
}

class $$CompanionDevicesTableTableManager extends RootTableManager<
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
      BaseReferences<_$AppDatabase, $CompanionDevicesTable, CompanionDeviceData>
    ),
    CompanionDeviceData,
    PrefetchHooks Function()> {
  $$CompanionDevicesTableTableManager(
      _$AppDatabase db, $CompanionDevicesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompanionDevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompanionDevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompanionDevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> publicKeyHex = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> firstConnected = const Value.absent(),
            Value<int> lastConnected = const Value.absent(),
            Value<int> connectionCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CompanionDevicesCompanion(
            publicKeyHex: publicKeyHex,
            name: name,
            firstConnected: firstConnected,
            lastConnected: lastConnected,
            connectionCount: connectionCount,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String publicKeyHex,
            required String name,
            required int firstConnected,
            required int lastConnected,
            Value<int> connectionCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CompanionDevicesCompanion.insert(
            publicKeyHex: publicKeyHex,
            name: name,
            firstConnected: firstConnected,
            lastConnected: lastConnected,
            connectionCount: connectionCount,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CompanionDevicesTableProcessedTableManager = ProcessedTableManager<
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
      BaseReferences<_$AppDatabase, $CompanionDevicesTable, CompanionDeviceData>
    ),
    CompanionDeviceData,
    PrefetchHooks Function()>;
typedef $$ContactDisplayStatesTableCreateCompanionBuilder
    = ContactDisplayStatesCompanion Function({
  required String publicKeyHex,
  required String companionDeviceKey,
  required int lastSeen,
  Value<double?> lastLatitude,
  Value<double?> lastLongitude,
  required int lastChannelIdx,
  required int lastPathLen,
  Value<bool> isManuallyHidden,
  Value<int?> hiddenAt,
  Value<String?> name,
  required int firstSeen,
  Value<int> totalTelemetryReceived,
  Value<bool> isAutonomousDevice,
  Value<int> rowid,
});
typedef $$ContactDisplayStatesTableUpdateCompanionBuilder
    = ContactDisplayStatesCompanion Function({
  Value<String> publicKeyHex,
  Value<String> companionDeviceKey,
  Value<int> lastSeen,
  Value<double?> lastLatitude,
  Value<double?> lastLongitude,
  Value<int> lastChannelIdx,
  Value<int> lastPathLen,
  Value<bool> isManuallyHidden,
  Value<int?> hiddenAt,
  Value<String?> name,
  Value<int> firstSeen,
  Value<int> totalTelemetryReceived,
  Value<bool> isAutonomousDevice,
  Value<int> rowid,
});

class $$ContactDisplayStatesTableFilterComposer
    extends Composer<_$AppDatabase, $ContactDisplayStatesTable> {
  $$ContactDisplayStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get publicKeyHex => $composableBuilder(
      column: $table.publicKeyHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companionDeviceKey => $composableBuilder(
      column: $table.companionDeviceKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastSeen => $composableBuilder(
      column: $table.lastSeen, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lastLatitude => $composableBuilder(
      column: $table.lastLatitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lastLongitude => $composableBuilder(
      column: $table.lastLongitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastChannelIdx => $composableBuilder(
      column: $table.lastChannelIdx,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastPathLen => $composableBuilder(
      column: $table.lastPathLen, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isManuallyHidden => $composableBuilder(
      column: $table.isManuallyHidden,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hiddenAt => $composableBuilder(
      column: $table.hiddenAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get firstSeen => $composableBuilder(
      column: $table.firstSeen, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalTelemetryReceived => $composableBuilder(
      column: $table.totalTelemetryReceived,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isAutonomousDevice => $composableBuilder(
      column: $table.isAutonomousDevice,
      builder: (column) => ColumnFilters(column));
}

class $$ContactDisplayStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactDisplayStatesTable> {
  $$ContactDisplayStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get publicKeyHex => $composableBuilder(
      column: $table.publicKeyHex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companionDeviceKey => $composableBuilder(
      column: $table.companionDeviceKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastSeen => $composableBuilder(
      column: $table.lastSeen, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lastLatitude => $composableBuilder(
      column: $table.lastLatitude,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lastLongitude => $composableBuilder(
      column: $table.lastLongitude,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastChannelIdx => $composableBuilder(
      column: $table.lastChannelIdx,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastPathLen => $composableBuilder(
      column: $table.lastPathLen, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isManuallyHidden => $composableBuilder(
      column: $table.isManuallyHidden,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hiddenAt => $composableBuilder(
      column: $table.hiddenAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get firstSeen => $composableBuilder(
      column: $table.firstSeen, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalTelemetryReceived => $composableBuilder(
      column: $table.totalTelemetryReceived,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isAutonomousDevice => $composableBuilder(
      column: $table.isAutonomousDevice,
      builder: (column) => ColumnOrderings(column));
}

class $$ContactDisplayStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactDisplayStatesTable> {
  $$ContactDisplayStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get publicKeyHex => $composableBuilder(
      column: $table.publicKeyHex, builder: (column) => column);

  GeneratedColumn<String> get companionDeviceKey => $composableBuilder(
      column: $table.companionDeviceKey, builder: (column) => column);

  GeneratedColumn<int> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);

  GeneratedColumn<double> get lastLatitude => $composableBuilder(
      column: $table.lastLatitude, builder: (column) => column);

  GeneratedColumn<double> get lastLongitude => $composableBuilder(
      column: $table.lastLongitude, builder: (column) => column);

  GeneratedColumn<int> get lastChannelIdx => $composableBuilder(
      column: $table.lastChannelIdx, builder: (column) => column);

  GeneratedColumn<int> get lastPathLen => $composableBuilder(
      column: $table.lastPathLen, builder: (column) => column);

  GeneratedColumn<bool> get isManuallyHidden => $composableBuilder(
      column: $table.isManuallyHidden, builder: (column) => column);

  GeneratedColumn<int> get hiddenAt =>
      $composableBuilder(column: $table.hiddenAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get firstSeen =>
      $composableBuilder(column: $table.firstSeen, builder: (column) => column);

  GeneratedColumn<int> get totalTelemetryReceived => $composableBuilder(
      column: $table.totalTelemetryReceived, builder: (column) => column);

  GeneratedColumn<bool> get isAutonomousDevice => $composableBuilder(
      column: $table.isAutonomousDevice, builder: (column) => column);
}

class $$ContactDisplayStatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ContactDisplayStatesTable,
    ContactDisplayStateData,
    $$ContactDisplayStatesTableFilterComposer,
    $$ContactDisplayStatesTableOrderingComposer,
    $$ContactDisplayStatesTableAnnotationComposer,
    $$ContactDisplayStatesTableCreateCompanionBuilder,
    $$ContactDisplayStatesTableUpdateCompanionBuilder,
    (
      ContactDisplayStateData,
      BaseReferences<_$AppDatabase, $ContactDisplayStatesTable,
          ContactDisplayStateData>
    ),
    ContactDisplayStateData,
    PrefetchHooks Function()> {
  $$ContactDisplayStatesTableTableManager(
      _$AppDatabase db, $ContactDisplayStatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactDisplayStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactDisplayStatesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactDisplayStatesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> publicKeyHex = const Value.absent(),
            Value<String> companionDeviceKey = const Value.absent(),
            Value<int> lastSeen = const Value.absent(),
            Value<double?> lastLatitude = const Value.absent(),
            Value<double?> lastLongitude = const Value.absent(),
            Value<int> lastChannelIdx = const Value.absent(),
            Value<int> lastPathLen = const Value.absent(),
            Value<bool> isManuallyHidden = const Value.absent(),
            Value<int?> hiddenAt = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<int> firstSeen = const Value.absent(),
            Value<int> totalTelemetryReceived = const Value.absent(),
            Value<bool> isAutonomousDevice = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ContactDisplayStatesCompanion(
            publicKeyHex: publicKeyHex,
            companionDeviceKey: companionDeviceKey,
            lastSeen: lastSeen,
            lastLatitude: lastLatitude,
            lastLongitude: lastLongitude,
            lastChannelIdx: lastChannelIdx,
            lastPathLen: lastPathLen,
            isManuallyHidden: isManuallyHidden,
            hiddenAt: hiddenAt,
            name: name,
            firstSeen: firstSeen,
            totalTelemetryReceived: totalTelemetryReceived,
            isAutonomousDevice: isAutonomousDevice,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String publicKeyHex,
            required String companionDeviceKey,
            required int lastSeen,
            Value<double?> lastLatitude = const Value.absent(),
            Value<double?> lastLongitude = const Value.absent(),
            required int lastChannelIdx,
            required int lastPathLen,
            Value<bool> isManuallyHidden = const Value.absent(),
            Value<int?> hiddenAt = const Value.absent(),
            Value<String?> name = const Value.absent(),
            required int firstSeen,
            Value<int> totalTelemetryReceived = const Value.absent(),
            Value<bool> isAutonomousDevice = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ContactDisplayStatesCompanion.insert(
            publicKeyHex: publicKeyHex,
            companionDeviceKey: companionDeviceKey,
            lastSeen: lastSeen,
            lastLatitude: lastLatitude,
            lastLongitude: lastLongitude,
            lastChannelIdx: lastChannelIdx,
            lastPathLen: lastPathLen,
            isManuallyHidden: isManuallyHidden,
            hiddenAt: hiddenAt,
            name: name,
            firstSeen: firstSeen,
            totalTelemetryReceived: totalTelemetryReceived,
            isAutonomousDevice: isAutonomousDevice,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ContactDisplayStatesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ContactDisplayStatesTable,
        ContactDisplayStateData,
        $$ContactDisplayStatesTableFilterComposer,
        $$ContactDisplayStatesTableOrderingComposer,
        $$ContactDisplayStatesTableAnnotationComposer,
        $$ContactDisplayStatesTableCreateCompanionBuilder,
        $$ContactDisplayStatesTableUpdateCompanionBuilder,
        (
          ContactDisplayStateData,
          BaseReferences<_$AppDatabase, $ContactDisplayStatesTable,
              ContactDisplayStateData>
        ),
        ContactDisplayStateData,
        PrefetchHooks Function()>;
typedef $$ContactPositionHistoriesTableCreateCompanionBuilder
    = ContactPositionHistoriesCompanion Function({
  Value<int> id,
  required String publicKeyHex,
  required String companionDeviceKey,
  required int timestamp,
  required double latitude,
  required double longitude,
  Value<double?> accuracy,
  required int channelIdx,
  required int pathLen,
  Value<double?> batteryVoltage,
  required int binLevel,
  required bool isAggregated,
});
typedef $$ContactPositionHistoriesTableUpdateCompanionBuilder
    = ContactPositionHistoriesCompanion Function({
  Value<int> id,
  Value<String> publicKeyHex,
  Value<String> companionDeviceKey,
  Value<int> timestamp,
  Value<double> latitude,
  Value<double> longitude,
  Value<double?> accuracy,
  Value<int> channelIdx,
  Value<int> pathLen,
  Value<double?> batteryVoltage,
  Value<int> binLevel,
  Value<bool> isAggregated,
});

class $$ContactPositionHistoriesTableFilterComposer
    extends Composer<_$AppDatabase, $ContactPositionHistoriesTable> {
  $$ContactPositionHistoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get publicKeyHex => $composableBuilder(
      column: $table.publicKeyHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companionDeviceKey => $composableBuilder(
      column: $table.companionDeviceKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get accuracy => $composableBuilder(
      column: $table.accuracy, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get channelIdx => $composableBuilder(
      column: $table.channelIdx, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pathLen => $composableBuilder(
      column: $table.pathLen, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get batteryVoltage => $composableBuilder(
      column: $table.batteryVoltage,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get binLevel => $composableBuilder(
      column: $table.binLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isAggregated => $composableBuilder(
      column: $table.isAggregated, builder: (column) => ColumnFilters(column));
}

class $$ContactPositionHistoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactPositionHistoriesTable> {
  $$ContactPositionHistoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get publicKeyHex => $composableBuilder(
      column: $table.publicKeyHex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companionDeviceKey => $composableBuilder(
      column: $table.companionDeviceKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get accuracy => $composableBuilder(
      column: $table.accuracy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get channelIdx => $composableBuilder(
      column: $table.channelIdx, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pathLen => $composableBuilder(
      column: $table.pathLen, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get batteryVoltage => $composableBuilder(
      column: $table.batteryVoltage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get binLevel => $composableBuilder(
      column: $table.binLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isAggregated => $composableBuilder(
      column: $table.isAggregated,
      builder: (column) => ColumnOrderings(column));
}

class $$ContactPositionHistoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactPositionHistoriesTable> {
  $$ContactPositionHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get publicKeyHex => $composableBuilder(
      column: $table.publicKeyHex, builder: (column) => column);

  GeneratedColumn<String> get companionDeviceKey => $composableBuilder(
      column: $table.companionDeviceKey, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<int> get channelIdx => $composableBuilder(
      column: $table.channelIdx, builder: (column) => column);

  GeneratedColumn<int> get pathLen =>
      $composableBuilder(column: $table.pathLen, builder: (column) => column);

  GeneratedColumn<double> get batteryVoltage => $composableBuilder(
      column: $table.batteryVoltage, builder: (column) => column);

  GeneratedColumn<int> get binLevel =>
      $composableBuilder(column: $table.binLevel, builder: (column) => column);

  GeneratedColumn<bool> get isAggregated => $composableBuilder(
      column: $table.isAggregated, builder: (column) => column);
}

class $$ContactPositionHistoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ContactPositionHistoriesTable,
    ContactPositionHistoryData,
    $$ContactPositionHistoriesTableFilterComposer,
    $$ContactPositionHistoriesTableOrderingComposer,
    $$ContactPositionHistoriesTableAnnotationComposer,
    $$ContactPositionHistoriesTableCreateCompanionBuilder,
    $$ContactPositionHistoriesTableUpdateCompanionBuilder,
    (
      ContactPositionHistoryData,
      BaseReferences<_$AppDatabase, $ContactPositionHistoriesTable,
          ContactPositionHistoryData>
    ),
    ContactPositionHistoryData,
    PrefetchHooks Function()> {
  $$ContactPositionHistoriesTableTableManager(
      _$AppDatabase db, $ContactPositionHistoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactPositionHistoriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactPositionHistoriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactPositionHistoriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> publicKeyHex = const Value.absent(),
            Value<String> companionDeviceKey = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<double?> accuracy = const Value.absent(),
            Value<int> channelIdx = const Value.absent(),
            Value<int> pathLen = const Value.absent(),
            Value<double?> batteryVoltage = const Value.absent(),
            Value<int> binLevel = const Value.absent(),
            Value<bool> isAggregated = const Value.absent(),
          }) =>
              ContactPositionHistoriesCompanion(
            id: id,
            publicKeyHex: publicKeyHex,
            companionDeviceKey: companionDeviceKey,
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            channelIdx: channelIdx,
            pathLen: pathLen,
            batteryVoltage: batteryVoltage,
            binLevel: binLevel,
            isAggregated: isAggregated,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String publicKeyHex,
            required String companionDeviceKey,
            required int timestamp,
            required double latitude,
            required double longitude,
            Value<double?> accuracy = const Value.absent(),
            required int channelIdx,
            required int pathLen,
            Value<double?> batteryVoltage = const Value.absent(),
            required int binLevel,
            required bool isAggregated,
          }) =>
              ContactPositionHistoriesCompanion.insert(
            id: id,
            publicKeyHex: publicKeyHex,
            companionDeviceKey: companionDeviceKey,
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            channelIdx: channelIdx,
            pathLen: pathLen,
            batteryVoltage: batteryVoltage,
            binLevel: binLevel,
            isAggregated: isAggregated,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ContactPositionHistoriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ContactPositionHistoriesTable,
        ContactPositionHistoryData,
        $$ContactPositionHistoriesTableFilterComposer,
        $$ContactPositionHistoriesTableOrderingComposer,
        $$ContactPositionHistoriesTableAnnotationComposer,
        $$ContactPositionHistoriesTableCreateCompanionBuilder,
        $$ContactPositionHistoriesTableUpdateCompanionBuilder,
        (
          ContactPositionHistoryData,
          BaseReferences<_$AppDatabase, $ContactPositionHistoriesTable,
              ContactPositionHistoryData>
        ),
        ContactPositionHistoryData,
        PrefetchHooks Function()>;
typedef $$AckRecordsTableCreateCompanionBuilder = AckRecordsCompanion Function({
  required String messageId,
  required Uint8List ackerPublicKey,
  required int receivedAt,
  Value<int?> snr,
  Value<int?> rssi,
  Value<String?> companionDeviceKey,
  Value<int> rowid,
});
typedef $$AckRecordsTableUpdateCompanionBuilder = AckRecordsCompanion Function({
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
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get ackerPublicKey => $composableBuilder(
      column: $table.ackerPublicKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get snr => $composableBuilder(
      column: $table.snr, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rssi => $composableBuilder(
      column: $table.rssi, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companionDeviceKey => $composableBuilder(
      column: $table.companionDeviceKey,
      builder: (column) => ColumnFilters(column));
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
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get ackerPublicKey => $composableBuilder(
      column: $table.ackerPublicKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get snr => $composableBuilder(
      column: $table.snr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rssi => $composableBuilder(
      column: $table.rssi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companionDeviceKey => $composableBuilder(
      column: $table.companionDeviceKey,
      builder: (column) => ColumnOrderings(column));
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
      column: $table.ackerPublicKey, builder: (column) => column);

  GeneratedColumn<int> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => column);

  GeneratedColumn<int> get snr =>
      $composableBuilder(column: $table.snr, builder: (column) => column);

  GeneratedColumn<int> get rssi =>
      $composableBuilder(column: $table.rssi, builder: (column) => column);

  GeneratedColumn<String> get companionDeviceKey => $composableBuilder(
      column: $table.companionDeviceKey, builder: (column) => column);
}

class $$AckRecordsTableTableManager extends RootTableManager<
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
      BaseReferences<_$AppDatabase, $AckRecordsTable, AckRecordData>
    ),
    AckRecordData,
    PrefetchHooks Function()> {
  $$AckRecordsTableTableManager(_$AppDatabase db, $AckRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AckRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AckRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AckRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> messageId = const Value.absent(),
            Value<Uint8List> ackerPublicKey = const Value.absent(),
            Value<int> receivedAt = const Value.absent(),
            Value<int?> snr = const Value.absent(),
            Value<int?> rssi = const Value.absent(),
            Value<String?> companionDeviceKey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AckRecordsCompanion(
            messageId: messageId,
            ackerPublicKey: ackerPublicKey,
            receivedAt: receivedAt,
            snr: snr,
            rssi: rssi,
            companionDeviceKey: companionDeviceKey,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String messageId,
            required Uint8List ackerPublicKey,
            required int receivedAt,
            Value<int?> snr = const Value.absent(),
            Value<int?> rssi = const Value.absent(),
            Value<String?> companionDeviceKey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AckRecordsCompanion.insert(
            messageId: messageId,
            ackerPublicKey: ackerPublicKey,
            receivedAt: receivedAt,
            snr: snr,
            rssi: rssi,
            companionDeviceKey: companionDeviceKey,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AckRecordsTableProcessedTableManager = ProcessedTableManager<
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
      BaseReferences<_$AppDatabase, $AckRecordsTable, AckRecordData>
    ),
    AckRecordData,
    PrefetchHooks Function()>;
typedef $$OfflineMapAreasTableCreateCompanionBuilder = OfflineMapAreasCompanion
    Function({
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
typedef $$OfflineMapAreasTableUpdateCompanionBuilder = OfflineMapAreasCompanion
    Function({
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
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get north => $composableBuilder(
      column: $table.north, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get south => $composableBuilder(
      column: $table.south, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get east => $composableBuilder(
      column: $table.east, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get west => $composableBuilder(
      column: $table.west, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minZoom => $composableBuilder(
      column: $table.minZoom, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxZoom => $composableBuilder(
      column: $table.maxZoom, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tileCount => $composableBuilder(
      column: $table.tileCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnFilters(column));
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
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get north => $composableBuilder(
      column: $table.north, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get south => $composableBuilder(
      column: $table.south, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get east => $composableBuilder(
      column: $table.east, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get west => $composableBuilder(
      column: $table.west, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minZoom => $composableBuilder(
      column: $table.minZoom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxZoom => $composableBuilder(
      column: $table.maxZoom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tileCount => $composableBuilder(
      column: $table.tileCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));
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
      column: $table.providerId, builder: (column) => column);

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
      column: $table.downloadedAt, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);
}

class $$OfflineMapAreasTableTableManager extends RootTableManager<
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
      BaseReferences<_$AppDatabase, $OfflineMapAreasTable, OfflineMapAreaData>
    ),
    OfflineMapAreaData,
    PrefetchHooks Function()> {
  $$OfflineMapAreasTableTableManager(
      _$AppDatabase db, $OfflineMapAreasTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineMapAreasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineMapAreasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineMapAreasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
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
          }) =>
              OfflineMapAreasCompanion(
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
          createCompanionCallback: ({
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
          }) =>
              OfflineMapAreasCompanion.insert(
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
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OfflineMapAreasTableProcessedTableManager = ProcessedTableManager<
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
      BaseReferences<_$AppDatabase, $OfflineMapAreasTable, OfflineMapAreaData>
    ),
    OfflineMapAreaData,
    PrefetchHooks Function()>;

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
  $$ContactDisplayStatesTableTableManager get contactDisplayStates =>
      $$ContactDisplayStatesTableTableManager(_db, _db.contactDisplayStates);
  $$ContactPositionHistoriesTableTableManager get contactPositionHistories =>
      $$ContactPositionHistoriesTableTableManager(
          _db, _db.contactPositionHistories);
  $$AckRecordsTableTableManager get ackRecords =>
      $$AckRecordsTableTableManager(_db, _db.ackRecords);
  $$OfflineMapAreasTableTableManager get offlineMapAreas =>
      $$OfflineMapAreasTableTableManager(_db, _db.offlineMapAreas);
}
