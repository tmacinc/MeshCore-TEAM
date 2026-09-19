// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:meshcore_team/database/database.dart';

/// How long a team member stays on the map after their last telemetry.
/// Their last known location is kept beyond this; it just isn't drawn.
const Duration teamMapVisibilityWindow = Duration(hours: 12);

/// Whether a peer's last known location belongs on the team map for the
/// tracking channel [trackingChannelHash].
bool isVisibleOnTeamMap(
  PeerLocationData location, {
  required int trackingChannelHash,
  required int nowMs,
}) {
  if (location.isManuallyHidden) return false;
  if (location.totalTelemetryReceived <= 0) return false;
  if (location.lastChannelHash != trackingChannelHash) return false;
  if (location.lastLatitude == null || location.lastLongitude == null) {
    return false;
  }
  return nowMs - location.lastSeen <= teamMapVisibilityWindow.inMilliseconds;
}

/// Parses the tracking channel hash stored in settings (hex string).
int? parseTrackingChannelHash(String? hex) {
  if (hex == null) return null;
  final cleaned = hex.trim().toLowerCase().replaceFirst('0x', '');
  if (cleaned.isEmpty || !RegExp(r'^[0-9a-f]+$').hasMatch(cleaned)) {
    return null;
  }
  return int.tryParse(cleaned, radix: 16);
}
