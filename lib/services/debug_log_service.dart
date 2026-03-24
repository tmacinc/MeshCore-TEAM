// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

enum LogCategory {
  sync,
  ble,
  telemetry,
  forwarding,
  error,
  general,
}

class LogEntry {
  final DateTime timestamp;
  final LogCategory category;
  final String message;

  const LogEntry({
    required this.timestamp,
    required this.category,
    required this.message,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  String toExportLine() =>
      '${timestamp.toIso8601String()} [${category.name.toUpperCase()}] $message';
}

class DebugLogService extends ChangeNotifier {
  static const int _maxEntries = 2000;
  static const Duration _notifyBatchWindow = Duration(milliseconds: 50);

  static DebugLogService? _instance;
  static DebugLogService get instance => _instance ??= DebugLogService._();

  DebugLogService._();

  final Queue<LogEntry> _entries = Queue<LogEntry>();
  Timer? _notifyTimer;

  List<LogEntry> get entries => _entries.toList(growable: false);

  int get length => _entries.length;

  void add(LogCategory category, String message) {
    _entries.addLast(LogEntry(
      timestamp: DateTime.now(),
      category: category,
      message: message,
    ));
    if (_entries.length > _maxEntries) {
      _entries.removeFirst();
    }
    _scheduleNotify();
  }

  void clear() {
    _notifyTimer?.cancel();
    _notifyTimer = null;
    _entries.clear();
    notifyListeners();
  }

  void _scheduleNotify() {
    if (_notifyTimer != null) return;
    _notifyTimer = Timer(_notifyBatchWindow, () {
      _notifyTimer = null;
      notifyListeners();
    });
  }

  List<LogEntry> filtered(Set<LogCategory> categories) {
    if (categories.length == LogCategory.values.length) return entries;
    return _entries
        .where((e) => categories.contains(e.category))
        .toList(growable: false);
  }

  String exportAsText({Set<LogCategory>? categories}) {
    final list = categories != null ? filtered(categories) : entries;
    return list.map((e) => e.toExportLine()).join('\n');
  }

  static LogCategory categorize(String message) {
    if (message.contains('❌') ||
        message.contains('⚠️') ||
        message.contains('ERROR')) {
      return LogCategory.error;
    }
    if (message.startsWith('[ForwardingPolicy]') ||
        message.startsWith('[ForwardingV1]')) {
      return LogCategory.forwarding;
    }
    if (message.startsWith('[ConnectionVM] 📡') ||
        message.startsWith('[ConnectionVM] 📍') ||
        message.startsWith('[Telemetry') ||
        message.startsWith('[CapPublisher]') ||
        message.contains('Telemetry')) {
      return LogCategory.telemetry;
    }
    if (message.startsWith('[BleManager]') ||
        message.startsWith('[BLE') ||
        message.startsWith('[Reconnect]') ||
        message.startsWith('[Parser]')) {
      return LogCategory.ble;
    }
    if (message.contains('Phase') ||
        message.contains('sync') ||
        message.contains('Sync') ||
        message.startsWith('[ConnectionVM] 🔄') ||
        message.startsWith('[ConnectionVM] ↩️') ||
        message.startsWith('[ConnectionVM] 📋') ||
        message.startsWith('[ConnectionVM] 📺') ||
        message.startsWith('[ConnectionVM] 📨') ||
        message.startsWith('[ConnectionVM] 🚀')) {
      return LogCategory.sync;
    }
    return LogCategory.general;
  }
}

/// Installs a debug-mode interceptor that captures all debugPrint output into
/// [DebugLogService]. Call once at startup (before runApp).
void installDebugLogInterceptor() {
  if (!kDebugMode) return;

  final original = debugPrint;
  final logService = DebugLogService.instance;

  debugPrint = (String? message, {int? wrapWidth}) {
    if (message == null || message.isEmpty) return;
    original(message, wrapWidth: wrapWidth);
    logService.add(DebugLogService.categorize(message), message);
  };
}
