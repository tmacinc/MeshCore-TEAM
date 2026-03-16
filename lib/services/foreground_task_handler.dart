// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Foreground task handler for flutter_foreground_task
/// Handles periodic callbacks while service is running
@pragma('vm:entry-point')
void foregroundTaskEntryPoint() {
  FlutterForegroundTask.setTaskHandler(MeshForegroundTaskHandler());
}

/// Task handler that runs in the foreground service
class MeshForegroundTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  int _updateCount = 0;

  @override
  void onStart(DateTime timestamp, SendPort? sendPort) {
    _sendPort = sendPort;
    print('[ForegroundTask] Task started at $timestamp');
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {
    _updateCount++;

    // Send update to main isolate
    _sendPort?.send({
      'type': 'update',
      'timestamp': timestamp.toIso8601String(),
      'count': _updateCount,
    });

    // Log periodically (every minute)
    if (_updateCount % 12 == 0) {
      // 12 * 5s = 60s
      print('[ForegroundTask] Still alive - update #$_updateCount');
    }
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) {
    print('[ForegroundTask] Task destroyed at $timestamp');
  }

  @override
  void onNotificationButtonPressed(String id) {
    print('[ForegroundTask] Notification button pressed: $id');

    // Handle disconnect button
    if (id == 'disconnect') {
      _sendPort?.send({
        'type': 'disconnect_requested',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  void onNotificationPressed() {
    print('[ForegroundTask] Notification pressed - opening app');
    FlutterForegroundTask.launchApp('/');
  }
}

