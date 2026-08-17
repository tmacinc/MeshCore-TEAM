// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

/// Remembers the desktop window's size and position across launches.
///
/// Desktop-only, ephemeral UI state that nothing else needs to react to --
/// deliberately kept out of the reactive AppSettings/SettingsService model.
///
/// Note: window_manager's "finished" resize/move events
/// (onWindowResized/onWindowMoved) are macOS/Windows only, not available on
/// Linux. This uses the continuous onWindowResize/onWindowMove events with
/// its own debounce instead, so it works on Linux too.
class WindowStateService with WindowListener {
  static const _keyX = 'window_x';
  static const _keyY = 'window_y';
  static const _keyWidth = 'window_width';
  static const _keyHeight = 'window_height';
  static const _debounce = Duration(milliseconds: 500);

  final SharedPreferences _prefs;
  Timer? _debounceTimer;

  WindowStateService(this._prefs);

  /// Applies the saved window bounds, if any were previously recorded.
  /// A first launch (nothing saved yet) leaves the platform default alone.
  Future<void> restoreWindowState() async {
    final x = _prefs.getDouble(_keyX);
    final y = _prefs.getDouble(_keyY);
    final width = _prefs.getDouble(_keyWidth);
    final height = _prefs.getDouble(_keyHeight);
    if (x == null || y == null || width == null || height == null) return;

    await windowManager.setBounds(Rect.fromLTWH(x, y, width, height));
  }

  @override
  void onWindowResize() => _scheduleSave();

  @override
  void onWindowMove() => _scheduleSave();

  void _scheduleSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, _saveBounds);
  }

  Future<void> _saveBounds() async {
    final bounds = await windowManager.getBounds();
    await _prefs.setDouble(_keyX, bounds.left);
    await _prefs.setDouble(_keyY, bounds.top);
    await _prefs.setDouble(_keyWidth, bounds.width);
    await _prefs.setDouble(_keyHeight, bounds.height);
  }

  void dispose() {
    _debounceTimer?.cancel();
    windowManager.removeListener(this);
  }
}
