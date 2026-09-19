// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:intl/intl.dart';

/// Formats a message timestamp for display in chat bubbles.
///
/// - Same calendar day: HH:mm
/// - Within the past 7 days: Weekday HH:mm  (e.g. "Thursday 14:32")
/// - Older: Mon DD HH:mm  (e.g. "Jun 18 14:32")
///
/// Weekday and month names come from [DateFormat] rather than the ARB files:
/// intl already ships them for every locale we translate, and they decline
/// correctly per language. [locale] is a BCP 47 tag, normally
/// `Localizations.localeOf(context).toLanguageTag()`; null uses intl's default.
String formatMessageTime(DateTime timestamp, {String? locale}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final msgDay = DateTime(timestamp.year, timestamp.month, timestamp.day);
  final hhmm =
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

  if (msgDay == today) return hhmm;

  final daysAgo = today.difference(msgDay).inDays;
  if (daysAgo < 7) {
    return '${DateFormat.EEEE(locale).format(timestamp)} $hhmm';
  }

  return '${DateFormat.MMMd(locale).format(timestamp)} $hhmm';
}
