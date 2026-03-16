// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/services/forwarding_policy_service.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';
import 'package:provider/provider.dart';

class ForwardingDebugScreen extends StatefulWidget {
  const ForwardingDebugScreen({super.key});

  @override
  State<ForwardingDebugScreen> createState() => _ForwardingDebugScreenState();
}

class _ForwardingDebugScreenState extends State<ForwardingDebugScreen> {
  static const Duration _trackingTimeout = Duration(hours: 12);

  String? _selectedNodeId;

  @override
  Widget build(BuildContext context) {
    final settingsService = context.read<SettingsService>();
    final settings = context.watch<SettingsService>().settings;
    final forwarding = context.watch<ForwardingPolicyService>();
    final connectionVM = context.watch<ConnectionViewModel>();
    final db = context.read<AppDatabase>();

    final companionKey = settings.currentCompanionPublicKey;
    final contactsStream = (companionKey == null || companionKey.isEmpty)
        ? Stream<List<ContactData>>.value(const <ContactData>[])
        : db.contactsDao.watchContactsByCompanion(companionKey);
    final channelsStream = (companionKey == null || companionKey.isEmpty)
        ? Stream<List<ChannelData>>.value(const <ChannelData>[])
        : db.channelsDao.watchChannelsByCompanion(companionKey);
    final displayStatesStream = db.select(db.contactDisplayStates).watch();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forwarding Debug'),
      ),
      body: StreamBuilder<List<ChannelData>>(
        stream: channelsStream,
        builder: (context, snapshot) {
          final channels = snapshot.data ?? const <ChannelData>[];
          final trackingChannelIndex = _resolveTrackingChannelIndex(
              settings.telemetryChannelHash, channels);

          return StreamBuilder<List<ContactData>>(
            stream: contactsStream,
            builder: (context, contactsSnapshot) {
              final allContacts =
                  contactsSnapshot.data ?? const <ContactData>[];
              return StreamBuilder<List<ContactDisplayStateData>>(
                stream: displayStatesStream,
                builder: (context, statesSnapshot) {
                  final allStates =
                      statesSnapshot.data ?? const <ContactDisplayStateData>[];
                  final visibleTrackedStates = _filterMapVisibleTrackedStates(
                    allStates,
                    companionKey: companionKey,
                    trackingChannelIndex: trackingChannelIndex,
                  );

                  final nodes = _buildNodes(
                    connectionVM,
                    visibleTrackedStates,
                    allContacts,
                  );

                  final selectedNode = _resolveSelected(nodes);
                  final furthestHop = _furthestHop(visibleTrackedStates);
                  final summarySuffix = trackingChannelIndex == null
                      ? 'Tracking channel not configured'
                      : 'Tracking channel index: $trackingChannelIndex • timeout: 12h • visible users: ${visibleTrackedStates.length}';

                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopSummary(
                          forwarding: forwarding,
                          selectedAlgorithmMode:
                              settings.forwardingAlgorithmMode,
                          onAlgorithmChanged:
                              settingsService.setForwardingAlgorithmMode,
                          trackingEnabled: settings.telemetryEnabled,
                          furthestHop: furthestHop,
                          summarySuffix: summarySuffix,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 900;
                              if (isWide) {
                                return Row(
                                  children: [
                                    SizedBox(
                                      width: 360,
                                      child:
                                          _buildGroupList(nodes, selectedNode),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSelectedDetail(
                                        allNodes: nodes,
                                        selectedNode: selectedNode,
                                        forwarding: forwarding,
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return Column(
                                children: [
                                  SizedBox(
                                    height: 260,
                                    child: _buildGroupList(nodes, selectedNode),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: _buildSelectedDetail(
                                      allNodes: nodes,
                                      selectedNode: selectedNode,
                                      forwarding: forwarding,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  int? _resolveTrackingChannelIndex(
    String? telemetryChannelHash,
    List<ChannelData> channels,
  ) {
    if (telemetryChannelHash == null || telemetryChannelHash.isEmpty)
      return null;

    final hash = _tryParseChannelHash(telemetryChannelHash);
    if (hash == null) return null;

    for (final channel in channels) {
      if (channel.hash == hash) return channel.channelIndex;
    }

    return null;
  }

  List<ContactDisplayStateData> _filterMapVisibleTrackedStates(
    List<ContactDisplayStateData> states, {
    required String? companionKey,
    required int? trackingChannelIndex,
  }) {
    if (trackingChannelIndex == null) {
      return const <ContactDisplayStateData>[];
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cutoffMs = nowMs - _trackingTimeout.inMilliseconds;

    return states.where((state) {
      if (companionKey == null || companionKey.isEmpty) return false;
      if (state.companionDeviceKey != companionKey) return false;
      if (state.isManuallyHidden) return false;
      if (state.totalTelemetryReceived <= 0) return false;
      if (state.lastChannelIdx != trackingChannelIndex) return false;
      if (state.lastLatitude == null || state.lastLongitude == null)
        return false;
      return state.lastSeen >= cutoffMs;
    }).toList(growable: false);
  }

  List<_DebugNode> _buildNodes(
    ConnectionViewModel connectionVM,
    List<ContactDisplayStateData> visibleStates,
    List<ContactData> contacts,
  ) {
    final selfInfo = connectionVM.deviceCapabilities;
    final selfKey = selfInfo?.publicKey;

    final contactByHex = <String, ContactData>{
      for (final contact in contacts) _hex(contact.publicKey): contact,
    };

    final otherStates = visibleStates.where((state) {
      final contact = contactByHex[state.publicKeyHex];
      if (contact == null) return false;
      if (selfKey == null || selfKey.isEmpty) return true;
      return !_sameBytes(contact.publicKey, selfKey);
    }).toList()
      ..sort((left, right) {
        final leftHop = left.lastPathLen < 0 ? 999 : left.lastPathLen;
        final rightHop = right.lastPathLen < 0 ? 999 : right.lastPathLen;
        if (leftHop != rightHop) return leftHop.compareTo(rightHop);
        return right.lastSeen.compareTo(left.lastSeen);
      });

    final nodes = <_DebugNode>[
      _DebugNode(
        id: selfKey == null || selfKey.isEmpty
            ? 'self'
            : 'self_${_hex(selfKey, byteCount: 8)}',
        name: connectionVM.deviceName.isNotEmpty
            ? connectionVM.deviceName
            : 'This Companion',
        publicKey: selfKey,
        isSelf: true,
        isDirect: true,
        hopCount: 0,
        isRepeater: false,
        isOutOfRange: false,
        lastSeen: null,
        sourceContact: null,
        sourceState: null,
      ),
      ...otherStates.map(
        (state) {
          final contact = contactByHex[state.publicKeyHex];
          final publicKey =
              contact?.publicKey ?? _bytesFromHex(state.publicKeyHex);

          return _DebugNode(
            id: state.publicKeyHex,
            name: state.name?.isNotEmpty == true
                ? state.name!
                : (contact?.name?.isNotEmpty == true
                    ? contact!.name!
                    : 'Contact ${state.publicKeyHex.substring(0, min(6, state.publicKeyHex.length))}'),
            publicKey: publicKey,
            isSelf: false,
            isDirect: contact?.isDirect ?? (state.lastPathLen <= 0),
            hopCount: state.lastPathLen,
            isRepeater: contact?.isRepeater ?? false,
            isOutOfRange: contact?.isOutOfRange ?? false,
            lastSeen: DateTime.fromMillisecondsSinceEpoch(state.lastSeen),
            sourceContact: contact,
            sourceState: state,
          );
        },
      ),
    ];

    return nodes;
  }

  _DebugNode _resolveSelected(List<_DebugNode> nodes) {
    if (_selectedNodeId == null) {
      _selectedNodeId = nodes.first.id;
      return nodes.first;
    }

    for (final node in nodes) {
      if (node.id == _selectedNodeId) return node;
    }

    _selectedNodeId = nodes.first.id;
    return nodes.first;
  }

  int _furthestHop(List<ContactDisplayStateData> states) {
    var maxHop = -1;
    for (final state in states) {
      if (state.lastPathLen >= 0) {
        maxHop = max(maxHop, state.lastPathLen);
      }
    }
    return maxHop;
  }

  Widget _buildTopSummary({
    required ForwardingPolicyService forwarding,
    required String selectedAlgorithmMode,
    required Future<void> Function(String) onAlgorithmChanged,
    required bool trackingEnabled,
    required int furthestHop,
    required String summarySuffix,
  }) {
    final statusText = !trackingEnabled
        ? 'Tracking OFF → forwarding inactive'
        : forwarding.isPolicyEngineActive
            ? 'Forwarding policy engine active'
            : 'Forwarding policy engine inactive';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active policy: ${forwarding.forwardingMode}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: selectedAlgorithmMode,
              decoration: const InputDecoration(
                labelText: 'Forwarding algorithm (debug)',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: ForwardingAlgorithmMode.forwardingV1,
                  child: Text('Forwarding V1 (#TEL)'),
                ),
                DropdownMenuItem(
                  value: ForwardingAlgorithmMode.topology,
                  child: Text('Topology #T'),
                ),
                DropdownMenuItem(
                  value: ForwardingAlgorithmMode.auto,
                  child: Text('Auto (prefer topology)'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                unawaited(onAlgorithmChanged(value));
              },
            ),
            const SizedBox(height: 4),
            Text(
                'Selected strategy: ${forwarding.selectedAlgorithmMode} • Effective strategy: ${forwarding.effectiveAlgorithmMode}'),
            const SizedBox(height: 4),
            Text(statusText),
            const SizedBox(height: 4),
            Text(
              furthestHop >= 0
                  ? 'Furthest user hop distance: $furthestHop'
                  : 'Furthest user hop distance: n/a',
            ),
            const SizedBox(height: 4),
            Text(summarySuffix),
          ],
        ),
      ),
    );
  }

  int? _tryParseChannelHash(String hashHex) {
    final cleaned = hashHex.trim().toLowerCase().replaceFirst('0x', '');
    if (cleaned.isEmpty) return null;

    final isHex = RegExp(r'^[0-9a-f]+$').hasMatch(cleaned);
    if (!isHex) return null;

    try {
      return int.parse(cleaned, radix: 16);
    } catch (_) {
      return null;
    }
  }

  Widget _buildGroupList(List<_DebugNode> nodes, _DebugNode selectedNode) {
    return Card(
      child: ListView.separated(
        itemCount: nodes.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final node = nodes[index];
          final isSelected = node.id == selectedNode.id;

          return ListTile(
            selected: isSelected,
            leading: Icon(node.isSelf ? Icons.person : Icons.device_hub),
            title: Text(
              node.isSelf ? '${node.name} (You)' : node.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(_nodeSubtitle(node)),
            onTap: () {
              setState(() {
                _selectedNodeId = node.id;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildSelectedDetail({
    required List<_DebugNode> allNodes,
    required _DebugNode selectedNode,
    required ForwardingPolicyService forwarding,
  }) {
    final neighbors = _directNeighborsFor(selectedNode, allNodes);

    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedNode.isSelf
                  ? '${selectedNode.name} (You)'
                  : selectedNode.name,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Public key: ${_hex(selectedNode.publicKey, byteCount: 8)}'),
            Text('Hop count: ${_hopLabel(selectedNode.hopCount)}'),
            Text('Direct: ${selectedNode.isDirect ? 'yes' : 'no'}'),
            Text('Repeater: ${selectedNode.isRepeater ? 'yes' : 'no'}'),
            Text('Out of range: ${selectedNode.isOutOfRange ? 'yes' : 'no'}'),
            Text('Last seen: ${_timeLabel(selectedNode.lastSeen)}'),
            if (selectedNode.sourceState != null) ...[
              Text(
                  'Telemetry channel idx: ${selectedNode.sourceState!.lastChannelIdx}'),
              Text(
                  'Telemetry count: ${selectedNode.sourceState!.totalTelemetryReceived}'),
            ],
            const SizedBox(height: 12),
            const Text(
              'Forwarding settings',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            if (selectedNode.isSelf) ...[
              Text('Mode: ${forwarding.forwardingMode}'),
              Text(
                  'Policy engine active: ${forwarding.isPolicyEngineActive ? 'yes' : 'no'}'),
              Text('Last max hops: ${forwarding.lastAppliedMaxHops ?? 'n/a'}'),
              Text(
                  'Last forward list size: ${forwarding.lastAppliedPrefixCount}'),
              Text('Last trigger: ${forwarding.lastAppliedTrigger ?? 'n/a'}'),
              Text('Last applied: ${_timeLabel(forwarding.lastAppliedAt)}'),
              Text('Last error: ${forwarding.lastPolicyError ?? 'none'}'),
            ] else ...[
              Text(
                  'Forwarding candidate: ${_isForwardingCandidate(selectedNode) ? 'yes' : 'no'}'),
              Text('Candidate reason: ${_candidateReason(selectedNode)}'),
            ],
            const SizedBox(height: 12),
            const Text(
              'Direct neighbors',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            if (neighbors.isEmpty)
              const Text(
                'No direct-neighbor data available for this node from current telemetry.',
              )
            else
              ...neighbors.map(
                (neighbor) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '- ${neighbor.name} (${_hopLabel(neighbor.hopCount)})',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<_DebugNode> _directNeighborsFor(
    _DebugNode selectedNode,
    List<_DebugNode> allNodes,
  ) {
    if (selectedNode.isSelf) {
      return allNodes
          .where((node) => !node.isSelf && node.isDirect)
          .toList(growable: false);
    }

    if (selectedNode.isDirect) {
      return allNodes.where((node) => node.isSelf).toList(growable: false);
    }

    return const <_DebugNode>[];
  }

  bool _isForwardingCandidate(_DebugNode node) {
    if (node.isSelf || node.sourceContact == null) return false;

    final contact = node.sourceContact!;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final staleCutoffMs = nowMs - const Duration(minutes: 15).inMilliseconds;

    return contact.publicKey.length >= 6 &&
        contact.lastSeen >= staleCutoffMs &&
        !contact.isOutOfRange;
  }

  String _candidateReason(_DebugNode node) {
    if (node.isSelf) return 'Local node is not part of whitelist candidates';
    if (node.sourceContact == null) return 'No contact data';

    final contact = node.sourceContact!;
    if (contact.publicKey.length < 6) return 'Public key too short';

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final staleCutoffMs = nowMs - const Duration(minutes: 15).inMilliseconds;
    if (contact.lastSeen < staleCutoffMs) return 'Stale (>15 min)';
    if (contact.isOutOfRange) return 'Marked out-of-range';

    return 'Eligible under smart-forwarding filters';
  }

  String _nodeSubtitle(_DebugNode node) {
    if (node.isSelf) return 'Hop 0 • local node';

    final hop = _hopLabel(node.hopCount);
    final direct = node.isDirect ? 'direct' : 'relay';
    return '$hop • $direct';
  }

  String _hopLabel(int hopCount) {
    if (hopCount < 0) return 'unknown hop';
    return 'hop $hopCount';
  }

  String _timeLabel(DateTime? time) {
    if (time == null) return 'n/a';
    final delta = DateTime.now().difference(time);

    if (delta.inSeconds < 60) return '${delta.inSeconds}s ago';
    if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
    if (delta.inHours < 24) return '${delta.inHours}h ago';
    return '${delta.inDays}d ago';
  }

  String _hex(Uint8List? bytes, {int? byteCount}) {
    if (bytes == null || bytes.isEmpty) return 'n/a';

    final maxBytes =
        byteCount == null ? bytes.length : min(byteCount, bytes.length);
    final buffer = StringBuffer();

    for (var i = 0; i < maxBytes; i++) {
      buffer.write(bytes[i].toRadixString(16).padLeft(2, '0'));
    }

    return buffer.toString();
  }

  Uint8List? _bytesFromHex(String hex) {
    if (hex.isEmpty || hex.length.isOdd) return null;

    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      final pair = hex.substring(i, i + 2);
      final value = int.tryParse(pair, radix: 16);
      if (value == null) return null;
      bytes.add(value);
    }
    return Uint8List.fromList(bytes);
  }

  bool _sameBytes(Uint8List left, Uint8List right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }
}

class _DebugNode {
  final String id;
  final String name;
  final Uint8List? publicKey;
  final bool isSelf;
  final bool isDirect;
  final int hopCount;
  final bool isRepeater;
  final bool isOutOfRange;
  final DateTime? lastSeen;
  final ContactData? sourceContact;
  final ContactDisplayStateData? sourceState;

  const _DebugNode({
    required this.id,
    required this.name,
    required this.publicKey,
    required this.isSelf,
    required this.isDirect,
    required this.hopCount,
    required this.isRepeater,
    required this.isOutOfRange,
    required this.lastSeen,
    required this.sourceContact,
    required this.sourceState,
  });
}
