import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:uuid/uuid.dart';

import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/models/route_payload.dart';
import 'package:meshcore_team/models/waypoint.dart';
import 'package:meshcore_team/repositories/message_repository.dart';
import 'package:meshcore_team/widgets/waypoint_edit_dialog.dart';

class ManageWaypointsScreen extends StatefulWidget {
  const ManageWaypointsScreen({super.key});

  @override
  State<ManageWaypointsScreen> createState() => _ManageWaypointsScreenState();
}

class _ManageWaypointsScreenState extends State<ManageWaypointsScreen> {
  bool _isBusy = false;

  bool _isMultiSelectMode = false;
  Set<String> _selectedWaypointIds = <String>{};

  static const double _duplicateWaypointLocationRadiusMeters = 20;

  bool _isRoute(WaypointData waypoint) =>
      WaypointType.fromString(waypoint.waypointType) == WaypointType.route;

  double _distanceMeters(LatLng a, LatLng b) {
    const d = Distance();
    return d.as(LengthUnit.Meter, a, b);
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

  String _formatDate(int msSinceEpoch) {
    final dt = DateTime.fromMillisecondsSinceEpoch(msSinceEpoch);
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Future<void> _deleteAllReceived() async {
    final ok = await _confirm(
      'Delete received waypoints?',
      'This will delete all received waypoints from the device.',
    );
    if (!ok) return;

    final db = context.read<AppDatabase>();

    setState(() {
      _isBusy = true;
    });

    try {
      await db.waypointsDao.deleteAllReceivedWaypoints();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _deleteAllLocal() async {
    final ok = await _confirm(
      'Delete local waypoints?',
      'This will delete all local waypoints you created on the device.',
    );
    if (!ok) return;

    final db = context.read<AppDatabase>();

    setState(() {
      _isBusy = true;
    });

    try {
      await db.waypointsDao.deleteAllLocalWaypoints();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _deleteWaypoint(WaypointData waypoint) async {
    final ok = await _confirm(
      'Delete waypoint?',
      'This will delete "${waypoint.name}".',
    );
    if (!ok) return;

    final db = context.read<AppDatabase>();
    try {
      await db.waypointsDao.deleteWaypoint(waypoint.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
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

  void _enterMultiSelectMode({String? initialWaypointId}) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedWaypointIds =
          initialWaypointId != null ? <String>{initialWaypointId} : <String>{};
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
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

    setState(() {
      _isBusy = true;
    });

    try {
      for (final id in ids) {
        await db.waypointsDao.deleteWaypoint(id);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
      return;
    } finally {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted ${ids.length} waypoint(s)')),
    );

    _exitMultiSelectMode();
  }

  Future<void> _shareSelectedWaypoints() async {
    if (_selectedWaypointIds.isEmpty) return;

    final db = context.read<AppDatabase>();
    final repo = context.read<MessageRepository>();
    final all = await db.waypointsDao.getAllWaypoints();
    final selected = all
        .where((w) => _selectedWaypointIds.contains(w.id))
        .toList(growable: false);

    setState(() {
      _isBusy = true;
    });

    try {
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

      _exitMultiSelectMode();
      return;
    } finally {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
      });
    }
  }

  WaypointType _inferWaypointTypeFromGpx({
    required String? type,
    required String name,
    required String description,
  }) {
    final normalized = (type ?? '').trim().toUpperCase();
    final direct = WaypointType.fromString(normalized);
    if (direct != WaypointType.custom) return direct;

    final text = '$name $description'.toUpperCase();
    if (text.contains('CAMP') || text.contains('SITE'))
      return WaypointType.camp;
    if (text.contains('MEET') || text.contains('RENDEZVOUS')) {
      return WaypointType.meetup;
    }
    if (text.contains('DANGER') ||
        text.contains('WARNING') ||
        text.contains('HAZARD')) {
      return WaypointType.danger;
    }
    if (text.contains('DEER') ||
        text.contains('GAME') ||
        text.contains('WILDLIFE')) {
      return WaypointType.game;
    }
    if (text.contains('STAND') ||
        text.contains('BLIND') ||
        text.contains('HUNT')) {
      return WaypointType.stand;
    }
    if (text.contains('WATER') ||
        text.contains('CREEK') ||
        text.contains('STREAM') ||
        text.contains('RIVER') ||
        text.contains('LAKE') ||
        text.contains('POND')) {
      return WaypointType.water;
    }
    if (text.contains('CAR') ||
        text.contains('TRUCK') ||
        text.contains('VEHICLE') ||
        text.contains('ATV') ||
        text.contains('PARKING')) {
      return WaypointType.vehicle;
    }

    return WaypointType.custom;
  }

  Future<void> _importFromGpx() async {
    final db = context.read<AppDatabase>();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final ext = result.files.single.extension?.toLowerCase();
    if (ext != 'gpx') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a .gpx file')),
      );
      return;
    }

    setState(() {
      _isBusy = true;
    });

    try {
      final picked = result.files.single;

      final bytes = picked.bytes;
      if (bytes == null) throw StateError('Failed to read GPX file bytes');

      final gpxString = utf8.decode(bytes);
      final gpx = GpxReader().fromString(gpxString);
      final wpts = gpx.wpts ?? const <Wpt>[];

      final existingWaypoints =
          List<WaypointData>.of(await db.waypointsDao.getAllWaypoints());
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      var importedCount = 0;
      for (final w in wpts) {
        final lat = w.lat;
        final lon = w.lon;
        if (lat == null || lon == null) continue;

        final name = (w.name ?? 'Imported Waypoint').trim();
        final description = (w.desc ?? w.cmt ?? '').trim();
        final type = _inferWaypointTypeFromGpx(
          type: w.type,
          name: name,
          description: description,
        );

        final incomingNameNorm = name.toLowerCase();
        final incomingLoc = LatLng(lat, lon);
        var isDuplicate = false;

        for (final existing in existingWaypoints) {
          final existingNameNorm = existing.name.trim().toLowerCase();
          final nameMatch = incomingNameNorm.isNotEmpty &&
              existingNameNorm.isNotEmpty &&
              existingNameNorm == incomingNameNorm;

          final dist = _distanceMeters(
            LatLng(existing.latitude, existing.longitude),
            incomingLoc,
          );
          final locationMatch = dist <= _duplicateWaypointLocationRadiusMeters;

          if (nameMatch || locationMatch) {
            isDuplicate = true;
            break;
          }
        }

        if (isDuplicate) continue;

        final id = const Uuid().v4();
        await db.waypointsDao.insertWaypoint(
          WaypointsCompanion.insert(
            id: id,
            name: name,
            description: Value(description),
            latitude: lat,
            longitude: lon,
            waypointType: type.name.toUpperCase(),
            creatorNodeId: 'imported',
            createdAt: nowMs,
            isReceived: const Value(true),
            isVisible: const Value(true),
            isNew: const Value(false),
          ),
        );

        existingWaypoints.add(
          WaypointData(
            id: id,
            meshId: null,
            name: name,
            description: description,
            latitude: lat,
            longitude: lon,
            waypointType: type.name.toUpperCase(),
            creatorNodeId: 'imported',
            createdAt: nowMs,
            isReceived: true,
            isVisible: true,
            isNew: false,
          ),
        );

        importedCount++;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $importedCount waypoint(s)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _exportToGpx({List<WaypointData>? waypoints}) async {
    final db = context.read<AppDatabase>();

    setState(() {
      _isBusy = true;
    });

    try {
      final list = waypoints ?? await db.waypointsDao.getAllWaypoints();

      final gpx = Gpx();
      gpx.metadata = Metadata(
        name: 'MeshCore Waypoints',
        desc: 'Waypoints exported from MeshCore Team app',
        time: DateTime.now().toUtc(),
      );

      gpx.wpts = [
        for (final w in list)
          Wpt(
            lat: w.latitude,
            lon: w.longitude,
            name: w.name,
            desc: w.description,
            type: w.waypointType,
            cmt: 'Created by ${w.creatorNodeId}',
            time: DateTime.fromMillisecondsSinceEpoch(w.createdAt).toUtc(),
          ),
      ];

      final xml = GpxWriter().asString(gpx, pretty: true);
      final fileName =
          'meshcore_waypoints_${DateTime.now().millisecondsSinceEpoch}.gpx';
      final bytes = Uint8List.fromList(utf8.encode(xml));

      // Build the XFile once — used by both paths.
      final xFile = XFile.fromData(
        bytes,
        mimeType: 'application/gpx+xml',
        name: fileName,
      );

      Directory? downloadsDir;
      try {
        downloadsDir = await getDownloadsDirectory();
      } catch (_) {
        // Not available on this platform.
      }

      if (!mounted) return;

      // Show export options dialog.
      final choice = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Export GPX',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(height: 1),
              if (downloadsDir != null)
                ListTile(
                  leading: const Icon(Icons.save_alt),
                  title: const Text('Save to Downloads'),
                  subtitle: Text(downloadsDir.path),
                  onTap: () => Navigator.pop(ctx, 'downloads'),
                ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share…'),
                subtitle: const Text('Share with other apps'),
                onTap: () => Navigator.pop(ctx, 'share'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

      if (choice == null || !mounted) return;

      if (choice == 'downloads') {
        final file = File('${downloadsDir!.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to ${file.path}')),
        );
      } else {
        await Share.shareXFiles([xFile], subject: fileName);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _showWaypointActions(WaypointData waypoint) async {
    final db = context.read<AppDatabase>();

    if (waypoint.isNew) {
      await db.waypointsDao.markAsViewed(waypoint.id);
    }
    if (!mounted) return;

    final outerContext = context;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final type = WaypointType.fromString(waypoint.waypointType);

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
                if (_isRoute(waypoint)) ...[
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
                ListTile(
                  leading: const Icon(Icons.navigation),
                  title: const Text('Navigate to Waypoint'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(outerContext).pop(
                      LatLng(waypoint.latitude, waypoint.longitude),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Share via Mesh'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final repo = outerContext.read<MessageRepository>();
                    final ok = await repo.sendWaypointToMesh(waypoint);
                    if (!mounted) return;
                    ScaffoldMessenger.of(outerContext).showSnackBar(
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
                    _enterMultiSelectMode(initialWaypointId: waypoint.id);
                  },
                ),
                if (!waypoint.isReceived)
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: Text(
                      _isRoute(waypoint) ? 'Edit Route Info' : 'Edit Waypoint',
                    ),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _editWaypoint(waypoint);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete Waypoint'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _deleteWaypoint(waypoint);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editWaypoint(WaypointData waypoint) async {
    if (waypoint.isReceived) return;

    final type = WaypointType.fromString(waypoint.waypointType);
    final routePayload = _isRoute(waypoint)
        ? decodeRoutePayload(
            waypoint.description,
            fallbackLatitude: waypoint.latitude,
            fallbackLongitude: waypoint.longitude,
          )
        : null;
    final result = await context.showWaypointEditDialog(
      initialName: waypoint.name,
      initialDescription: routePayload?.description ?? waypoint.description,
      initialType: type,
      initialColorValue: routePayload?.colorValue,
    );

    if (result == null) return;

    final db = context.read<AppDatabase>();
    final existingPayload = _isRoute(waypoint)
        ? decodeRoutePayload(
            waypoint.description,
            fallbackLatitude: waypoint.latitude,
            fallbackLongitude: waypoint.longitude,
          )
        : null;
    final nextDescription = existingPayload != null
        ? encodeRoutePayload(
            description: result.description,
            points: existingPayload.points,
            colorValue: result.colorValue,
          )
        : result.description;
    await db.waypointsDao.updateWaypoint(
      waypoint.id,
      WaypointsCompanion(
        name: Value(result.name),
        description: Value(nextDescription),
        waypointType: Value(result.type.name.toUpperCase()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isMultiSelectMode
              ? (_selectedWaypointIds.isEmpty
                  ? 'Select Waypoints'
                  : '${_selectedWaypointIds.length} selected')
              : 'Manage Waypoints & Routes',
        ),
        leading: _isMultiSelectMode
            ? IconButton(
                tooltip: 'Cancel selection',
                onPressed: _exitMultiSelectMode,
                icon: const Icon(Icons.close),
              )
            : null,
        actions: _isMultiSelectMode
            ? [
                if (_selectedWaypointIds.isNotEmpty)
                  IconButton(
                    tooltip: 'Share selected',
                    onPressed: _shareSelectedWaypoints,
                    icon: const Icon(Icons.share),
                  ),
                if (_selectedWaypointIds.isNotEmpty)
                  IconButton(
                    tooltip: 'Export selected',
                    onPressed: () async {
                      final all = await db.waypointsDao.getAllWaypoints();
                      final selected = all
                          .where((w) => _selectedWaypointIds.contains(w.id))
                          .toList(growable: false);
                      await _exportToGpx(waypoints: selected);
                      _exitMultiSelectMode();
                    },
                    icon: const Icon(Icons.file_download),
                  ),
                if (_selectedWaypointIds.isNotEmpty)
                  IconButton(
                    tooltip: 'Delete selected',
                    onPressed: _deleteSelectedWaypoints,
                    icon: const Icon(Icons.delete),
                  ),
              ]
            : [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'import_gpx':
                        _importFromGpx();
                        break;
                      case 'export_gpx':
                        _exportToGpx();
                        break;
                      case 'select_multiple':
                        _enterMultiSelectMode();
                        break;
                      case 'delete_received':
                        _deleteAllReceived();
                        break;
                      case 'delete_local':
                        _deleteAllLocal();
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'import_gpx',
                      child: Text('Import from GPX'),
                    ),
                    PopupMenuItem(
                      value: 'export_gpx',
                      child: Text('Export to GPX'),
                    ),
                    PopupMenuItem(
                      value: 'select_multiple',
                      child: Text('Select Multiple'),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete_received',
                      child: Text('Delete All Received'),
                    ),
                    PopupMenuItem(
                      value: 'delete_local',
                      child: Text('Delete All Local'),
                    ),
                  ],
                ),
              ],
      ),
      body: Stack(
        children: [
          StreamBuilder<List<WaypointData>>(
            stream: db.waypointsDao.watchAllWaypoints(),
            builder: (context, snapshot) {
              final waypoints = snapshot.data ?? const <WaypointData>[];
              final total = waypoints.length;
              final local = waypoints.where((w) => !w.isReceived).length;
              final received = waypoints.where((w) => w.isReceived).length;
              final routes = waypoints.where(_isRoute).length;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stats',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text('Total: $total'),
                          Text('Local: $local'),
                          Text('Received: $received'),
                          Text('Routes: $routes'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (waypoints.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Text('No waypoints or routes yet.'),
                      ),
                    )
                  else
                    ...waypoints.map((w) {
                      final type = WaypointType.fromString(w.waypointType);
                      final payload = _isRoute(w)
                          ? decodeRoutePayload(
                              w.description,
                              fallbackLatitude: w.latitude,
                              fallbackLongitude: w.longitude,
                            )
                          : null;
                      final subtitle =
                          '${w.latitude.toStringAsFixed(6)}, ${w.longitude.toStringAsFixed(6)}\n${payload != null ? 'Points: ${payload.points.length}\n' : ''}${_formatDate(w.createdAt)}';

                      final isSelected = _selectedWaypointIds.contains(w.id);

                      return Card(
                        child: ListTile(
                          leading: _isMultiSelectMode
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => _toggleWaypointSelected(w),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      type.icon,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    if (payload?.colorValue != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Color(payload!.colorValue!),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                          title: Text(w.name),
                          subtitle: Text(subtitle),
                          isThreeLine: true,
                          trailing: _isMultiSelectMode
                              ? null
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!w.isReceived)
                                      IconButton(
                                        tooltip: 'Edit',
                                        onPressed: () => _editWaypoint(w),
                                        icon: const Icon(Icons.edit),
                                      ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      onPressed: () => _deleteWaypoint(w),
                                      icon: const Icon(Icons.delete),
                                    ),
                                  ],
                                ),
                          onTap: () async {
                            if (_isMultiSelectMode) {
                              _toggleWaypointSelected(w);
                              return;
                            }

                            await _showWaypointActions(w);
                          },
                          onLongPress: () {
                            if (_isMultiSelectMode) return;
                            _enterMultiSelectMode(initialWaypointId: w.id);
                          },
                        ),
                      );
                    }),
                ],
              );
            },
          ),
          if (_isBusy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
