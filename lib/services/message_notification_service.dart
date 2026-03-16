// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/utils/notification_payload.dart';

/// Manages message and waypoint notifications
/// Matches Android MessageNotificationManager functionality
class MessageNotificationService {
  final FlutterLocalNotificationsPlugin _notifications;
  final SettingsService _settings;

  // Notification channels
  static const String channelIdMessages = 'mesh_messages';
  static const String channelIdDirectMessages = 'mesh_direct_messages';
  static const String channelIdWaypoints = 'mesh_waypoints';

  // State tracking (matches Android)
  static bool isAppInForeground = false;
  static bool isMessagesScreenVisible = false;
  static int? activeChannelHash;
  static int? activeContactHash;

  int _notificationIdCounter = 2000;

  MessageNotificationService({
    required FlutterLocalNotificationsPlugin notifications,
    required SettingsService settings,
  })  : _notifications = notifications,
        _settings = settings;

  /// Initialize notification channels
  Future<void> initialize() async {
    debugPrint('📬 Initializing message notification service...');

    if (Platform.isAndroid) {
      // Channel for group/channel messages
      final channelMessages = AndroidNotificationChannel(
        channelIdMessages,
        'Channel Messages',
        description: 'Notifications for channel messages on the mesh network',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
      );

      // Channel for direct/private messages
      final channelDirectMessages = AndroidNotificationChannel(
        channelIdDirectMessages,
        'Direct Messages',
        description: 'Notifications for direct messages on the mesh network',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
      );

      // Channel for waypoints
      final channelWaypoints = AndroidNotificationChannel(
        channelIdWaypoints,
        'Waypoint Notifications',
        description: 'Notifications for received waypoints on the mesh network',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
      );

      // Create channels
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(channelMessages);
      await androidPlugin?.createNotificationChannel(channelDirectMessages);
      await androidPlugin?.createNotificationChannel(channelWaypoints);

      debugPrint('📬 Android notification channels created');
    }

    // IMPORTANT:
    // Don't request notification permissions during startup.
    // This ensures first-launch UI (permission explainer) is shown before the OS prompt.
    // Permission requests should happen from explicit user action (e.g., PermissionsScreen).
    if (Platform.isIOS) {
      debugPrint('📬 iOS notification permissions will be requested later');
    }

    debugPrint('✅ Message notification service initialized');
  }

  /// Show notification for a new message
  Future<void> showMessageNotification({
    required MessageData message,
    required String channelName,
    required bool isDirect,
  }) async {
    // Check if notifications are enabled
    if (!_settings.settings.notificationsEnabled) {
      debugPrint('📬 Notifications disabled in settings');
      return;
    }

    // Don't notify for messages sent by me
    if (message.isSentByMe) {
      debugPrint('📬 Skipping notification for own message');
      return;
    }

    // Check if we should suppress this notification
    final shouldSuppress = _shouldSuppressNotification(
      message: message,
      isDirect: isDirect,
    );

    if (shouldSuppress) {
      debugPrint(
          '📬 Suppressing notification (viewing active chat: hash=${message.channelHash})');
      return;
    }

    // Show the notification
    await _showNotificationInternal(
      message: message,
      channelName: channelName,
      isDirect: isDirect,
    );
  }

  /// Check if notification should be suppressed
  bool _shouldSuppressNotification({
    required MessageData message,
    required bool isDirect,
  }) {
    // Only suppress if app is in foreground AND messages screen is visible
    if (!isAppInForeground || !isMessagesScreenVisible) {
      return false;
    }

    if (isDirect) {
      // Suppress if this DM is from the currently active contact
      return message.channelHash == activeContactHash;
    } else {
      // Suppress if this channel message is from the currently active channel
      return message.channelHash == activeChannelHash;
    }
  }

  /// Show notification internal implementation
  Future<void> _showNotificationInternal({
    required MessageData message,
    required String channelName,
    required bool isDirect,
  }) async {
    final notificationId = _notificationIdCounter++;
    final channelId = isDirect ? channelIdDirectMessages : channelIdMessages;

    // Create payload for deep linking
    final payload = isDirect
        ? NotificationPayload.directMessage(message.channelHash)
        : NotificationPayload.channelMessage(message.channelHash);

    // Notification title and body
    final title = isDirect
        ? '${message.senderName ?? 'Unknown'} (Direct Message)'
        : '$channelName: ${message.senderName ?? 'Unknown'}';
    final body = message.content;

    debugPrint(
        '📬 Showing notification: $title (ID: $notificationId, channel: $channelId)');

    // Android notification details
    final androidDetails = AndroidNotificationDetails(
      channelId,
      isDirect ? 'Direct Messages' : 'Channel Messages',
      importance: Importance.high,
      priority: Priority.high,
      playSound: _settings.settings.notificationSoundEnabled,
      enableVibration: _settings.settings.notificationVibrateEnabled,
      ticker: title,
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show notification
    await _notifications.show(
      notificationId,
      title,
      body,
      platformDetails,
      payload: payload.toJson(),
    );
  }

  /// Show notification for a new waypoint
  Future<void> showWaypointNotification({
    required String waypointName,
    required String waypointType,
    required String creatorName,
  }) async {
    // Check if notifications are enabled
    if (!_settings.settings.notificationsEnabled) {
      return;
    }

    final notificationId = _notificationIdCounter++;

    final title = 'New Waypoint: $waypointName';
    final body = '$waypointType from $creatorName';

    debugPrint(
        '📬 Showing waypoint notification: $title (ID: $notificationId)');

    // Android notification details
    const androidDetails = AndroidNotificationDetails(
      channelIdWaypoints,
      'Waypoint Notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: 'New Waypoint',
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show notification
    await _notifications.show(
      notificationId,
      title,
      body,
      platformDetails,
    );
  }

  /// Request notification permissions (iOS and Android 13+)
  Future<bool> requestPermissions() async {
    debugPrint('📬 Requesting notification permissions...');

    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      debugPrint('📬 Android notification permission: $granted');
      return granted ?? false;
    }

    if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('📬 iOS notification permission: $granted');
      return granted ?? false;
    }

    return false;
  }

  /// Check if notification permissions are granted
  Future<bool> arePermissionsGranted() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.areNotificationsEnabled() ?? false;
      return granted;
    }

    // iOS doesn't have a direct check, assume granted if requested
    return true;
  }
}
