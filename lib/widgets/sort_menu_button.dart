// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:material_ui/material_ui.dart';

/// A single choice in a [SortMenuButton]'s dropdown.
class SortMenuOption<T> {
  final T value;
  final IconData icon;
  final String label;

  const SortMenuOption({
    required this.value,
    required this.icon,
    required this.label,
  });
}

/// Standard sort control: an icon button showing the active sort's icon that
/// opens a dropdown menu of sort options, in place of a tap-to-cycle button.
/// Shared by the Contacts and Channels screens.
class SortMenuButton<T> extends StatelessWidget {
  final T value;
  final List<SortMenuOption<T>> options;
  final ValueChanged<T> onChanged;

  const SortMenuButton({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final current = options.firstWhere((o) => o.value == value);
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<T>(
      icon: Icon(current.icon),
      tooltip: current.label,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem<T>(
            value: option.value,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                option.icon,
                color: option.value == value ? colorScheme.primary : null,
              ),
              title: Text(
                option.label,
                style: option.value == value
                    ? TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)
                    : null,
              ),
              trailing: option.value == value
                  ? Icon(Icons.check, color: colorScheme.primary, size: 20)
                  : null,
            ),
          ),
      ],
    );
  }
}
