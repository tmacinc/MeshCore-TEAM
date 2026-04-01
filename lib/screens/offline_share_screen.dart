// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:meshcore_team/services/team_config_server.dart';
import 'package:meshcore_team/services/team_config_service.dart';

/// Multi-step screen for sharing a team config over a local hotspot/Wi-Fi.
///
/// Flow:
/// 1. Hotspot instructions (platform-specific)
/// 2. Pick config file
/// 3. Confirm config details
/// 4. Serve file + display QR code
/// 5. Done / stop server
class OfflineShareScreen extends StatefulWidget {
  const OfflineShareScreen({super.key});

  @override
  State<OfflineShareScreen> createState() => _OfflineShareScreenState();
}

enum _ShareStep {
  instructions,
  pickFile,
  confirm,
  serving,
}

class _OfflineShareScreenState extends State<OfflineShareScreen> {
  _ShareStep _step = _ShareStep.instructions;

  // Config file state.
  File? _selectedFile;
  String? _selectedFileName;
  TeamConfigPreview? _preview;
  final TeamConfigService _configService = TeamConfigService();

  // Server state.
  final TeamConfigServer _server = TeamConfigServer();
  String? _serverUrl;
  String? _errorMessage;

  @override
  void dispose() {
    _server.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _ShareStep.instructions,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Share Config Offline'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  void _handleBack() {
    switch (_step) {
      case _ShareStep.instructions:
        Navigator.of(context).pop();
      case _ShareStep.pickFile:
        setState(() => _step = _ShareStep.instructions);
      case _ShareStep.confirm:
        setState(() {
          _step = _ShareStep.pickFile;
          _preview = null;
          _selectedFile = null;
        });
      case _ShareStep.serving:
        // Confirm before stopping server.
        _confirmStopServer();
    }
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case _ShareStep.instructions:
        return _buildInstructions(key: const ValueKey('instructions'));
      case _ShareStep.pickFile:
        return _buildPickFile(key: const ValueKey('pickFile'));
      case _ShareStep.confirm:
        return _buildConfirm(key: const ValueKey('confirm'));
      case _ShareStep.serving:
        return _buildServing(key: const ValueKey('serving'));
    }
  }

  // ── Step 1: Hotspot Instructions ──────────────────────────────────────

  Widget _buildInstructions({Key? key}) {
    final isAndroid = Platform.isAndroid;
    final isIOS = Platform.isIOS;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(
      key: key,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            children: [
              Icon(
                Icons.wifi_tethering,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Share Config Without Internet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Create a mobile hotspot on your device so team members '
                'can connect and download the config directly.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isIOS ? Icons.phone_iphone : Icons.phone_android,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isIOS
                                ? 'iPhone / iPad'
                                : isAndroid
                                    ? 'Android'
                                    : 'Mobile Hotspot',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isIOS) ...[
                        _instructionStep('1', 'Open Settings'),
                        _instructionStep('2', 'Tap Personal Hotspot'),
                        _instructionStep('3', 'Turn on "Allow Others to Join"'),
                        _instructionStep('4',
                            'Share the hotspot name and password with your team'),
                      ] else if (isAndroid) ...[
                        _instructionStep('1', 'Open Settings'),
                        _instructionStep(
                            '2', 'Tap Network & Internet (or Connections)'),
                        _instructionStep('3', 'Tap Hotspot & Tethering'),
                        _instructionStep('4', 'Turn on Wi-Fi Hotspot'),
                        _instructionStep('5',
                            'Share the hotspot name and password with your team'),
                      ] else ...[
                        _instructionStep('1',
                            'Enable your mobile hotspot from system settings'),
                        _instructionStep('2',
                            'Share the hotspot name and password with your team'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Team members should connect to your hotspot Wi-Fi '
                          'before scanning the QR code.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _step = _ShareStep.pickFile;
                        });
                      },
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _instructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Pick Config File ──────────────────────────────────────────

  Widget _buildPickFile({Key? key}) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Column(
      key: key,
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Select Config to Share',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose a .teamcfg.zip file to share with your team.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _pickConfigFile,
                    icon: const Icon(Icons.file_open),
                    label: const Text('Choose File'),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomPadding),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _step = _ShareStep.instructions;
                });
              },
              child: const Text('Back'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickConfigFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;

      final picked = result.files.single;
      if (picked.path == null) {
        setState(() => _errorMessage = 'Could not read selected file.');
        return;
      }

      // Copy to temp for preview and serving.
      final tempDir = await Directory.systemTemp.createTemp('teamcfg_share');
      final tempFile = File('${tempDir.path}/${picked.name}');
      await File(picked.path!).copy(tempFile.path);

      // Parse the preview.
      TeamConfigPreview preview;
      try {
        preview = await _configService.readPreview(tempFile);
      } catch (e) {
        if (!mounted) return;
        setState(() => _errorMessage = 'Invalid config file: $e');
        return;
      }

      if (!mounted) return;
      setState(() {
        _selectedFile = tempFile;
        _selectedFileName = picked.name;
        _preview = preview;
        _errorMessage = null;
        _step = _ShareStep.confirm;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error selecting file: $e');
      }
    }
  }

  // ── Step 3: Confirm Config Details ────────────────────────────────────

  Widget _buildConfirm({Key? key}) {
    final preview = _preview!;
    final tileSizeMB =
        (preview.tileSizeBytes / (1024 * 1024)).toStringAsFixed(1);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(
      key: key,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            children: [
              Text(
                'Config Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (preview.name != null && preview.name!.isNotEmpty) ...[
                        Text(
                          preview.name!,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        _selectedFileName ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      if (preview.description != null &&
                          preview.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(preview.description!),
                      ],
                      const Divider(height: 24),
                      if (preview.radioSettings != null) ...[
                        _detailRow(
                          Icons.settings_input_antenna,
                          'Radio Settings',
                          '${preview.radioSettings!.frequencyMHz.toStringAsFixed(3)} MHz · '
                              'BW ${preview.radioSettings!.bandwidthKHz.toStringAsFixed(1)} kHz · '
                              'SF${preview.radioSettings!.spreadingFactor} · '
                              'CR 4/${preview.radioSettings!.codingRate}',
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (preview.channels.isNotEmpty) ...[
                        _detailRow(
                          Icons.forum,
                          'Channels (${preview.channels.length})',
                          preview.channels.map((c) => c.name).join(', '),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (preview.waypoints.isNotEmpty) ...[
                        _detailRow(
                          Icons.place,
                          'Waypoints & Routes (${preview.waypoints.length})',
                          preview.waypoints.map((w) => w.name).join(', '),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (preview.tileCount > 0)
                        _detailRow(
                          Icons.map,
                          'Map Tiles',
                          '${preview.tileCount} tiles (~$tileSizeMB MB)',
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _step = _ShareStep.pickFile;
                          _preview = null;
                          _selectedFile = null;
                          _errorMessage = null;
                        });
                      },
                      child: const Text('Select Another'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _startServing,
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 4: Serve & Display QR ────────────────────────────────────────

  Future<void> _startServing() async {
    try {
      setState(() => _errorMessage = null);

      // Get local IP.
      final ip = await TeamConfigServer.getLocalIpAddress();
      if (ip == null) {
        setState(() {
          _errorMessage = 'Could not determine local IP address. '
              'Make sure your hotspot is enabled.';
        });
        return;
      }

      // Read file bytes.
      final bytes = await _selectedFile!.readAsBytes();

      // Start server.
      final port = await _server.start(
        zipBytes: bytes,
        fileName: _selectedFileName ?? 'team_config.teamcfg.zip',
      );

      final url = 'http://$ip:$port/download';

      if (!mounted) return;
      setState(() {
        _serverUrl = url;
        _step = _ShareStep.serving;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to start server: $e');
      }
    }
  }

  Widget _buildServing({Key? key}) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Column(
      key: key,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            children: [
              Icon(
                Icons.wifi_tethering,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Sharing Config',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_preview?.name != null && _preview!.name!.isNotEmpty)
                Text(
                  _preview!.name!,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),
              // QR Code
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: QrImageView(
                    data: _serverUrl!,
                    size: 220,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const Text(
                        'Team members should:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _instructionStep('1', 'Connect to your hotspot Wi-Fi'),
                      _instructionStep('2',
                          'Open MeshCore TEAM → Import Team Config → From QR Code'),
                      _instructionStep('3', 'Scan this QR code to download'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Manual URL fallback.
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual download URL:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _serverUrl!,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Downloads counter.
              if (_server.downloadCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${_server.downloadCount} download(s) completed',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                    textAlign: TextAlign.center,
                  ),
                ),
              FilledButton.icon(
                onPressed: _stopAndFinish,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Finished'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmStopServer() async {
    final stop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop Sharing?'),
        content: const Text('This will stop the config server. '
            'Team members will no longer be able to download.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Sharing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );

    if (stop == true && mounted) {
      await _server.stop();
      Navigator.of(context).pop();
    }
  }

  Future<void> _stopAndFinish() async {
    await _server.stop();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
