// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:material_ui/material_ui.dart';

/// Color constants for nighttime mode.
/// All values are dim reds that preserve dark-adapted vision.
class NightColors {
  NightColors._();

  static const Color background   = Color(0xFF080000);
  static const Color surface      = Color(0xFF120000);
  static const Color surfaceLow   = Color(0xFF0D0000);
  static const Color surfaceHigh  = Color(0xFF1C0000);
  static const Color appBarBg     = Color(0xFF0D0000);

  static const Color primary      = Color(0xFF8B0000);
  static const Color onPrimary    = Color(0xFFAA3030);

  /// Main text / icon color.
  static const Color onSurface    = Color(0xFFAA3030);
  /// Secondary / subtitle text color.
  static const Color onSurfaceVariant = Color(0xFF7A2525);
  /// Very dim — for inactive / placeholder elements.
  static const Color dim          = Color(0xFF552020);
  static const Color dimmer       = Color(0xFF3D1515);
  static const Color dimmest      = Color(0xFF2A1010);

  // Connectivity indicator shades (CircleAvatar backgrounds)
  static const Color connectJustSeen    = Color(0xFF4A2020);
  static const Color connectRecent      = Color(0xFF3D1515);
  static const Color connectStale       = Color(0xFF2A1010);
  static const Color connectOffline     = Color(0xFF1A0808);
  static const Color connectOutOfRange  = Color(0xFF150505);

  // BLE / connection status indicator colors (top bar, bottom bar)
  static const Color statusConnected    = Color(0xFF6B3030);
  static const Color statusConnecting   = Color(0xFF7A3020);
  static const Color statusScanning     = Color(0xFF6B2020);
  static const Color statusDisconnected = Color(0xFF4A1515);
}

/// ColorFilter that converts map tiles to a dim red-grayscale for nighttime mode.
/// Converts each pixel to luminance (standard Rec. 601 weights * 0.4 brightness)
/// and maps it exclusively to the red channel, zeroing green and blue.
const ColorFilter kNightMapTileFilter = ColorFilter.matrix(<double>[
  0.12, 0.235, 0.046, 0, 0,
  0,    0,     0,     0, 0,
  0,    0,     0,     0, 0,
  0,    0,     0,     1, 0,
]);
