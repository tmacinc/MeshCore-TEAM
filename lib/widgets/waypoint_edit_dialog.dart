import 'package:flutter/material.dart';

import 'package:meshcore_team/models/waypoint.dart';

class WaypointEditDialog extends StatefulWidget {
  final String initialName;
  final String initialDescription;
  final WaypointType initialType;

  const WaypointEditDialog({
    super.key,
    required this.initialName,
    required this.initialDescription,
    required this.initialType,
  });

  @override
  State<WaypointEditDialog> createState() => _WaypointEditDialogState();
}

class _WaypointEditDialogState extends State<WaypointEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late WaypointType _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
    _selectedType = widget.initialType;
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

  const _WaypointEditResult({
    required this.name,
    required this.description,
    required this.type,
  });
}

extension WaypointEditDialogResult on BuildContext {
  Future<({String name, String description, WaypointType type})?>
      showWaypointEditDialog({
    required String initialName,
    required String initialDescription,
    required WaypointType initialType,
  }) async {
    final result = await showDialog<_WaypointEditResult>(
      context: this,
      builder: (context) => WaypointEditDialog(
        initialName: initialName,
        initialDescription: initialDescription,
        initialType: initialType,
      ),
    );

    if (result == null) return null;
    return (
      name: result.name,
      description: result.description,
      type: result.type
    );
  }
}
