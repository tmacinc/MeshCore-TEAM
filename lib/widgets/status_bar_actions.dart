// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:material_ui/material_ui.dart';
import 'app_menu_button.dart';
import 'bt_status_icon.dart';
import 'network_status_icons.dart';

/// Shared AppBar actions: location sharing, routing, BLE status, hamburger menu.
/// Use as a single entry in AppBar.actions — it expands into the four widgets.
class StatusBarActions extends StatelessWidget {
  const StatusBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NetworkStatusIcons(),
        BtStatusIcon(),
        AppMenuButton(),
      ],
    );
  }
}
