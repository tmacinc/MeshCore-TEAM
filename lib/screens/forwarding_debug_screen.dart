// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/database/daos/peers_dao.dart';
import 'package:meshcore_team/models/team_map_visibility.dart';
import 'package:meshcore_team/services/peer_directory.dart';
import '../l10n/app_localizations.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/services/forwarding_policy_service.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';
import 'package:meshcore_team/widgets/themed_dropdown.dart';
import 'package:provider/provider.dart';

class ForwardingDebugScreen extends StatefulWidget {
  const ForwardingDebugScreen({super.key});

  @override
  State<ForwardingDebugScreen> createState() => _ForwardingDebugScreenState();
}

class _ForwardingDebugScreenState extends State<ForwardingDebugScreen> {
  String? _selectedNodeId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
    final locationsStream = db.peersDao.watchPeersWithLocation();
    final peers = context.watch<PeerDirectory>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.forwardingDebug),
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
              return StreamBuilder<List<PeerWithLocation>>(
                stream: locationsStream,
                builder: (context, statesSnapshot) {
                  final allStates =
                      statesSnapshot.data ?? const <PeerWithLocation>[];
                  final visibleTrackedStates = _filterMapVisibleTrackedStates(
                    allStates,
                    trackingChannelHash:
                        parseTrackingChannelHash(settings.telemetryChannelHash),
                  );

                  final nodes = _buildNodes(
                    connectionVM,
                    peers,
                    visibleTrackedStates,
                    allContacts,
                  );

                  final selectedNode = _resolveSelected(nodes);
                  final furthestHop = _furthestHop(visibleTrackedStates);
                  final fwdL10n = AppLocalizations.of(context)!;
                  final summarySuffix = trackingChannelIndex == null
                      ? fwdL10n.trackingChannelNotConfigured
                      : fwdL10n.trackingChannelIndex(trackingChannelIndex.toString(), visibleTrackedStates.length);

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

  List<PeerWithLocation> _filterMapVisibleTrackedStates(
    List<PeerWithLocation> members, {
    required int? trackingChannelHash,
  }) {
    if (trackingChannelHash == null) return const <PeerWithLocation>[];

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return members
        .where((m) => isVisibleOnTeamMap(
              m.location,
              trackingChannelHash: trackingChannelHash,
              nowMs: nowMs,
            ))
        .toList(growable: false);
  }

  List<_DebugNode> _buildNodes(
    ConnectionViewModel connectionVM,
    PeerDirectory peers,
    List<PeerWithLocation> visibleMembers,
    List<ContactData> contacts,
  ) {
    final selfInfo = connectionVM.deviceCapabilities;
    final selfKey = selfInfo?.publicKey;

    final contactByHex = <String, ContactData>{
      for (final contact in contacts) _hex(contact.publicKey): contact,
    };

    ContactData? contactFor(PeerWithLocation m) {
      final key = m.peer.radioPublicKey;
      return key == null ? null : contactByHex[_hex(key)];
    }

    final otherMembers = visibleMembers.where((m) {
      final contact = contactFor(m);
      if (contact == null) return false;
      if (selfKey == null || selfKey.isEmpty) return true;
      return !_sameBytes(contact.publicKey, selfKey);
    }).toList()
      ..sort((left, right) {
        final l = left.location;
        final r = right.location;
        final leftHop = l.lastPathLen < 0 ? 999 : l.lastPathLen;
        final rightHop = r.lastPathLen < 0 ? 999 : r.lastPathLen;
        if (leftHop != rightHop) return leftHop.compareTo(rightHop);
        return r.lastSeen.compareTo(l.lastSeen);
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
      ...otherMembers.map(
        (m) {
          final contact = contactFor(m)!;
          final state = m.location;

          return _DebugNode(
            id: 'peer_${m.peer.id}',
            name: peers.displayName(m.peer),
            publicKey: contact.publicKey,
            isSelf: false,
            isDirect: contact.isDirect,
            hopCount: state.lastPathLen,
            isRepeater: contact.isRepeater,
            isOutOfRange: contact.isOutOfRange,
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

  int _furthestHop(List<PeerWithLocation> members) {
    var maxHop = -1;
    for (final m in members) {
      if (m.location.lastPathLen >= 0) {
        maxHop = max(maxHop, m.location.lastPathLen);
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
    final l10n = AppLocalizations.of(context)!;
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
            ThemedDropdown<String>(
              value: selectedAlgorithmMode,
              decoration: InputDecoration(
                labelText: l10n.forwardingAlgorithmDebug,
                isDense: true,
              ),
              items: [
                DropdownMenuItem(
                  value: ForwardingAlgorithmMode.forwardingV1,
                  child: Text(l10n.forwardingV1Tel),
                ),
                DropdownMenuItem(
                  value: ForwardingAlgorithmMode.topology,
                  child: Text(l10n.topologyT),
                ),
                DropdownMenuItem(
                  value: ForwardingAlgorithmMode.auto,
                  child: Text(l10n.autoPreferTopology),
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
    final l10n = AppLocalizations.of(context)!;
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
            Text(l10n.forwardingPublicKey(_hex(selectedNode.publicKey, byteCount: 8))),
            Text(l10n.hopCountLabel(_hopLabel(selectedNode.hopCount))),
            Text(l10n.forwardingDirect(selectedNode.isDirect ? 'yes' : 'no')),
            Text(l10n.forwardingRepeater(selectedNode.isRepeater ? 'yes' : 'no')),
            Text(l10n.forwardingOutOfRange(selectedNode.isOutOfRange ? 'yes' : 'no')),
            Text(l10n.lastSeen(_timeLabel(selectedNode.lastSeen))),
            if (selectedNode.sourceState != null) ...[
              Text(
                  'Telemetry channel hash: ${selectedNode.sourceState!.lastChannelHash.toRadixString(16)}'),
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
              Text(l10n.forwardingMode(forwarding.forwardingMode.toString())),
              Text(
                  'Policy engine active: ${forwarding.isPolicyEngineActive ? 'yes' : 'no'}'),
              Text(l10n.forwardingLastMaxHops((forwarding.lastAppliedMaxHops ?? 'n/a').toString())),
              Text(
                  'Last forward list size: ${forwarding.lastAppliedPrefixCount}'),
              Text(l10n.forwardingLastTrigger((forwarding.lastAppliedTrigger ?? 'n/a').toString())),
              Text(l10n.forwardingLastApplied(_timeLabel(forwarding.lastAppliedAt))),
              Text(l10n.forwardingLastError(forwarding.lastPolicyError ?? 'none')),
            ] else ...[
              Text(
                  'Forwarding candidate: ${_isForwardingCandidate(selectedNode) ? 'yes' : 'no'}'),
              Text(l10n.forwardingCandidateReason(_candidateReason(selectedNode))),
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
  final PeerLocationData? sourceState;

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
