// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/services/settings_service.dart';
import '../utils/battery_optimization_helper.dart';

/// Permissions Screen - Requests all required permissions on first launch
class PermissionsScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionsScreen({
    super.key,
    required this.onPermissionsGranted,
  });

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _isRequesting = false;
  bool _permissionsDenied = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Intentionally do NOT auto-request permissions on screen load.
    // We show the explainer first, and only prompt after explicit user action.
  }

  /// Request all required permissions at once
  Future<void> _requestAllPermissions() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
      _permissionsDenied = false;
      _errorMessage = null;
    });

    try {
      // Build permission list. On iOS, request Bluetooth last because it
      // triggers the local network prompt — show familiar prompts first.
      final permissionsToRequest = <Permission>[];

      // Location permission (required for BLE on Android, GPS for all platforms)
      permissionsToRequest.add(Permission.location);

      // Notification permission (Android 13+, iOS always)
      permissionsToRequest.add(Permission.notification);

      // Bluetooth permissions (requested last on iOS to avoid local network
      // prompt appearing before the user has context)
      if (Platform.isAndroid) {
        if (await _shouldRequestBluetoothScan()) {
          permissionsToRequest.add(Permission.bluetoothScan);
        }
        if (await _shouldRequestBluetoothConnect()) {
          permissionsToRequest.add(Permission.bluetoothConnect);
        }
      } else if (Platform.isIOS) {
        permissionsToRequest.add(Permission.bluetooth);
      }

      debugPrint('🔐 Requesting ${permissionsToRequest.length} permissions sequentially...');

      // Request permissions one at a time so iOS doesn't stack dialogs.
      bool allGranted = true;
      final deniedPermissions = <String>[];

      for (final permission in permissionsToRequest) {
        final status = await permission.request();
        debugPrint('🔐 ${permission.toString()}: ${status.toString()}');

        if (!status.isGranted) {
          allGranted = false;
          deniedPermissions.add(_getPermissionName(permission));
        }
      }

      if (allGranted) {
        debugPrint('✅ All permissions granted!');

        // Optional: request background location (Android only). This is not required
        // for initial app usage, so we don't block launch if denied.
        if (Platform.isAndroid) {
          await _requestOptionalBackgroundLocation();
        }

        // Request battery optimization exemption (Android only, optional)
        if (Platform.isAndroid) {
          await _requestBatteryOptimization();
        }

        // All permissions granted, proceed to app
        widget.onPermissionsGranted();
      } else {
        debugPrint('❌ Permissions denied: ${deniedPermissions.join(", ")}');
        setState(() {
          _isRequesting = false;
          _permissionsDenied = true;
          _errorMessage =
              'Required permissions denied:\n${deniedPermissions.join("\n")}';
        });
      }
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      setState(() {
        _isRequesting = false;
        _permissionsDenied = true;
        _errorMessage = 'Error requesting permissions: $e';
      });
    }
  }

  Future<void> _requestOptionalBackgroundLocation() async {
    try {
      final status = await Permission.locationAlways.status;
      if (!status.isGranted) {
        await Permission.locationAlways.request();
      }
    } catch (e) {
      debugPrint('⚠️ Background location request skipped: $e');
    }
  }

  /// Check if we should request Bluetooth Scan permission
  Future<bool> _shouldRequestBluetoothScan() async {
    if (!Platform.isAndroid) return false;
    final status = await Permission.bluetoothScan.status;
    return !status.isGranted;
  }

  /// Check if we should request Bluetooth Connect permission
  Future<bool> _shouldRequestBluetoothConnect() async {
    if (!Platform.isAndroid) return false;
    final status = await Permission.bluetoothConnect.status;
    return !status.isGranted;
  }

  /// Request battery optimization exemption (Android only, optional)
  Future<void> _requestBatteryOptimization() async {
    try {
      final settings = context.read<SettingsService>();

      if (settings.settings.batteryOptimizationRequested) {
        debugPrint('⚡ Battery optimization already prompted (settings flag)');
        return;
      }

      final isIgnoring =
          await BatteryOptimizationHelper.isIgnoringBatteryOptimizations();
      if (!isIgnoring) {
        debugPrint('⚡ Requesting battery optimization exemption...');

        // Show explanation dialog
        if (mounted) {
          final shouldRequest = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Battery Optimization'),
              content: const Text(
                'To keep your mesh connection active in the background, '
                'we recommend disabling battery optimization for this app.\n\n'
                'This will allow the app to maintain a stable Bluetooth connection '
                'to your radio even when the screen is off.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Skip'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Allow'),
                ),
              ],
            ),
          );

          if (shouldRequest == true) {
            await BatteryOptimizationHelper
                .requestBatteryOptimizationExemption();
            debugPrint('⚡ Battery optimization request shown');
            await settings.setBatteryOptimizationRequested(true);
          } else {
            debugPrint('⚡ User skipped battery optimization');
            await settings.setBatteryOptimizationRequested(true);
          }
        }
      } else {
        debugPrint('⚡ Battery optimization already disabled');
        await settings.setBatteryOptimizationRequested(true);
      }
    } catch (e) {
      debugPrint('⚠️ Error handling battery optimization: $e');
      // Don't fail the permission flow if battery optimization fails
    }
  }

  /// Get human-readable permission name
  String _getPermissionName(Permission permission) {
    if (permission == Permission.bluetoothScan ||
        permission == Permission.bluetoothConnect ||
        permission == Permission.bluetooth) {
      return 'Bluetooth';
    } else if (permission == Permission.location) {
      return 'Location';
    } else if (permission == Permission.notification) {
      return 'Notifications';
    }
    return permission.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // App Icon/Logo
            SizedBox(
              height: 80,
              child: Image.asset(
                Platform.isIOS
                    ? 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png'
                    : 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.radio,
                  size: 80,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'MeshCore TEAM',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'To connect to your mesh radio and share messages, '
              'MeshCore TEAM needs access to:',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Permission items
            _buildPermissionItem(
              Icons.bluetooth,
              'Bluetooth',
              'Connect to your mesh radio',
            ),
            const SizedBox(height: 16),
            _buildPermissionItem(
              Icons.location_on,
              'Location',
              'Required for maps: navigate and share your location with your team.',
            ),
            const SizedBox(height: 16),
            _buildPermissionItem(
              Icons.notifications,
              'Notifications',
              'Alert you when messages arrive',
            ),
            const SizedBox(height: 16),
            _buildPermissionItem(
              Icons.sync,
              'Background',
              'Keep your mesh connection and tracking running in the background.',
            ),

            const SizedBox(height: 24),

            // Primary action (show before any OS prompts)
            if (!_isRequesting && !_permissionsDenied) ...[
              ElevatedButton(
                onPressed: _requestAllPermissions,
                child: const Text('Continue to permissions'),
              ),
              const SizedBox(height: 12),
              Text(
                'You can change these later in system settings.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],

            // Status/Error
            if (_isRequesting)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Requesting permissions...',
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else if (_permissionsDenied) ...[
              Card(
                color: Colors.red.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ?? 'Permissions Required',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.red,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'MeshCore TEAM requires these permissions to function. '
                        'Please grant all permissions to continue.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => exit(0),
                      child: const Text('Exit App'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _requestAllPermissions,
                      child: const Text('Try Again'),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 32, color: Colors.blue),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
