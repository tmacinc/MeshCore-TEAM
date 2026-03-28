// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:compassx/compassx.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/models/map_tile_providers.dart';
import 'package:meshcore_team/models/route_payload.dart';
import 'package:meshcore_team/models/waypoint.dart' as waypoint_model;
import 'package:meshcore_team/repositories/message_repository.dart';
import 'package:meshcore_team/screens/direct_message_screen.dart';
import 'package:meshcore_team/screens/manage_waypoints_screen.dart';
import 'package:meshcore_team/screens/offline_maps_screen.dart';
import 'package:meshcore_team/services/forwarding_policy_service.dart';
import 'package:meshcore_team/services/map_tile_cache_service.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';
import 'package:meshcore_team/widgets/offline_map_download_dialog.dart';
import 'package:meshcore_team/widgets/waypoint_create_dialog.dart';
import 'package:meshcore_team/widgets/waypoint_edit_dialog.dart';

/// Map Screen
/// Displays map with user location
/// Future: Will show contact locations based on team logic
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  bool _isLoadingLocation = false;
  String? _locationError;

  double? _headingDegrees;
  double? _courseDegrees;
  bool _isMovingForTrackUp = false;
  LatLng? _lastCourseLocation;
  DateTime? _lastCourseTime;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<CompassXEvent>? _compassSub;
  Timer? _companionTelemetryTimer;
  Timer? _contactMarkerRefreshTimer;
  Timer? _phoneLocationPollingTimer;
  bool? _lastShouldUseCompanion;

  bool _isFollowingUser = false;
  bool _isHeadingUp = false;
  bool _isPickingWaypoint = false;

  bool _isRouteEditMode = false;
  String? _editingRouteId;
  String _routeDraftName = '';
  String _routeDraftDescription = '';
  List<LatLng> _routeDraftPoints = <LatLng>[];

  bool _isWaypointMultiSelectMode = false;
  Set<String> _selectedWaypointIds = <String>{};

  int? _draggingPointIndex;

  bool _isGroupStatusOpen = false;

  LatLng? _navTarget;
  String _navTargetName = '';

  void _showComingSoon(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$featureName coming soon')),
    );
  }

  String _formatRelativeTime(int timestampMs) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diffMs = now - timestampMs;
    if (diffMs < 0) return 'now';

    final seconds = (diffMs / 1000).floor();
    if (seconds < 60) return '${seconds}s ago';
    final minutes = (seconds / 60).floor();
    if (minutes < 60) return '${minutes}m ago';
    final hours = (minutes / 60).floor();
    if (hours < 24) return '${hours}h ago';
    final days = (hours / 24).floor();
    return '${days}d ago';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  void _startNavigation(LatLng target, String name) {
    setState(() {
      _navTarget = target;
      _navTargetName = name;
      _isGroupStatusOpen = false;
      // Force heading-up (track-up) mode during navigation.
      _isHeadingUp = true;
      _isFollowingUser = true;
    });
    context.read<SettingsService>().setMapTrackUpMode(true);
    final loc = _userLocation;
    if (loc != null) {
      _mapController.move(loc, _mapController.camera.zoom);
    }
    _applyMapRotationForTrackUp();
  }

  void _stopNavigation() {
    setState(() {
      _navTarget = null;
      _navTargetName = '';
    });
  }

  Uint8List _hexToBytes(String hex) {
    final cleaned = hex.trim();
    if (cleaned.length % 2 != 0) {
      throw ArgumentError('Hex string length must be even');
    }
    final bytes = <int>[];
    for (int i = 0; i < cleaned.length; i += 2) {
      bytes.add(int.parse(cleaned.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  void _showContactQuickInfo(ContactDisplayStateData state) {
    final name = (state.name == null || state.name!.trim().isEmpty)
        ? 'Unknown'
        : state.name!.trim();
    final idShort = state.publicKeyHex.length >= 8
        ? state.publicKeyHex.substring(0, 8).toUpperCase()
        : state.publicKeyHex.toUpperCase();

    final hopCount = state.lastPathLen;
    final lastHeard = _formatRelativeTime(state.lastSeen);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name ($idShort) • hops:$hopCount • heard:$lastHeard'),
      ),
    );
  }

  Future<void> _showContactDetailsDialog(
    AppDatabase db,
    ContactDisplayStateData state,
  ) async {
    final name = (state.name == null || state.name!.trim().isEmpty)
        ? 'Unknown'
        : state.name!.trim();

    final Future<ContactData?> contactFuture = () async {
      try {
        final pkBytes = _hexToBytes(state.publicKeyHex);
        return db.contactsDao.getContactByPublicKey(pkBytes);
      } catch (_) {
        return null;
      }
    }();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(name),
          content: FutureBuilder<ContactData?>(
            future: contactFuture,
            builder: (context, snapshot) {
              final contact = snapshot.data;
              final lastHeard = _formatRelativeTime(state.lastSeen);

              final lat = state.lastLatitude;
              final lon = state.lastLongitude;

              final companionBattMv = contact?.companionBatteryMilliVolts;
              final isAutonomous = contact?.isAutonomousDevice ?? false;
              final phoneBattMv =
                  isAutonomous ? null : contact?.phoneBatteryMilliVolts;

              String formatBatteryMv(int? mv) {
                return mv != null ? '${mv}mV' : 'Unknown';
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hop count: ${state.lastPathLen}'),
                  const SizedBox(height: 6),
                  Text('Last heard: $lastHeard'),
                  const SizedBox(height: 10),
                  Text('Lat: ${lat?.toStringAsFixed(6) ?? 'Unknown'}'),
                  const SizedBox(height: 6),
                  Text('Lon: ${lon?.toStringAsFixed(6) ?? 'Unknown'}'),
                  const SizedBox(height: 10),
                  const Text('Battery'),
                  const SizedBox(height: 6),
                  Text('Companion: ${formatBatteryMv(companionBattMv)}'),
                  const SizedBox(height: 6),
                  if (isAutonomous)
                    const Text('Phone: Autonomous (no phone)')
                  else
                    Text('Phone: ${formatBatteryMv(phoneBattMv)}'),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (state.lastLatitude != null && state.lastLongitude != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _startNavigation(
                    LatLng(state.lastLatitude!, state.lastLongitude!),
                    name,
                  );
                },
                child: const Text('Navigate'),
              ),
            TextButton(
              onPressed: () async {
                final nowMs = DateTime.now().millisecondsSinceEpoch;
                await (db.update(db.contactDisplayStates)
                      ..where((t) =>
                          t.publicKeyHex.equals(state.publicKeyHex) &
                          t.companionDeviceKey
                              .equals(state.companionDeviceKey)))
                    .write(
                  ContactDisplayStatesCompanion(
                    isManuallyHidden: const Value(true),
                    hiddenAt: Value(nowMs),
                  ),
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Remove from group'),
            ),
            FilledButton(
              onPressed: () async {
                final contact = await contactFuture;
                if (contact == null) return;

                if (!context.mounted) return;
                Navigator.of(context).pop();
                Navigator.push(
                  this.context,
                  MaterialPageRoute(
                    builder: (context) => DirectMessageScreen(contact: contact),
                  ),
                );
              },
              child: const Text('Direct message'),
            ),
          ],
        );
      },
    );
  }

  void _showGroupMemberActions(AppDatabase db, ContactDisplayStateData state) {
    final name = (state.name == null || state.name!.trim().isEmpty)
        ? state.publicKeyHex.substring(0, 8).toUpperCase()
        : state.name!.trim();

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Text(
                  name,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.message_outlined),
                title: const Text('Direct message'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  try {
                    final pkBytes = _hexToBytes(state.publicKeyHex);
                    final contact =
                        await db.contactsDao.getContactByPublicKey(pkBytes);
                    if (contact == null || !mounted) return;
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(
                        builder: (_) => DirectMessageScreen(contact: contact),
                      ),
                    );
                  } catch (_) {}
                },
              ),
              ListTile(
                leading: const Icon(Icons.center_focus_strong_outlined),
                title: const Text('Center on map'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() => _isGroupStatusOpen = false);
                  _mapController.move(
                    LatLng(state.lastLatitude!, state.lastLongitude!),
                    _mapController.camera.zoom,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.navigation_outlined),
                title: const Text('Navigate to'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _startNavigation(
                    LatLng(state.lastLatitude!, state.lastLongitude!),
                    name,
                  );
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.person_remove_outlined, color: Colors.red[700]),
                title: Text('Remove from group',
                    style: TextStyle(color: Colors.red[700])),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final nowMs = DateTime.now().millisecondsSinceEpoch;
                  await (db.update(db.contactDisplayStates)
                        ..where((t) =>
                            t.publicKeyHex.equals(state.publicKeyHex) &
                            t.companionDeviceKey
                                .equals(state.companionDeviceKey)))
                      .write(
                    ContactDisplayStatesCompanion(
                      isManuallyHidden: const Value(true),
                      hiddenAt: Value(nowMs),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _startWaypointPickMode() {
    setState(() {
      _isRouteEditMode = false;
      _editingRouteId = null;
      _routeDraftName = '';
      _routeDraftDescription = '';
      _routeDraftPoints = <LatLng>[];
      _isPickingWaypoint = true;
      _isFollowingUser = false;
    });
  }

  void _cancelWaypointPickMode() {
    setState(() {
      _isPickingWaypoint = false;
    });
  }

  void _showAddWaypointOrRouteMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_location_alt),
              title: const Text('Create Waypoint'),
              onTap: () {
                Navigator.of(context).pop();
                _startWaypointPickMode();
              },
            ),
            ListTile(
              leading: const Icon(Icons.route),
              title: const Text('Create Route'),
              onTap: () {
                Navigator.of(context).pop();
                _startRouteCreateMode();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startRouteCreateMode() {
    setState(() {
      _isPickingWaypoint = false;
      _isRouteEditMode = true;
      _editingRouteId = null;
      _routeDraftName = '';
      _routeDraftDescription = '';
      _routeDraftPoints = <LatLng>[];
      _isFollowingUser = false;
    });
  }

  void _startRouteEditMode(WaypointData routeWaypoint) {
    final payload = decodeRoutePayload(
      routeWaypoint.description,
      fallbackLatitude: routeWaypoint.latitude,
      fallbackLongitude: routeWaypoint.longitude,
    );

    setState(() {
      _isPickingWaypoint = false;
      _isRouteEditMode = true;
      _editingRouteId = routeWaypoint.id;
      _routeDraftName = routeWaypoint.name;
      _routeDraftDescription = payload.description;
      _routeDraftPoints = List<LatLng>.of(payload.points);
      _isFollowingUser = false;
    });
  }

  void _cancelRouteEditMode() {
    setState(() {
      _isRouteEditMode = false;
      _editingRouteId = null;
      _routeDraftName = '';
      _routeDraftDescription = '';
      _routeDraftPoints = <LatLng>[];
      _draggingPointIndex = null;
    });
  }

  void _undoRoutePoint() {
    if (_routeDraftPoints.isEmpty) return;
    setState(() {
      _routeDraftPoints = List<LatLng>.of(_routeDraftPoints)..removeLast();
      // Clear selection if the removed point was selected or index is now out of range.
      if (_draggingPointIndex != null &&
          _draggingPointIndex! >= _routeDraftPoints.length) {
        _draggingPointIndex = null;
      }
    });
  }

  Future<({String name, String description})?> _showRouteMetaDialog({
    required String initialName,
    required String initialDescription,
    required bool isEdit,
  }) async {
    final nameCtrl = TextEditingController(text: initialName);
    final descCtrl = TextEditingController(text: initialDescription);

    final result = await showDialog<({String name, String description})>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            final canSave = nameCtrl.text.trim().isNotEmpty;
            return AlertDialog(
              title: Text(isEdit ? 'Edit Route' : 'Save Route'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Route Name'),
                      onChanged: (_) => setInnerState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: canSave
                      ? () {
                          Navigator.of(context).pop((
                            name: nameCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                          ));
                        }
                      : null,
                  child: Text(isEdit ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    descCtrl.dispose();
    return result;
  }

  Future<void> _saveRouteDraft() async {
    if (_routeDraftPoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 points for a route')),
      );
      return;
    }

    // Capture providers before the async dialog to avoid
    // BuildContext use after an async gap (dependents.isEmpty).
    final db = context.read<AppDatabase>();
    final connectionVM = context.read<ConnectionViewModel>();

    final meta = await _showRouteMetaDialog(
      initialName: _routeDraftName,
      initialDescription: _routeDraftDescription,
      isEdit: _editingRouteId != null,
    );
    if (meta == null) return;
    final creatorNodeId = connectionVM.deviceName.trim().isNotEmpty
        ? connectionVM.deviceName.trim()
        : 'local';

    final anchor = _routeDraftPoints.first;
    final encodedDescription = encodeRoutePayload(
      description: meta.description,
      points: _routeDraftPoints,
    );

    if (_editingRouteId != null) {
      await db.waypointsDao.updateWaypoint(
        _editingRouteId!,
        WaypointsCompanion(
          name: Value(meta.name),
          description: Value(encodedDescription),
          latitude: Value(anchor.latitude),
          longitude: Value(anchor.longitude),
          waypointType:
              Value(waypoint_model.WaypointType.route.name.toUpperCase()),
        ),
      );
    } else {
      await db.waypointsDao.insertWaypoint(
        waypoint_model.Waypoint(
          id: const Uuid().v4(),
          meshId: null,
          name: meta.name,
          description: encodedDescription,
          latitude: anchor.latitude,
          longitude: anchor.longitude,
          waypointType: waypoint_model.WaypointType.route,
          creatorNodeId: creatorNodeId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          isReceived: false,
          isVisible: true,
          isNew: false,
        ).toCompanion(),
      );
    }

    _cancelRouteEditMode();
  }

  Future<void> _confirmWaypointPickMode() async {
    final center = _mapController.camera.center;

    setState(() {
      _isPickingWaypoint = false;
    });

    final createResult = await context.showWaypointCreateDialog(
      latitude: center.latitude,
      longitude: center.longitude,
    );

    if (createResult == null) return;

    final connectionVM = context.read<ConnectionViewModel>();
    final db = context.read<AppDatabase>();

    // Match TEAM behavior: creator is tracked by the node/device name that the
    // firmware prepends to sent channel messages.
    final creatorNodeId = connectionVM.deviceName.trim().isNotEmpty
        ? connectionVM.deviceName.trim()
        : 'local';

    final wp = waypoint_model.Waypoint(
      id: const Uuid().v4(),
      meshId: null,
      name: createResult.name,
      description: createResult.description,
      latitude: center.latitude,
      longitude: center.longitude,
      waypointType: createResult.type,
      creatorNodeId: creatorNodeId,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      isReceived: false,
      isVisible: true,
      isNew: false,
    );

    try {
      // Local de-dupe: avoid creating duplicates by name or location.
      const duplicateLocationMeters = 20.0;
      final incomingName = wp.name.trim().toLowerCase();
      final allWaypoints = await db.waypointsDao.getAllWaypoints();
      for (final w in allWaypoints) {
        final nameMatch = incomingName.isNotEmpty &&
            w.name.trim().toLowerCase() == incomingName;
        final dist = Geolocator.distanceBetween(
          w.latitude,
          w.longitude,
          wp.latitude,
          wp.longitude,
        );

        if (nameMatch || dist <= duplicateLocationMeters) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Waypoint already exists')),
          );
          return;
        }
      }

      await db.waypointsDao.insertWaypoint(wp.toCompanion());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add waypoint: $e')),
      );
    }
  }

  Future<void> _showWaypointActions(WaypointData waypoint) async {
    final db = context.read<AppDatabase>();

    if (waypoint.isNew) {
      await db.waypointsDao.markAsViewed(waypoint.id);
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final type =
            waypoint_model.WaypointType.fromString(waypoint.waypointType);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${type.icon} ${waypoint.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (type == waypoint_model.WaypointType.route) ...[
                  const SizedBox(height: 4),
                  Text(
                    decodeRoutePayload(
                      waypoint.description,
                      fallbackLatitude: waypoint.latitude,
                      fallbackLongitude: waypoint.longitude,
                    ).description,
                  ),
                ] else if (waypoint.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(waypoint.description),
                ],
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.navigation),
                          title: const Text('Navigate to'),
                          onTap: () {
                            Navigator.of(context).pop();
                            _startNavigation(
                              LatLng(waypoint.latitude, waypoint.longitude),
                              waypoint.name,
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.share),
                          title: const Text('Share via Mesh'),
                          onTap: () async {
                            Navigator.of(context).pop();

                            final repo = this.context.read<MessageRepository>();
                            final ok = await repo.sendWaypointToMesh(waypoint);
                            if (!mounted) return;

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Waypoint shared to mesh'
                                      : 'Failed to share waypoint',
                                ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.check_circle),
                          title: const Text('Select Multiple'),
                          onTap: () {
                            Navigator.of(context).pop();
                            setState(() {
                              _isWaypointMultiSelectMode = true;
                              _selectedWaypointIds = <String>{waypoint.id};
                            });
                          },
                        ),
                        if (!waypoint.isReceived)
                          ListTile(
                            leading: const Icon(Icons.edit),
                            title: Text(
                              type == waypoint_model.WaypointType.route
                                  ? 'Edit Route Points'
                                  : 'Edit',
                            ),
                            onTap: () async {
                              Navigator.of(context).pop();
                              if (type == waypoint_model.WaypointType.route) {
                                _startRouteEditMode(waypoint);
                                return;
                              }
                              final editResult =
                                  await this.context.showWaypointEditDialog(
                                        initialName: waypoint.name,
                                        initialDescription: waypoint.description,
                                        initialType: type,
                                      );
                              if (editResult == null) return;
                              await db.waypointsDao.updateWaypoint(
                                waypoint.id,
                                WaypointsCompanion(
                                  name: Value(editResult.name),
                                  description: Value(editResult.description),
                                  waypointType:
                                      Value(editResult.type.name.toUpperCase()),
                                ),
                              );
                            },
                          ),
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text('Delete'),
                          onTap: () async {
                            Navigator.of(context).pop();
                            final ok = await _confirm(
                              'Delete waypoint?',
                              'This will delete "${waypoint.name}".',
                            );
                            if (!ok) return;
                            await db.waypointsDao.deleteWaypoint(waypoint.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleWaypointSelected(WaypointData waypoint) async {
    final db = context.read<AppDatabase>();
    if (waypoint.isNew) {
      await db.waypointsDao.markAsViewed(waypoint.id);
    }

    setState(() {
      if (_selectedWaypointIds.contains(waypoint.id)) {
        _selectedWaypointIds.remove(waypoint.id);
      } else {
        _selectedWaypointIds.add(waypoint.id);
      }
    });
  }

  void _exitWaypointMultiSelectMode() {
    setState(() {
      _isWaypointMultiSelectMode = false;
      _selectedWaypointIds = <String>{};
    });
  }

  Future<void> _deleteSelectedWaypoints() async {
    if (_selectedWaypointIds.isEmpty) return;

    final ok = await _confirm(
      'Delete waypoints?',
      'This will delete ${_selectedWaypointIds.length} waypoint(s).',
    );
    if (!ok) return;

    final db = context.read<AppDatabase>();
    final ids = _selectedWaypointIds.toList(growable: false);
    for (final id in ids) {
      await db.waypointsDao.deleteWaypoint(id);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted ${ids.length} waypoint(s)')),
    );

    _exitWaypointMultiSelectMode();
  }

  Future<void> _shareSelectedWaypoints() async {
    if (_selectedWaypointIds.isEmpty) return;

    final db = context.read<AppDatabase>();
    final repo = context.read<MessageRepository>();

    final all = await db.waypointsDao.getAllWaypoints();

    final selected = all
        .where((w) => _selectedWaypointIds.contains(w.id))
        .toList(growable: false);

    final result = await repo.sendWaypointsToMesh(selected);
    final okCount = result.okCount;
    final failCount = result.failCount;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failCount == 0
              ? 'Shared $okCount waypoint(s)'
              : 'Shared $okCount, failed $failCount',
        ),
      ),
    );

    _exitWaypointMultiSelectMode();
  }

  Future<void> _openDownloadMapAreaDialog({
    required MapTileProviderOption provider,
  }) async {
    final bounds = _mapController.camera.visibleBounds;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return OfflineMapDownloadDialog(
          bounds: bounds,
          providerId: provider.id,
          providerLabel: provider.label,
          urlTemplate: provider.urlTemplate,
          subdomains: provider.subdomains,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _startCompassTracking();

    // Ensure contact marker colors update as contacts go stale (5 min) even if
    // no new packets arrive.
    _contactMarkerRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {});
    });

    // Apply location/track-up policy after first build when providers exist.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settingsService = context.read<SettingsService>();
      final connectionVM = context.read<ConnectionViewModel>();
      _applyLocationPolicy(settingsService, connectionVM);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _positionSub = null;
    _compassSub?.cancel();
    _compassSub = null;
    _companionTelemetryTimer?.cancel();
    _companionTelemetryTimer = null;
    _contactMarkerRefreshTimer?.cancel();
    _contactMarkerRefreshTimer = null;
    _phoneLocationPollingTimer?.cancel();
    _phoneLocationPollingTimer = null;
    super.dispose();
  }

  void _startPhoneLocationTracking() {
    _positionSub?.cancel();
    _phoneLocationPollingTimer?.cancel();

    // Seed with one current position ASAP.
    _getCurrentLocation();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((position) {
      _handleNewLocation(
        LatLng(position.latitude, position.longitude),
        timestamp: DateTime.now(),
        speedMps: position.speed.isFinite ? position.speed : null,
        headingDegrees: (position.heading.isFinite && position.heading >= 0)
            ? position.heading
            : null,
      );
    }, onError: (Object error) {
      setState(() {
        _locationError = 'Location stream error: $error';
      });
    });

    // Periodic polling as a safety net: guarantees at least one update every
    // 2 seconds even when the OS throttles the position stream (e.g. Android
    // Fused Location Provider batching with the native telemetry service).
    _phoneLocationPollingTimer =
        Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 3),
        );
        if (!mounted) return;
        _handleNewLocation(
          LatLng(position.latitude, position.longitude),
          timestamp: DateTime.now(),
          speedMps: position.speed.isFinite ? position.speed : null,
          headingDegrees: (position.heading.isFinite && position.heading >= 0)
              ? position.heading
              : null,
        );
      } catch (_) {
        // Polling is best-effort; stream is primary.
      }
    });
  }

  void _stopPhoneLocationTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    _phoneLocationPollingTimer?.cancel();
    _phoneLocationPollingTimer = null;
  }

  void _startCompassTracking() {
    _compassSub?.cancel();
    _compassSub = CompassX.events.listen((event) {
      if (!mounted) return;
      final heading = event.heading;
      if (heading.isFinite) {
        // Accept the very first heading unconditionally; after that, only
        // update when the change exceeds 2° to avoid excessive rebuilds.
        final isFirst = _headingDegrees == null;
        final delta = isFirst ? 0.0 : (heading - _headingDegrees!).abs();
        final wrappedDelta = delta > 180 ? 360 - delta : delta;
        if (isFirst || wrappedDelta >= 2.0) {
          setState(() {
            _headingDegrees = heading;
          });
          // When stationary, apply compass heading for track-up rotation.
          if (_isHeadingUp && !_isMovingForTrackUp) {
            _applyMapRotationForTrackUp();
          }
        }
      }
    }, onError: (Object error) {
      debugPrint('[MapScreen] Compass error: $error');
    });
  }

  void _applyLocationPolicy(
    SettingsService settingsService,
    ConnectionViewModel connectionVM,
  ) {
    final wantsCompanion =
        settingsService.settings.locationSource == LocationSource.companion;

    final companionFixTime = connectionVM.companionGpsFixTime;
    final hasRecentCompanionFix = connectionVM.hasCompanionGpsFix &&
        companionFixTime != null &&
        DateTime.now().difference(companionFixTime) <
            const Duration(seconds: 10);

    final shouldPollCompanionTelemetry =
        wantsCompanion && connectionVM.isConnected;
    if (shouldPollCompanionTelemetry && _companionTelemetryTimer == null) {
      _companionTelemetryTimer =
          Timer.periodic(const Duration(seconds: 2), (_) async {
        if (!mounted) return;
        final vm = context.read<ConnectionViewModel>();
        // Only send the request. Policy is re-evaluated reactively via
        // ConnectionViewModel.notifyListeners() → build → postFrameCallback.
        await vm.requestCompanionTelemetry();
      });

      // Fire one request immediately.
      connectionVM.requestCompanionTelemetry();
    } else if (!shouldPollCompanionTelemetry &&
        _companionTelemetryTimer != null) {
      _companionTelemetryTimer?.cancel();
      _companionTelemetryTimer = null;
    }

    final fixAgeMs = companionFixTime != null
        ? DateTime.now().difference(companionFixTime).inMilliseconds
        : null;
    final shouldUseCompanion =
        wantsCompanion && connectionVM.isConnected && hasRecentCompanionFix;

    if (shouldUseCompanion != _lastShouldUseCompanion) {
      debugPrint('[MapScreen] 📍 LocationPolicy: wantsCompanion=$wantsCompanion'
          ' connected=${connectionVM.isConnected}'
          ' hasGpsFix=${connectionVM.hasCompanionGpsFix}'
          ' fixAgeMs=$fixAgeMs'
          ' hasRecentFix=$hasRecentCompanionFix'
          ' → shouldUseCompanion=$shouldUseCompanion'
          ' phoneSub=${_positionSub != null}');
      _lastShouldUseCompanion = shouldUseCompanion;
    }

    if (shouldUseCompanion) {
      _stopPhoneLocationTracking();
      final lat = connectionVM.companionLatitude;
      final lon = connectionVM.companionLongitude;
      if (lat != null && lon != null) {
        // Only push a new location when the coordinates have actually changed.
        // Calling _handleNewLocation unconditionally triggers setState → rebuild
        // → postFrameCallback → _applyLocationPolicy → repeat, causing an
        // infinite rebuild loop when the companion is stationary.
        // Use DateTime.now() so that bearing/speed inference has a real elapsed
        // time between successive fixes rather than the stale companionFixTime.
        final alreadyAt =
            _userLocation?.latitude == lat && _userLocation?.longitude == lon;
        debugPrint(
            '[MapScreen] 📍 Companion loc: $lat,$lon alreadyAt=$alreadyAt');
        if (!alreadyAt) {
          _handleNewLocation(
            LatLng(lat, lon),
            timestamp: DateTime.now(),
          );
        }
      }
    } else {
      if (_positionSub == null) {
        debugPrint('[MapScreen] 📍 Starting phone GPS fallback');
        _startPhoneLocationTracking();
      }
    }
  }

  void _applyMapRotationForTrackUp() {
    if (!_isHeadingUp) return;

    final bearing = _isMovingForTrackUp ? _courseDegrees : _headingDegrees;
    if (bearing == null) return;

    final mapRotation = (360.0 - bearing) % 360.0;
    _mapController.rotate(mapRotation);
  }

  void _handleNewLocation(
    LatLng next, {
    required DateTime? timestamp,
    double? speedMps,
    double? headingDegrees,
  }) {
    final now = timestamp ?? DateTime.now();

    // Compute movement/course bearing (track-up) from speed/heading when
    // available, or from successive points otherwise.
    const movingSpeedThresholdMps = 1.0;

    double? nextCourse;
    bool moving = false;

    if (speedMps != null &&
        speedMps.isFinite &&
        speedMps > movingSpeedThresholdMps) {
      moving = true;
      if (headingDegrees != null) {
        nextCourse = headingDegrees % 360.0;
      }
    }

    if (nextCourse == null &&
        _lastCourseLocation != null &&
        _lastCourseTime != null) {
      final prev = _lastCourseLocation!;
      final dtSeconds =
          now.difference(_lastCourseTime!).inMilliseconds / 1000.0;
      final distanceMeters = const Distance().as(LengthUnit.Meter, prev, next);

      if (dtSeconds > 0 && distanceMeters >= 3.0) {
        final inferredSpeed = distanceMeters / dtSeconds;
        moving = inferredSpeed > movingSpeedThresholdMps;
        if (moving) {
          nextCourse = _bearingBetween(prev, next);
        }
      }
    }

    _lastCourseLocation = next;
    _lastCourseTime = now;

    setState(() {
      _userLocation = next;
      _locationError = null;
      _courseDegrees = nextCourse ?? _courseDegrees;
      _isMovingForTrackUp = moving;
    });

    if (_isFollowingUser) {
      final zoom = _mapController.camera.zoom;
      _mapController.move(next, zoom);
    }

    if (_isHeadingUp && moving) {
      _applyMapRotationForTrackUp();
    }
  }

  double _bearingBetween(LatLng from, LatLng to) {
    // Bearing in degrees from north, clockwise.
    final lat1 = _degToRad(from.latitude);
    final lat2 = _degToRad(to.latitude);
    final dLon = _degToRad(to.longitude - from.longitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearingRad = math.atan2(y, x);
    final bearingDeg = (_radToDeg(bearingRad) + 360.0) % 360.0;
    return bearingDeg;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
  double _radToDeg(double rad) => rad * (180.0 / math.pi);

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Get current position (permissions already granted at app startup)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Center map on user location
      if (_userLocation != null) {
        _mapController.move(_userLocation!, 15.0);
      }
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location: $e';
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<SettingsService>();
    final connectionVM = context.watch<ConnectionViewModel>();
    final forwardingPolicy = context.watch<ForwardingPolicyService>();
    final tileCache = context.read<MapTileCacheService>();
    final db = context.read<AppDatabase>();
    final tileConfig = tileProviderForId(settingsService.settings.mapProvider);
    final currentProviderId = normalizeMapProviderId(
      settingsService.settings.mapProvider,
    );
    final showTrackedUserNames =
        settingsService.settings.mapShowTrackedUserNames;
    final showWaypointNames =
        settingsService.settings.mapShowWaypointNames;

    final telemetryConfigured = settingsService.settings.telemetryEnabled &&
        (settingsService.settings.telemetryChannelHash?.isNotEmpty ?? false);
    final telemetryActive = telemetryConfigured && connectionVM.isConnected;
    final campModeEnabled = settingsService.settings.campModeEnabled;

    final wantsCompanion =
        settingsService.settings.locationSource == LocationSource.companion;
    final companionFixTime = connectionVM.companionGpsFixTime;
    final hasRecentCompanionFix = connectionVM.hasCompanionGpsFix &&
        companionFixTime != null &&
        DateTime.now().difference(companionFixTime) <
            const Duration(seconds: 10);
    final usingCompanionGps =
        wantsCompanion && connectionVM.isConnected && hasRecentCompanionFix;

    final gpsSourceLine = usingCompanionGps
        ? 'Companion GPS'
        : wantsCompanion
            ? 'Phone GPS (fallback)'
            : 'Phone GPS';

    // Keep local state in sync with persisted settings and connection state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isHeadingUp != settingsService.settings.mapTrackUpMode) {
        setState(() {
          _isHeadingUp = settingsService.settings.mapTrackUpMode;
          if (!_isHeadingUp) {
            _isMovingForTrackUp = false;
          }
        });
        if (!settingsService.settings.mapTrackUpMode) {
          _mapController.rotate(0);
        } else {
          _applyMapRotationForTrackUp();
        }
      }
      _applyLocationPolicy(settingsService, connectionVM);
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Map'),
                Text(
                  gpsSourceLine,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Tooltip(
              message: telemetryActive
                  ? 'Sharing location'
                  : telemetryConfigured
                      ? 'Location sharing enabled (not connected)'
                      : 'Location sharing off',
              child: Icon(
                Icons.sensors,
                size: 22,
                color: telemetryActive ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Builder(builder: (context) {
              final activeHops = forwardingPolicy.lastAppliedMaxHops;
              final forwardingActive = activeHops != null && activeHops > 0;
              final tooltipMsg = forwardingActive && campModeEnabled
                  ? 'Camp mode – forwarding active ($activeHops hop${activeHops == 1 ? '' : 's'})'
                  : forwardingActive
                      ? 'Policy engine: forwarding active ($activeHops hop${activeHops == 1 ? '' : 's'})'
                      : campModeEnabled
                          ? 'Forwarding mode: camp'
                          : 'Forwarding mode: full mesh';
              final iconColor = forwardingActive
                  ? Colors.lightGreenAccent
                  : campModeEnabled
                      ? Colors.lightGreenAccent
                      : Colors.lightGreenAccent;
              final label = campModeEnabled
                  ? (forwardingActive ? 'C$activeHops' : 'C')
                  : forwardingActive
                      ? '$activeHops'
                      : null;
              final showDouble = forwardingActive || campModeEnabled;
              return Tooltip(
                message: tooltipMsg,
                child: showDouble
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 18,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  child: Icon(
                                    Icons.check,
                                    size: 18,
                                    color: iconColor,
                                  ),
                                ),
                                Positioned(
                                  left: 5,
                                  child: Icon(
                                    Icons.check,
                                    size: 18,
                                    color: iconColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (label != null) ...[
                            const SizedBox(width: 2),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: iconColor,
                              ),
                            ),
                          ],
                        ],
                      )
                    : const Icon(
                        Icons.check,
                        size: 20,
                        color: Colors.lightGreenAccent,
                      ),
              );
            }),
          ],
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Map type',
            initialValue: currentProviderId,
            onSelected: (providerId) async {
              await settingsService.setMapProvider(providerId);
            },
            itemBuilder: (context) {
              return [
                for (final opt in kMapTileProviderOptions)
                  CheckedPopupMenuItem<String>(
                    value: opt.id,
                    checked: opt.id == currentProviderId,
                    child: Text(opt.label),
                  ),
              ];
            },
            icon: const Icon(Icons.layers),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            tooltip: 'Map settings',
            icon: const Icon(Icons.settings),
            onSelected: (value) async {
              switch (value) {
                case 'toggle_tracked_user_names':
                  await settingsService
                      .setMapShowTrackedUserNames(!showTrackedUserNames);
                  break;
                case 'toggle_waypoint_names':
                  await settingsService
                      .setMapShowWaypointNames(!showWaypointNames);
                  break;
                case 'download_map_area':
                  _openDownloadMapAreaDialog(provider: tileConfig);
                  break;
                case 'manage_offline_maps':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const OfflineMapsScreen(),
                    ),
                  );
                  break;
                case 'manage_waypoints':
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ManageWaypointsScreen(),
                    ),
                  );

                  if (result is LatLng) {
                    _mapController.move(result, _mapController.camera.zoom);
                  }
                  break;
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem<String>(
                  value: 'download_map_area',
                  child: Text('Download Map Area'),
                ),
                PopupMenuItem<String>(
                  value: 'manage_offline_maps',
                  child: Text('Manage Offline Maps'),
                ),
                PopupMenuItem<String>(
                  value: 'manage_waypoints',
                  child: Text('Manage Waypoints & Routes'),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'toggle_tracked_user_names',
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Show Tracked User Names'),
                      ),
                      Icon(
                        showTrackedUserNames
                            ? Icons.check
                            : Icons.check_box_outline_blank,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'toggle_waypoint_names',
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Show Waypoint & Route Names'),
                      ),
                      Icon(
                        showWaypointNames
                            ? Icons.check
                            : Icons.check_box_outline_blank,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ??
                  const LatLng(37.7749, -122.4194), // Default to SF
              initialZoom: 15.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              interactionOptions: InteractionOptions(
                flags: _isHeadingUp
                    ? (InteractiveFlag.all &
                        ~InteractiveFlag.rotate &
                        ~InteractiveFlag.drag)
                    : (InteractiveFlag.all & ~InteractiveFlag.rotate),
              ),
              onTap: (tapPosition, point) {
                if (_isRouteEditMode) {
                  if (_draggingPointIndex != null) {
                    // Place the selected point at the tapped location.
                    setState(() {
                      _routeDraftPoints =
                          List<LatLng>.of(_routeDraftPoints)
                            ..[_draggingPointIndex!] = point;
                      _draggingPointIndex = null;
                    });
                  } else {
                    // Add a new point.
                    setState(() {
                      _routeDraftPoints = List<LatLng>.of(_routeDraftPoints)
                        ..add(point);
                    });
                  }
                }
              },
              onPositionChanged: (camera, hasGesture) {
                if (!hasGesture) return;

                // Track-up behaves like a locked "my location" mode.
                // Allow zoom, but keep the map centered on the user.
                if (_isHeadingUp) {
                  final user = _userLocation;
                  if (user == null) return;

                  const eps = 1e-7;
                  final moved = (camera.center.latitude - user.latitude).abs() >
                          eps ||
                      (camera.center.longitude - user.longitude).abs() > eps;
                  if (moved) {
                    _mapController.move(user, camera.zoom);
                  }
                  return;
                }

                if (_isFollowingUser) {
                  setState(() {
                    _isFollowingUser = false;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: tileConfig.urlTemplate,
                subdomains: tileConfig.subdomains,
                tileProvider: tileCache.tileProvider,
                userAgentPackageName: 'com.meshcore.team',
                maxNativeZoom: 18,
              ),
              StreamBuilder<List<ChannelData>>(
                stream: db.select(db.channels).watch(),
                builder: (context, channelsSnapshot) {
                  final channels =
                      channelsSnapshot.data ?? const <ChannelData>[];

                  // When tracking (telemetry) is disabled, clear contacts from the map.
                  if (!settingsService.settings.telemetryEnabled) {
                    return const SizedBox.shrink();
                  }

                  final companionKey =
                      settingsService.settings.currentCompanionPublicKey;
                  if (companionKey == null || companionKey.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final selectedHashHex =
                      settingsService.settings.telemetryChannelHash;
                  if (selectedHashHex == null || selectedHashHex.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  int? tryParseHash(String hex) {
                    final cleaned =
                        hex.trim().toLowerCase().replaceFirst('0x', '');
                    if (cleaned.isEmpty) return null;
                    if (!RegExp(r'^[0-9a-f]+$').hasMatch(cleaned)) return null;
                    try {
                      return int.parse(cleaned, radix: 16);
                    } catch (_) {
                      return null;
                    }
                  }

                  final selectedHash = tryParseHash(selectedHashHex);
                  if (selectedHash == null) return const SizedBox.shrink();

                  ChannelData? selectedChannel;
                  for (final c in channels) {
                    if (c.hash == selectedHash) {
                      selectedChannel = c;
                      break;
                    }
                  }
                  if (selectedChannel == null) return const SizedBox.shrink();
                  if (selectedChannel!.isPublic) return const SizedBox.shrink();

                  final selectedChannelIdx = selectedChannel!.channelIndex;

                  return StreamBuilder<List<ContactDisplayStateData>>(
                    stream: db.select(db.contactDisplayStates).watch(),
                    builder: (context, snapshot) {
                      final states =
                          snapshot.data ?? const <ContactDisplayStateData>[];

                      final nowMs = DateTime.now().millisecondsSinceEpoch;
                      const windowMs = 12 * 60 * 60 * 1000; // 12 hours

                      final visible = states.where((s) {
                        if (s.companionDeviceKey != companionKey) return false;
                        if (s.isManuallyHidden) return false;
                        if (s.totalTelemetryReceived <= 0) return false;
                        if (s.lastChannelIdx != selectedChannelIdx) {
                          return false;
                        }
                        if (s.lastLatitude == null || s.lastLongitude == null) {
                          return false;
                        }
                        return (nowMs - s.lastSeen) <= windowMs;
                      }).toList();

                      if (visible.isEmpty) return const SizedBox.shrink();

                      return MarkerLayer(
                        markers: [
                          for (final s in visible)
                            Marker(
                              point: LatLng(s.lastLatitude!, s.lastLongitude!),
                              width: showTrackedUserNames ? 108 : 44,
                              height: showTrackedUserNames ? 68 : 44,
                              child: _ContactMarker(
                                name: s.name,
                                showName: showTrackedUserNames,
                                pathLen: s.lastPathLen,
                                lastSeenMs: s.lastSeen,
                                isAutonomous: s.isAutonomousDevice,
                                onTap: () => _showContactDetailsDialog(db, s),
                                onDoubleTap: () => _showContactQuickInfo(s),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
              StreamBuilder<List<WaypointData>>(
                stream: db.waypointsDao.watchVisibleWaypoints(),
                builder: (context, snapshot) {
                  final waypoints = snapshot.data ?? const <WaypointData>[];
                  final routeLines = <Polyline>[];

                  for (final wp in waypoints) {
                    final type =
                        waypoint_model.WaypointType.fromString(wp.waypointType);
                    if (type != waypoint_model.WaypointType.route) continue;

                    final payload = decodeRoutePayload(
                      wp.description,
                      fallbackLatitude: wp.latitude,
                      fallbackLongitude: wp.longitude,
                    );
                    if (payload.points.length < 2) continue;

                    routeLines.add(
                      Polyline(
                        points: payload.points,
                        strokeWidth: 4,
                        color: wp.isReceived
                            ? Colors.deepPurple.withValues(alpha: 0.65)
                            : Colors.deepPurple,
                      ),
                    );
                  }

                  if (_isRouteEditMode && _routeDraftPoints.length >= 2) {
                    routeLines.add(
                      Polyline(
                        points: _routeDraftPoints,
                        strokeWidth: 3,
                        color: Colors.orange,
                        pattern: const StrokePattern.dotted(spacingFactor: 1.8),
                      ),
                    );
                  }

                  if (routeLines.isEmpty && !(_isRouteEditMode && _routeDraftPoints.isNotEmpty)) {
                    return const SizedBox.shrink();
                  }

                  return Stack(
                    children: [
                      if (routeLines.isNotEmpty)
                        PolylineLayer(polylines: routeLines),
                      if (_isRouteEditMode && _routeDraftPoints.isNotEmpty)
                        MarkerLayer(
                          markers: [
                            for (int i = 0; i < _routeDraftPoints.length; i++)
                              Marker(
                                point: _routeDraftPoints[i],
                                width: 36,
                                height: 36,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (_draggingPointIndex == i) {
                                        // Deselect if tapping same point.
                                        _draggingPointIndex = null;
                                      } else {
                                        // Select this point for moving.
                                        _draggingPointIndex = i;
                                      }
                                    });
                                  },
                                  child: Center(
                                    child: Container(
                                      width: _draggingPointIndex == i ? 26 : 20,
                                      height: _draggingPointIndex == i ? 26 : 20,
                                      decoration: BoxDecoration(
                                        color: _draggingPointIndex == i
                                            ? Colors.blue
                                            : i == 0
                                                ? Colors.green
                                                : i ==
                                                        _routeDraftPoints
                                                                .length -
                                                            1
                                                    ? Colors.red
                                                    : Colors.orange,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: _draggingPointIndex == i
                                              ? 3
                                              : 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  );
                },
              ),
              StreamBuilder<List<WaypointData>>(
                stream: db.waypointsDao.watchVisibleWaypoints(),
                builder: (context, snapshot) {
                  final waypoints = snapshot.data ?? const <WaypointData>[];
                  if (waypoints.isEmpty) return const SizedBox.shrink();

                  return MarkerLayer(
                    markers: [
                      for (final wp in waypoints)
                        Marker(
                          point: LatLng(wp.latitude, wp.longitude),
                          width: showWaypointNames ? 120 : 40,
                          height: showWaypointNames ? 60 : 40,
                          child: GestureDetector(
                            onTap: () {
                              if (_isWaypointMultiSelectMode) {
                                _toggleWaypointSelected(wp);
                              } else {
                                _showWaypointActions(wp);
                              }
                            },
                            child: Builder(
                              builder: (context) {
                                final mapRotationDegrees =
                                    MapCamera.of(context).rotation;
                                final counterRotationRad =
                                    (-mapRotationDegrees) * (math.pi / 180.0);

                                final isSelected =
                                    _selectedWaypointIds.contains(wp.id);

                                final showReceivedBadge =
                                    !_isWaypointMultiSelectMode &&
                                        wp.isReceived &&
                                        wp.isNew;

                                return Transform.rotate(
                                  angle: counterRotationRad,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          if (_isWaypointMultiSelectMode)
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                    : Colors.transparent,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .outline,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          if (showReceivedBadge)
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surface,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          if (waypoint_model.WaypointType.fromString(
                                                wp.waypointType) ==
                                              waypoint_model.WaypointType.route)
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: Colors.deepPurple,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.5,
                                                ),
                                              ),
                                            )
                                          else
                                            Text(
                                              waypoint_model.WaypointType.fromString(
                                                wp.waypointType,
                                              ).icon,
                                              style: const TextStyle(fontSize: 18),
                                            ),
                                          if (wp.isNew)
                                            Positioned(
                                              top: 6,
                                              right: 6,
                                              child: Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (showWaypointNames)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            wp.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              height: 1.1,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 44,
                      height: 44,
                      child: Builder(
                        builder: (context) {
                          final heading = _headingDegrees;
                          final course = _courseDegrees;
                          final mapRotation = _mapController.camera.rotation;
                          // Markers are rendered in map space and rotate with the map.
                          // So we compute the child rotation based on the desired screen direction.
                          // - North-up: arrow points to movement course when moving, otherwise compass.
                          // - Heading-up (track-up): arrow points up (screen), since up == heading/course.
                          final double? desiredScreenDegrees = _isHeadingUp
                              ? 0.0
                              : (_isMovingForTrackUp
                                  ? (course ?? heading)
                                  : heading);
                          if (desiredScreenDegrees == null) {
                            // No compass and no usable course yet.
                            return const Icon(
                              Icons.navigation,
                              color: Colors.blue,
                              size: 30,
                            );
                          }
                          final relativeDegrees =
                              desiredScreenDegrees - mapRotation;
                          final angleRad = relativeDegrees * (math.pi / 180.0);

                          return Transform.rotate(
                            angle: angleRad,
                            child: const Icon(
                              Icons.navigation,
                              color: Colors.blue,
                              size: 30,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              if (_navTarget != null && _userLocation != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_userLocation!, _navTarget!],
                      strokeWidth: 2.5,
                      color: Colors.black,
                      pattern: const StrokePattern.dotted(spacingFactor: 2.0),
                    ),
                  ],
                ),
            ],
          ),

          if (_isRouteEditMode)
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    _draggingPointIndex != null
                        ? 'Tap map to move point ${_draggingPointIndex! + 1} (tap point again to cancel)'
                        : _routeDraftPoints.isEmpty
                            ? 'Route mode: tap map to add first point'
                            : 'Route mode: ${_routeDraftPoints.length} points (tap a point to move it)',
                  ),
                ),
              ),
            ),

          if (_isPickingWaypoint)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Icon(
                    Icons.add,
                    size: 36,
                  ),
                ),
              ),
            ),

          if (_isWaypointMultiSelectMode)
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        _selectedWaypointIds.isEmpty
                            ? 'Tap waypoints to select'
                            : '${_selectedWaypointIds.length} selected',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedWaypointIds.isNotEmpty)
                    FloatingActionButton(
                      heroTag: 'share_selected_waypoints',
                      onPressed: _shareSelectedWaypoints,
                      child: const Icon(Icons.share),
                    ),
                  if (_selectedWaypointIds.isNotEmpty)
                    const SizedBox(height: 8),
                  if (_selectedWaypointIds.isNotEmpty)
                    FloatingActionButton(
                      heroTag: 'delete_selected_waypoints',
                      onPressed: _deleteSelectedWaypoints,
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onErrorContainer,
                      child: const Icon(Icons.delete),
                    ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'cancel_waypoint_multiselect',
                    onPressed: _exitWaypointMultiSelectMode,
                    child: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

          // Loading indicator
          if (_isLoadingLocation)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Getting location...'),
                    ],
                  ),
                ),
              ),
            ),

          // Error message
          if (_locationError != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _locationError = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Navigation distance chip (bottom-left)
          if (_navTarget != null && _userLocation != null)
            Positioned(
              left: 12,
              bottom: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.navigation,
                          size: 14, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        () {
                          final dist = Geolocator.distanceBetween(
                            _userLocation!.latitude,
                            _userLocation!.longitude,
                            _navTarget!.latitude,
                            _navTarget!.longitude,
                          );
                          return '${_navTargetName.isNotEmpty ? '${_navTargetName.length > 14 ? '${_navTargetName.substring(0, 14)}…' : _navTargetName} · ' : ''}${_formatDistance(dist)}';
                        }(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Group status overlay
          if (_isGroupStatusOpen && _navTarget == null)
            Positioned(
              left: 12,
              bottom: 16,
              width: 248,
              child: _GroupStatusPanel(
                db: db,
                settingsService: settingsService,
                formatRelativeTime: _formatRelativeTime,
                onClose: () => setState(() => _isGroupStatusOpen = false),
                onMemberTap: (state) => _showGroupMemberActions(db, state),
              ),
            ),

          // Bottom-right map controls
          if (!_isWaypointMultiSelectMode)
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isRouteEditMode) ...[
                    FloatingActionButton.small(
                      heroTag: 'map_route_cancel',
                      onPressed: _cancelRouteEditMode,
                      child: const Icon(Icons.close),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton.small(
                      heroTag: 'map_route_undo',
                      onPressed: _undoRoutePoint,
                      child: const Icon(Icons.undo),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton.small(
                      heroTag: 'map_route_save',
                      onPressed: _saveRouteDraft,
                      child: const Icon(Icons.check),
                    ),
                  ] else if (_isPickingWaypoint) ...[
                    FloatingActionButton.small(
                      heroTag: 'map_waypoint_cancel',
                      onPressed: _cancelWaypointPickMode,
                      child: const Icon(Icons.close),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton.small(
                      heroTag: 'map_waypoint_confirm',
                      onPressed: _confirmWaypointPickMode,
                      child: const Icon(Icons.check),
                    ),
                  ] else ...[
                    if (_navTarget != null) ...[
                      FloatingActionButton.small(
                        heroTag: 'map_nav_cancel',
                        tooltip: 'Cancel navigation',
                        backgroundColor:
                            Theme.of(context).colorScheme.errorContainer,
                        foregroundColor:
                            Theme.of(context).colorScheme.onErrorContainer,
                        onPressed: _stopNavigation,
                        child: const Icon(Icons.close),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FloatingActionButton.small(
                      heroTag: 'map_group_status',
                      tooltip: 'Group status',
                      backgroundColor: _isGroupStatusOpen
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      foregroundColor: _isGroupStatusOpen
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                      onPressed: () => setState(
                          () => _isGroupStatusOpen = !_isGroupStatusOpen),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.person, size: 20),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _isGroupStatusOpen
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.question_mark,
                                size: 8,
                                color: _isGroupStatusOpen
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton.small(
                      heroTag: 'map_follow_me',
                      onPressed: () async {
                        if (_userLocation == null) {
                          await _getCurrentLocation();
                        }
                        final loc = _userLocation;
                        if (loc == null) return;
                        if (_isHeadingUp) {
                          // Persist first so the post-frame settings sync
                          // doesn't flip _isHeadingUp back to true.
                          await context
                              .read<SettingsService>()
                              .setMapTrackUpMode(false);
                          setState(() {
                            _isHeadingUp = false;
                            _isMovingForTrackUp = false;
                            _isFollowingUser = true;
                          });
                          _mapController.rotate(0);
                        } else {
                          setState(() {
                            _isFollowingUser = true;
                          });
                        }
                        _mapController.move(loc, _mapController.camera.zoom);
                      },
                      child: Icon(
                        _isFollowingUser
                            ? Icons.location_searching
                            : Icons.my_location,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton.small(
                      heroTag: 'map_orientation',
                      onPressed: () async {
                        final next = !_isHeadingUp;
                        setState(() {
                          _isHeadingUp = next;
                          if (_isHeadingUp) {
                            _isFollowingUser = true;
                          }
                        });

                        await settingsService.setMapTrackUpMode(next);

                        if (next) {
                          final loc = _userLocation;
                          if (loc != null) {
                            _mapController.move(
                                loc, _mapController.camera.zoom);
                          }
                          _applyMapRotationForTrackUp();
                        } else {
                          setState(() {
                            _isMovingForTrackUp = false;
                          });
                          _mapController.rotate(0);
                        }
                      },
                      child: Icon(
                        _isHeadingUp ? Icons.explore : Icons.north,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton.small(
                      heroTag: 'map_add_waypoint',
                      onPressed: _showAddWaypointOrRouteMenu,
                      child: const Icon(Icons.add),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Color _contactStatusColor(int lastSeenMs, int pathLen) {
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final minutesSince = (nowMs - lastSeenMs) / 60000.0;
  if (minutesSince >= 10) return Colors.grey;
  if (minutesSince >= 5) return Colors.red;
  if (pathLen == 0) return Colors.green;
  if (pathLen <= 3) return Colors.yellow;
  return Colors.orange;
}

class _ContactMarker extends StatelessWidget {
  final String? name;
  final bool showName;
  final int pathLen;
  final int lastSeenMs;
  final bool isAutonomous;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const _ContactMarker({
    required this.name,
    required this.showName,
    required this.pathLen,
    required this.lastSeenMs,
    this.isAutonomous = false,
    this.onTap,
    this.onDoubleTap,
  });

  Color _borderColorForStatus() => _contactStatusColor(lastSeenMs, pathLen);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _borderColorForStatus();
    final displayName = name?.trim();
    final hasDisplayName = displayName != null && displayName.isNotEmpty;

    // Markers are rendered in map space and rotate with the map. We want these
    // contact icons to always face "up" on the screen, so we counter-rotate
    // them by the current map rotation.
    final mapRotationDegrees = MapCamera.of(context).rotation;
    final counterRotationRad = (-mapRotationDegrees) * (math.pi / 180.0);

    final marker = Transform.rotate(
      angle: counterRotationRad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                isAutonomous ? Icons.gps_fixed : Icons.person,
                color: color,
                size: 20,
              ),
            ),
          ),
          if (showName && hasDisplayName) ...[
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxWidth: 96),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null && onDoubleTap == null) return marker;

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: marker,
    );
  }
}

/// Overlay panel listing the contacts currently visible on the map.
class _GroupStatusPanel extends StatelessWidget {
  final AppDatabase db;
  final SettingsService settingsService;
  final String Function(int timestampMs) formatRelativeTime;
  final VoidCallback onClose;
  final void Function(ContactDisplayStateData) onMemberTap;

  const _GroupStatusPanel({
    required this.db,
    required this.settingsService,
    required this.formatRelativeTime,
    required this.onClose,
    required this.onMemberTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.group, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Group Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildContactList(context),
        ],
      ),
    );
  }

  Widget _buildContactList(BuildContext context) {
    final settings = settingsService.settings;

    if (!settings.telemetryEnabled) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Location sharing is off',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    final companionKey = settings.currentCompanionPublicKey;
    if (companionKey == null || companionKey.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Not connected',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    int? tryParseHash(String hex) {
      final cleaned = hex.trim().toLowerCase().replaceFirst('0x', '');
      if (cleaned.isEmpty) return null;
      if (!RegExp(r'^[0-9a-f]+$').hasMatch(cleaned)) return null;
      try {
        return int.parse(cleaned, radix: 16);
      } catch (_) {
        return null;
      }
    }

    final selectedHashHex = settings.telemetryChannelHash;
    if (selectedHashHex == null || selectedHashHex.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'No telemetry channel set',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    final selectedHash = tryParseHash(selectedHashHex);
    if (selectedHash == null) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Invalid telemetry channel',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    return StreamBuilder<List<ChannelData>>(
      stream: db.select(db.channels).watch(),
      builder: (context, channelsSnapshot) {
        final channels = channelsSnapshot.data ?? const <ChannelData>[];

        ChannelData? selectedChannel;
        for (final c in channels) {
          if (c.hash == selectedHash) {
            selectedChannel = c;
            break;
          }
        }

        if (selectedChannel == null || selectedChannel.isPublic) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'No group channel active',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          );
        }

        final selectedChannelIdx = selectedChannel.channelIndex;

        return StreamBuilder<List<ContactDisplayStateData>>(
          stream: db.select(db.contactDisplayStates).watch(),
          builder: (context, snapshot) {
            final nowMs = DateTime.now().millisecondsSinceEpoch;
            const windowMs = 12 * 60 * 60 * 1000;

            final visible =
                (snapshot.data ?? const <ContactDisplayStateData>[]).where((s) {
              if (s.companionDeviceKey != companionKey) return false;
              if (s.isManuallyHidden) return false;
              if (s.totalTelemetryReceived <= 0) return false;
              if (s.lastChannelIdx != selectedChannelIdx) return false;
              if (s.lastLatitude == null || s.lastLongitude == null) {
                return false;
              }
              return (nowMs - s.lastSeen) <= windowMs;
            }).toList()
                  ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));

            if (visible.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'No members on map',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              );
            }

            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: visible.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 12, endIndent: 12),
                itemBuilder: (context, i) {
                  final s = visible[i];
                  final name = (s.name?.trim().isNotEmpty ?? false)
                      ? s.name!.trim()
                      : s.publicKeyHex.substring(0, 8).toUpperCase();
                  final hopText = s.lastPathLen == 0
                      ? 'Direct'
                      : '${s.lastPathLen} hop${s.lastPathLen == 1 ? '' : 's'}';
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      s.isAutonomousDevice ? Icons.gps_fixed : Icons.person,
                      size: 20,
                      color: _contactStatusColor(s.lastSeen, s.lastPathLen),
                    ),
                    title: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      '$hopText · ${formatRelativeTime(s.lastSeen)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: () => onMemberTap(s),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
