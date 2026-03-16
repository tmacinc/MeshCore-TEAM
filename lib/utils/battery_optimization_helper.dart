// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';

/// Helper for managing battery optimization exemption on Android
/// Critical for reliable background operation during Doze mode
class BatteryOptimizationHelper {
  /// Check if battery optimization is disabled for this app
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;

    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      final isGranted = status.isGranted;
      debugPrint('⚡ Battery optimization exemption: $isGranted');
      return isGranted;
    } catch (e) {
      debugPrint('⚡ Error checking battery optimization: $e');
      return false;
    }
  }

  /// Request battery optimization exemption
  /// Opens Android settings for user to grant exemption
  static Future<bool> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return true;

    try {
      debugPrint('⚡ Requesting battery optimization exemption...');

      // Launch Android settings
      final intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        data: 'package:com.meshcore.team',
      );

      await intent.launch();
      debugPrint('⚡ Battery optimization settings opened');

      // Wait a bit for user to grant permission
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if granted
      return await isIgnoringBatteryOptimizations();
    } catch (e) {
      debugPrint('⚡ Error requesting battery optimization exemption: $e');
      return false;
    }
  }

  /// Check if the device supports battery optimization exemption request
  static Future<bool> canRequestBatteryOptimization() async {
    if (!Platform.isAndroid) return false;

    try {
      // Available on Android API 23+ (Android 6.0+)
      return true;
    } catch (e) {
      return false;
    }
  }
}
