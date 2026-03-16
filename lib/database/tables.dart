// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'package:drift/drift.dart';

/// Contacts table - stores mesh network nodes/contacts
/// Matches Android NodeEntity
@DataClassName('ContactData')
class Contacts extends Table {
  BlobColumn get publicKey => blob()(); // 32-byte public key (primary key)
  IntColumn get hash => integer()(); // Hash derived from full public key
  TextColumn get name => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  IntColumn get lastSeen => integer()(); // Unix timestamp in milliseconds
  IntColumn get companionBatteryMilliVolts =>
      integer().nullable()(); // Companion radio battery
  IntColumn get phoneBatteryMilliVolts =>
      integer().nullable()(); // Phone battery
  BoolColumn get isRepeater => boolean().withDefault(const Constant(false))();
  BoolColumn get isRoomServer => boolean().withDefault(const Constant(false))();
  BoolColumn get isDirect =>
      boolean().withDefault(const Constant(false))(); // True if 0 hops
  IntColumn get hopCount => integer()
      .withDefault(const Constant(-1))(); // Number of relay hops (-1 = unknown)
  IntColumn get lastTelemetryChannelIdx =>
      integer().nullable()(); // Which channel we received telemetry on
  IntColumn get lastTelemetryTimestamp =>
      integer().nullable()(); // When we last received telemetry
  BoolColumn get isOutOfRange => boolean()
      .withDefault(const Constant(false))(); // Marked by forwarding manager
  BoolColumn get isAutonomousDevice => boolean().withDefault(const Constant(
      false))(); // Remote device is in autonomous mode (no phone attached)
  TextColumn get companionDeviceKey => text()
      .nullable()(); // Which companion this contact belongs to (hex string)

  @override
  Set<Column> get primaryKey => {publicKey};
}

/// Channels table - stores public and private channels
/// Matches Android ChannelEntity
@DataClassName('ChannelData')
class Channels extends Table {
  IntColumn get hash => integer()(); // Hash derived from PSK (primary key)
  TextColumn get name => text()();
  BlobColumn get sharedKey => blob()(); // 16-byte pre-shared key
  BoolColumn get isPublic => boolean()();
  BoolColumn get shareLocation => boolean()
      .withDefault(const Constant(false))(); // Location sharing enabled
  IntColumn get channelIndex =>
      integer()(); // Firmware channel slot (0=public, 1-3=private)
  IntColumn get createdAt => integer()(); // Unix timestamp
  BoolColumn get muteNotifications =>
      boolean().withDefault(const Constant(false))();
  TextColumn get companionDeviceKey =>
      text().nullable()(); // Which companion this channel belongs to

  @override
  Set<Column> get primaryKey => {hash};
}

/// Messages table - stores sent and received chat messages
/// Matches Android MessageEntity
@DataClassName('MessageData')
class Messages extends Table {
  TextColumn get id => text()(); // UUID (primary key)
  BlobColumn get senderId => blob()(); // 32-byte sender public key
  TextColumn get senderName => text().nullable()();
  IntColumn get channelHash => integer()(); // References Channels.hash
  TextColumn get content => text()();
  IntColumn get timestamp => integer()(); // Unix timestamp
  BoolColumn get isPrivate =>
      boolean()(); // True for DMs, false for channel messages
  BlobColumn get ackChecksum =>
      blob().nullable()(); // Expected ACK checksum for delivery tracking
  TextColumn get deliveryStatus => text()(); // 'SENDING', 'SENT', 'DELIVERED'
  IntColumn get heardByCount =>
      integer().withDefault(const Constant(0))(); // Number of ACKs received
  IntColumn get attempt =>
      integer().withDefault(const Constant(0))(); // Retry attempt number
  BoolColumn get isSentByMe => boolean()();
  BoolColumn get isRead =>
      boolean().withDefault(const Constant(false))(); // Message read status
  TextColumn get companionDeviceKey => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Waypoints table - stores GPS waypoints for map markers
/// Matches Android Waypoint entity
@DataClassName('WaypointData')
class Waypoints extends Table {
  TextColumn get id => text()(); // UUID (primary key)
  TextColumn get meshId =>
      text().nullable()(); // Unique ID for tracking across mesh network
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get waypointType =>
      text()(); // WaypointType enum: CAMP, MEETUP, DANGER, GAME, STAND, WATER, VEHICLE, CUSTOM
  TextColumn get creatorNodeId =>
      text()(); // Who created this waypoint (hex string of public key)
  IntColumn get createdAt => integer()(); // Unix timestamp
  BoolColumn get isReceived => boolean().withDefault(const Constant(
      false))(); // false = user created, true = received from mesh
  BoolColumn get isVisible => boolean().withDefault(const Constant(true))();
  BoolColumn get isNew => boolean()
      .withDefault(const Constant(false))(); // true = unviewed waypoint

  @override
  Set<Column> get primaryKey => {id};
}

/// Companion devices table - tracks BLE devices that have been connected
/// Matches Android CompanionDeviceEntity
@DataClassName('CompanionDeviceData')
class CompanionDevices extends Table {
  TextColumn get publicKeyHex =>
      text()(); // 64-char hex string (32 bytes) (primary key)
  TextColumn get name => text()();
  IntColumn get firstConnected => integer()(); // Unix timestamp
  IntColumn get lastConnected => integer()(); // Unix timestamp
  IntColumn get connectionCount => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {publicKeyHex};
}

/// Contact display state table - persistent state for contact display on map
/// Matches Android ContactDisplayStateEntity
@DataClassName('ContactDisplayStateData')
class ContactDisplayStates extends Table {
  TextColumn get publicKeyHex =>
      text()(); // Hex string of public key (primary key)
  TextColumn get companionDeviceKey => text()();
  IntColumn get lastSeen => integer()(); // Last telemetry received timestamp
  RealColumn get lastLatitude => real().nullable()();
  RealColumn get lastLongitude => real().nullable()();
  IntColumn get lastChannelIdx => integer()(); // Which channel they were on
  IntColumn get lastPathLen => integer()(); // Hop count (for color coding)
  BoolColumn get isManuallyHidden => boolean()
      .withDefault(const Constant(false))(); // User clicked "Remove from Group"
  IntColumn get hiddenAt => integer().nullable()(); // When manually hidden
  TextColumn get name => text().nullable()();
  IntColumn get firstSeen => integer()(); // When first discovered
  IntColumn get totalTelemetryReceived =>
      integer().withDefault(const Constant(0))();
  BoolColumn get isAutonomousDevice => boolean().withDefault(const Constant(
      false))(); // Contact is an autonomous GPS tracker (no phone)

  @override
  Set<Column> get primaryKey => {publicKeyHex};
}

/// Contact position history table - historical position tracking with variable-time binning
/// Matches Android ContactPositionHistoryEntity
@DataClassName('ContactPositionHistoryData')
class ContactPositionHistories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get publicKeyHex =>
      text()(); // Which contact this position belongs to
  TextColumn get companionDeviceKey => text()();
  IntColumn get timestamp => integer()(); // Unix timestamp
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get accuracy => real().nullable()(); // GPS accuracy if available
  IntColumn get channelIdx =>
      integer()(); // Which channel this telemetry came on
  IntColumn get pathLen => integer()(); // Hop count at this position
  RealColumn get batteryVoltage =>
      real().nullable()(); // Battery level if available
  IntColumn get binLevel => integer()(); // 0=raw, 1=5min, 2=30min, 3=1hr
  BoolColumn get isAggregated =>
      boolean()(); // True if averaged from multiple points
}

/// ACK records table - tracks message acknowledgments
/// Matches Android AckRecordEntity
@DataClassName('AckRecordData')
class AckRecords extends Table {
  TextColumn get messageId => text()(); // References Messages.id
  BlobColumn get ackerPublicKey => blob()(); // Who sent the ACK (32 bytes)
  IntColumn get receivedAt => integer()(); // When we received the ACK
  IntColumn get snr => integer().nullable()(); // Signal-to-noise ratio
  IntColumn get rssi => integer().nullable()(); // Signal strength
  TextColumn get companionDeviceKey =>
      text().nullable()(); // Which companion this ACK belongs to

  @override
  Set<Column> get primaryKey => {messageId, ackerPublicKey};
}

/// Offline map areas table - metadata for downloaded map regions
/// Matches Android OfflineMapAreaEntity
@DataClassName('OfflineMapAreaData')
class OfflineMapAreas extends Table {
  TextColumn get id => text()(); // UUID (primary key)
  TextColumn get name => text()();
  TextColumn get providerId => text()();
  RealColumn get north => real()();
  RealColumn get south => real()();
  RealColumn get east => real()();
  RealColumn get west => real()();
  IntColumn get minZoom => integer()();
  IntColumn get maxZoom => integer()();
  IntColumn get tileCount => integer()();
  IntColumn get downloadedAt => integer()(); // Unix timestamp ms
  IntColumn get sizeBytes => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
