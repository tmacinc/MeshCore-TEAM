import 'package:flutter/foundation.dart';
import 'package:meshcore_team/main.dart' show isBetaBuild;
import 'package:meshcore_team/services/debug_log_service.dart';

void syncTrace(String message) {
  if (message.isEmpty) return;

  if (kDebugMode) debugPrintSynchronously(message);

  if (kDebugMode || isBetaBuild) {
    DebugLogService.instance.add(DebugLogService.categorize(message), message);
  }
}
