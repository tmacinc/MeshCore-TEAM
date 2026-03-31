import 'package:flutter/material.dart';

import 'package:meshcore_team/models/route_payload.dart';
import 'package:meshcore_team/models/waypoint.dart';

class WaypointEditDialog extends StatefulWidget {
  final String initialName;
  final String initialDescription;
  final WaypointType initialType;
  final int? initialColorValue;

  const WaypointEditDialog({
    super.key,
    required this.initialName,
    required this.initialDescription,
    required this.initialType,
    this.initialColorValue,
  });

  @override
  State<WaypointEditDialog> createState() => _WaypointEditDialogState();
}

class _WaypointEditDialogState extends State<WaypointEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late WaypointType _selectedType;
  int? _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
    _selectedType = widget.initialType;
    _selectedColor = widget.initialColorValue ??
        (widget.initialType == WaypointType.route
            ? kRouteColorPresets.first
            : null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameController.text.trim();

    return AlertDialog(
      scrollable: true,
      title: const Text('Edit Waypoint'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Waypoint Name',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<WaypointType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Waypoint Type',
                ),
                items: [
                  for (final type in WaypointType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text('${type.icon} ${type.displayName}'),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedType = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                ),
                maxLines: 3,
              ),
              if (_selectedType == WaypointType.route) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Route Color',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preset in kRouteColorPresets)
                      GestureDetector(
                        onTap: () => setState(() => _selectedColor = preset),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(preset),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == preset
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: _selectedColor == preset
                                ? [
                                    BoxShadow(
                                      color: Color(preset).withValues(alpha: 0.6),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: name.isEmpty
              ? null
              : () {
                  Navigator.of(context).pop(
                    _WaypointEditResult(
                      name: name,
                      description: _descriptionController.text.trim(),
                      type: _selectedType,
                      colorValue: _selectedType == WaypointType.route
                          ? _selectedColor
                          : null,
                    ),
                  );
                },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _WaypointEditResult {
  final String name;
  final String description;
  final WaypointType type;
  final int? colorValue;

  const _WaypointEditResult({
    required this.name,
    required this.description,
    required this.type,
    this.colorValue,
  });
}

extension WaypointEditDialogResult on BuildContext {
  Future<({String name, String description, WaypointType type, int? colorValue})?>
      showWaypointEditDialog({
    required String initialName,
    required String initialDescription,
    required WaypointType initialType,
    int? initialColorValue,
  }) async {
    final result = await showDialog<_WaypointEditResult>(
      context: this,
      builder: (context) => WaypointEditDialog(
        initialName: initialName,
        initialDescription: initialDescription,
        initialType: initialType,
        initialColorValue: initialColorValue,
      ),
    );

    if (result == null) return null;
    return (
      name: result.name,
      description: result.description,
      type: result.type,
      colorValue: result.colorValue,
    );
  }
}
