// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:battery_plus/battery_plus.dart';

/// Cross-platform phone battery helper.
///
/// iOS does not expose battery voltage, only battery level (%).
/// To keep TEAM telemetry's "battery mV" field populated on both Android & iOS,
/// we estimate mV from the reported battery percentage.
class PhoneBatteryService {
  static const int _batteryVoltageMinMv = 2750;
  static const int _batteryVoltageMaxMv = 4280;

  final Battery _battery;

  PhoneBatteryService({Battery? battery}) : _battery = battery ?? Battery();

  /// Returns an estimated battery voltage in millivolts based on battery level.
  ///
  /// Notes:
  /// - This is an approximation (linear mapping) meant to keep the field useful
  ///   on iOS where true voltage is not available.
  Future<int?> getEstimatedBatteryMilliVolts() async {
    final level = await _battery.batteryLevel;
    if (level < 0 || level > 100) return null;

    final t = level / 100.0;
    final mv = (_batteryVoltageMinMv +
            ((_batteryVoltageMaxMv - _batteryVoltageMinMv) * t))
        .round();

    return mv.clamp(_batteryVoltageMinMv, _batteryVoltageMaxMv);
  }
}
