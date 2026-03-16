// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:convert';

/// Notification payload for deep linking
class NotificationPayload {
  final String type;
  final Map<String, dynamic> data;

  const NotificationPayload({
    required this.type,
    required this.data,
  });

  /// Convert to JSON string for notification payload
  String toJson() {
    return jsonEncode({
      'type': type,
      'data': data,
    });
  }

  /// Parse from JSON string
  static NotificationPayload? fromJson(String? json) {
    if (json == null || json.isEmpty) return null;

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return NotificationPayload(
        type: map['type'] as String,
        data: map['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      return null;
    }
  }

  /// Create payload for direct message notification
  static NotificationPayload directMessage(int contactHash) {
    return NotificationPayload(
      type: 'direct_message',
      data: {'contactHash': contactHash},
    );
  }

  /// Create payload for channel message notification
  static NotificationPayload channelMessage(int channelHash) {
    return NotificationPayload(
      type: 'channel_message',
      data: {'channelHash': channelHash},
    );
  }

  /// Create payload for waypoint notification
  static NotificationPayload waypoint(String waypointId) {
    return NotificationPayload(
      type: 'waypoint',
      data: {'waypointId': waypointId},
    );
  }
}
