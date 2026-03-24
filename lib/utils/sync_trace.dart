import 'package:flutter/foundation.dart';
import 'package:meshcore_team/services/debug_log_service.dart';

void syncTrace(String message) {
  if (message.isEmpty) return;

  debugPrintSynchronously(message);

  if (kDebugMode) {
    DebugLogService.instance.add(DebugLogService.categorize(message), message);
  }
}
