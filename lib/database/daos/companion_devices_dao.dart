// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'companion_devices_dao.g.dart';

/// DAO for managing companion device records
/// Tracks BLE devices that have been connected
@DriftAccessor(tables: [CompanionDevices])
class CompanionDevicesDao extends DatabaseAccessor<AppDatabase>
    with _$CompanionDevicesDaoMixin {
  CompanionDevicesDao(super.db);

  /// Get all companion devices
  Future<List<CompanionDeviceData>> getAllCompanionDevices() {
    return (select(companionDevices)
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.lastConnected, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Get a companion device by public key hex
  Future<CompanionDeviceData?> getCompanionDevice(String publicKeyHex) {
    return (select(companionDevices)
          ..where((t) => t.publicKeyHex.equals(publicKeyHex)))
        .getSingleOrNull();
  }

  /// Insert a new companion device
  Future<int> insertCompanionDevice(CompanionDevicesCompanion device) {
    return into(companionDevices).insert(device);
  }

  /// Update a companion device
  Future<int> updateCompanionDevice(CompanionDevicesCompanion device) {
    return (update(companionDevices)
          ..where((t) => t.publicKeyHex.equals(device.publicKeyHex.value)))
        .write(device);
  }

  /// Delete a companion device
  Future<int> deleteCompanionDevice(String publicKeyHex) {
    return (delete(companionDevices)
          ..where((t) => t.publicKeyHex.equals(publicKeyHex)))
        .go();
  }
}
