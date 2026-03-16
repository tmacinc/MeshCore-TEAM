import 'package:flutter/material.dart';

import 'package:meshcore_team/models/waypoint.dart';

class WaypointCreateDialog extends StatefulWidget {
  final double latitude;
  final double longitude;

  const WaypointCreateDialog({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<WaypointCreateDialog> createState() => _WaypointCreateDialogState();
}

class _WaypointCreateDialogState extends State<WaypointCreateDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  WaypointType _selectedType = WaypointType.custom;

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
      title: const Text('Add Waypoint'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Waypoint Name',
                  hintText: 'e.g. Main Camp, Stand Alpha',
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
                  hintText: 'Additional notes…',
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
                    _WaypointCreateResult(
                      name: name,
                      description: _descriptionController.text.trim(),
                      type: _selectedType,
                    ),
                  );
                },
          child: const Text('Add Waypoint'),
        ),
      ],
    );
  }
}

class _WaypointCreateResult {
  final String name;
  final String description;
  final WaypointType type;

  const _WaypointCreateResult({
    required this.name,
    required this.description,
    required this.type,
  });
}

extension WaypointCreateDialogResult on BuildContext {
  Future<({String name, String description, WaypointType type})?>
      showWaypointCreateDialog({
    required double latitude,
    required double longitude,
  }) async {
    final result = await showDialog<_WaypointCreateResult>(
      context: this,
      builder: (context) => WaypointCreateDialog(
        latitude: latitude,
        longitude: longitude,
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
