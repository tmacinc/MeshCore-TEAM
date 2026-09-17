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
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))();

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
  TextColumn get notificationMode =>
      text().withDefault(const Constant('normal'))();
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))();
  TextColumn get companionDeviceKey =>
      text().nullable()(); // Which companion this channel belongs to

  /// Owned by the phone rather than the radio: kept across radio switches,
  /// pushed to a radio that doesn't have it, and its history is kept.
  /// Only ever true for a private channel with a secret key.
  BoolColumn get isTeam => boolean().withDefault(const Constant(false))();

  /// False when the channel is not in the current radio's slots — either
  /// never pushed, or the radio no longer has it. Named to match the Team
  /// Link branch so the two converge on merge.
  BoolColumn get firmwareConfirmed =>
      boolean().withDefault(const Constant(true))();

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
  IntColumn get senderPeerId =>
      integer().nullable()(); // Resolved sender, set on receive when known

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

/// Peers table - one row per person we know from team traffic.
///
/// [id] is local to this phone and never transmitted. Every way a peer can be
/// identified on the wire (radio name, radio key, Link app identity) is a
/// nullable column, so peers survive radio switches and renames, and a peer
/// first heard only by name can later be bound to its key.
@DataClassName('PeerData')
class Peers extends Table {
  IntColumn get id => integer().autoIncrement()();
  BlobColumn get radioPublicKey =>
      blob().nullable().unique()(); // 32-byte radio key, once known
  TextColumn get radioKeyPrefix =>
      text().nullable()(); // 12 lowercase hex chars, from CAP before full key
  TextColumn get appIdentityId =>
      text().nullable().unique()(); // Team Link uploaderId (hex)
  TextColumn get radioName =>
      text().nullable()(); // Last radio name seen; exact sender matching
  TextColumn get alias => text().nullable()(); // Team alias from CAP
  IntColumn get aliasUpdatedAt => integer().nullable()();
  IntColumn get capFlags => integer().nullable()(); // Last CAP flag byte
  IntColumn get capObservedAt => integer().nullable()();
  BoolColumn get isTeamMember => boolean()
      .withDefault(const Constant(false))(); // Seen on a private channel
  IntColumn get lastTeamChannelHash => integer().nullable()();
  IntColumn get firstSeen => integer()(); // Unix timestamp ms
  IntColumn get lastSeen => integer()(); // Unix timestamp ms
}

/// Last known location per peer. Kept indefinitely: the last position of a
/// team member is what matters if they go missing.
@DataClassName('PeerLocationData')
class PeerLocations extends Table {
  IntColumn get peerId => integer().references(Peers, #id)();
  IntColumn get lastSeen => integer()(); // Last telemetry received (ms)
  RealColumn get lastLatitude => real().nullable()();
  RealColumn get lastLongitude => real().nullable()();
  IntColumn get lastChannelHash => integer()(); // Channel the TEL arrived on
  IntColumn get lastPathLen => integer()(); // Hop count (for color coding)
  IntColumn get companionBatteryMilliVolts => integer().nullable()();
  IntColumn get phoneBatteryMilliVolts => integer().nullable()();
  BoolColumn get isAutonomousDevice =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isManuallyHidden => boolean()
      .withDefault(const Constant(false))(); // User clicked "Remove from Group"
  IntColumn get hiddenAt => integer().nullable()();
  IntColumn get firstSeen => integer()();
  IntColumn get totalTelemetryReceived =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {peerId};
}

/// Recent position trail per peer. Short-lived: thinned per peer and pruned
/// by age (see RetentionService).
@DataClassName('PeerPositionData')
class PeerPositionHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get peerId => integer().references(Peers, #id)();
  IntColumn get timestamp => integer()(); // Unix timestamp ms
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get channelHash => integer()();
  IntColumn get pathLen => integer()();
}

/// Adverts the radio heard but did not store, so the user can add them by
/// hand. The radio declines an advert when auto-add is off for that node
/// type, when the advert came from further than the auto-add hop limit, or
/// when its contact table is full — in every case it hands the whole contact
/// record to the app instead (PUSH_NEW_ADVERT).
///
/// Team members are added automatically and never land here.
@DataClassName('HeardAdvertData')
class HeardAdverts extends Table {
  BlobColumn get publicKey => blob()(); // 32-byte key (primary key)
  TextColumn get name => text()();
  IntColumn get advertType => integer()(); // ADV_TYPE_*: 1 chat, 2 repeater...
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  IntColumn get lastHeard => integer()(); // Unix timestamp ms
  IntColumn get lastAdvertTimestamp => integer()(); // From the advert itself

  /// When the user dismissed it. A newer advert clears this, so dismissing
  /// silences the entry without hiding the node forever.
  IntColumn get dismissedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {publicKey};
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

/// Imported overlay maps table - stores metadata for user-imported raster
/// overlay maps (Garmin KMZ, MBTiles, and geospatial PDF converted to MBTiles).
///
/// Only metadata lives here; the map data itself stays on disk under
/// {appDocuments}/imported_maps/{id}/. See [OverlayLayerType].
@DataClassName('ImportedOverlayMapData')
class ImportedOverlayMaps extends Table {
  TextColumn get id => text()(); // UUID (primary key)
  TextColumn get name => text()();
  TextColumn get dirPath =>
      text()(); // Path to extracted tile folder in app documents dir
  IntColumn get tileCount => integer()();
  IntColumn get importedAt => integer()(); // Unix timestamp ms
  BoolColumn get isVisible => boolean().withDefault(const Constant(true))();
  RealColumn get boundsNorth => real()();
  RealColumn get boundsSouth => real()();
  RealColumn get boundsEast => real()();
  RealColumn get boundsWest => real()();

  /// Discriminator: 'kmz' | 'mbtiles' | 'geopdf'. Defaults to 'kmz' so rows
  /// written before schema v9 keep their meaning with no data migration.
  TextColumn get layerType => text().withDefault(const Constant('kmz'))();

  /// Native zoom range. Null for KMZ, which has no pyramid semantics.
  IntColumn get minZoom => integer().nullable()();
  IntColumn get maxZoom => integer().nullable()();

  /// Per-layer render opacity, 0.0-1.0.
  RealColumn get opacity => real().withDefault(const Constant(1.0))();

  /// On-disk size, recorded at import. Avoids walking a multi-GB MBTiles
  /// file every time the manage screen rebuilds.
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
