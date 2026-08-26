// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:meshcore_team/theme/night_theme.dart';

class NightClock extends StatefulWidget {
  const NightClock({super.key});

  @override
  State<NightClock> createState() => _NightClockState();
}

class _NightClockState extends State<NightClock> {
  late DateTime _now;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(bool use24Hour) {
    final h = _now.hour;
    final m = _now.minute.toString().padLeft(2, '0');
    if (use24Hour) {
      return '${h.toString().padLeft(2, '0')}:$m';
    }
    final hour = h % 12 == 0 ? 12 : h % 12;
    final period = h < 12 ? 'AM' : 'PM';
    return '$hour:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final use24Hour = MediaQuery.alwaysUse24HourFormatOf(context);
    return Text(
      _formatTime(use24Hour),
      style: const TextStyle(
        color: NightColors.onSurface,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      ),
    );
  }
}
