// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:meshcore_team/database/daos/contacts_dao.dart';
import 'package:meshcore_team/database/daos/peers_dao.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/models/capability_message.dart';
import 'package:meshcore_team/services/settings_service.dart';

enum PeerResolutionState {
  /// The peer's key is a contact on the current radio.
  resolved,

  /// The peer's key is known, but the current radio doesn't have the contact
  /// (e.g. after a radio switch).
  knownNotOnRadio,

  /// Only the radio name is known so far (placeholder peer).
  unresolved,

  /// Several radios currently use this name; [PeerResolution.peer] is the
  /// best guess.
  ambiguous,
}

/// Result of recording a `#CAP:` message.
class CapabilityOutcome {
  final PeerData peer;

  /// True when this radio name now belongs to a different radio key than the
  /// one we had, i.e. they switched radios. Our self-advert doesn't help
  /// there, so the caller asks them to advertise instead.
  final bool keyMismatch;

  const CapabilityOutcome(this.peer, {required this.keyMismatch});
}

class PeerResolution {
  final PeerData peer;
  final PeerResolutionState state;

  /// The matching contact on the current radio, when there is one.
  final ContactData? contact;

  const PeerResolution(this.peer, this.state, this.contact);

  bool get isOnRadio => contact != null;
}

/// Translates wire identifiers (radio name, radio key, Link app identity) into
/// local peers, and peers back into names for display or transmission.
///
/// All peer writes go through here so the in-memory index stays current.
/// Lookups are synchronous against that index.
class PeerDirectory extends ChangeNotifier {
  final PeersDao _dao;
  final ContactsDao _contactsDao;
  final SettingsService _settings;

  final Map<int, PeerData> _byId = {};
  bool _loaded = false;

  // Serializes resolution so concurrent packets from a new sender can't
  // create duplicate placeholders.
  Future<void> _lock = Future.value();

  StreamSubscription<String?>? _companionSub;
  StreamSubscription<List<ContactData>>? _contactsSub;
  String? _activeCompanionKey;

  PeerDirectory({
    required PeersDao peersDao,
    required ContactsDao contactsDao,
    required SettingsService settings,
  })  : _dao = peersDao,
        _contactsDao = contactsDao,
        _settings = settings;

  Future<void> start() async {
    if (_loaded) return;
    for (final p in await _dao.getAllPeers()) {
      _byId[p.id] = p;
    }
    _loaded = true;
    _companionSub =
        _settings.currentCompanionPublicKeyStream.listen(_switchCompanion);
    _switchCompanion(_settings.settings.currentCompanionPublicKey);
    notifyListeners();
  }

  @override
  void dispose() {
    _companionSub?.cancel();
    _contactsSub?.cancel();
    super.dispose();
  }

  // --- Lookups ---

  Iterable<PeerData> get all => _byId.values;

  PeerData? byId(int? id) => id == null ? null : _byId[id];

  /// Matches a full 32-byte key, or a prefix of at least 6 bytes.
  PeerData? byRadioKey(List<int> key) {
    if (key.length < 6) return null;
    for (final p in _byId.values) {
      final k = p.radioPublicKey;
      if (k == null) continue;
      if (_startsWith(k, key)) return p;
    }
    return null;
  }

  PeerData? byAppId(String appId) {
    final id = appId.toLowerCase();
    for (final p in _byId.values) {
      if (p.appIdentityId == id) return p;
    }
    return null;
  }

  /// The single peer currently using [radioName], or null if none or several.
  PeerData? uniqueByRadioName(String radioName) {
    PeerData? found;
    for (final p in _byId.values) {
      if (p.radioName != radioName) continue;
      if (found != null) return null;
      found = p;
    }
    return found;
  }

  /// Name to show for [peer]: alias, then radio name, then a short key.
  String displayName(PeerData peer) {
    final alias = peer.alias?.trim();
    if (alias != null && alias.isNotEmpty) return alias;
    final name = peer.radioName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return shortId(peer);
  }

  /// Name to use in anything transmitted (mentions, replies). Never the alias.
  String? meshName(PeerData peer) => peer.radioName;

  String shortId(PeerData peer) {
    final key = peer.radioPublicKey;
    if (key != null) return _hex(key.take(4)).toUpperCase();
    final prefix = peer.radioKeyPrefix ?? peer.appIdentityId;
    if (prefix != null && prefix.length >= 8) {
      return prefix.substring(0, 8).toUpperCase();
    }
    return '#${peer.id}';
  }

  // --- Resolution ---

  /// Resolves the sender of a channel message, which is identified only by
  /// the radio name the firmware prepends.
  ///
  /// Matching is exact. Order: a contact on the current radio with that name,
  /// then a peer with a known key and that name, then a placeholder peer
  /// (created if needed). [isTeamChannel] marks the peer as a team member.
  Future<PeerResolution> resolveChannelSender({
    required String radioName,
    required List<ContactData> radioContacts,
    required int channelHash,
    required bool isTeamChannel,
  }) {
    return _serialized(() async {
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final onRadio =
          radioContacts.where((c) => (c.name ?? '') == radioName).toList();
      if (onRadio.isNotEmpty) {
        final contact = _pickContact(onRadio);
        final peer = await _peerForContact(contact, radioName, nowMs);
        final touched = await _touch(peer, radioName, nowMs,
            channelHash: channelHash, isTeamChannel: isTeamChannel);
        return PeerResolution(
          touched,
          onRadio.length > 1
              ? PeerResolutionState.ambiguous
              : PeerResolutionState.resolved,
          contact,
        );
      }

      final keyed = _byId.values
          .where((p) => p.radioName == radioName && p.radioPublicKey != null)
          .toList()
        ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
      if (keyed.isNotEmpty) {
        final touched = await _touch(keyed.first, radioName, nowMs,
            channelHash: channelHash, isTeamChannel: isTeamChannel);
        return PeerResolution(
          touched,
          keyed.length > 1
              ? PeerResolutionState.ambiguous
              : PeerResolutionState.knownNotOnRadio,
          null,
        );
      }

      var placeholder = _placeholderFor(radioName);
      placeholder ??= await _insert(PeersCompanion.insert(
        radioName: Value(radioName),
        firstSeen: nowMs,
        lastSeen: nowMs,
      ));
      final touched = await _touch(placeholder, radioName, nowMs,
          channelHash: channelHash, isTeamChannel: isTeamChannel);
      return PeerResolution(touched, PeerResolutionState.unresolved, null);
    });
  }

  /// The peer whose radio key starts with [keyPrefix] (12 hex chars).
  PeerData? byRadioKeyPrefix(String keyPrefix) {
    final wanted = keyPrefix.toLowerCase();
    for (final p in _byId.values) {
      final key = p.radioPublicKey;
      if (key != null) {
        if (_hex(key.take(6)) == wanted) return p;
      } else if (p.radioKeyPrefix == wanted) {
        return p;
      }
    }
    return null;
  }

  /// Stores what a `#CAP:` message says about its sender: capability flags,
  /// and from v2 the alias and radio key prefix.
  ///
  /// The key prefix is what makes CAP more than flags. It binds the alias to a
  /// radio rather than to a name, so it can merge two records that turn out to
  /// be one person, and it reveals when a known name is now a different radio.
  Future<CapabilityOutcome> recordCapability(
      PeerData peer, CapabilityMessage cap) {
    return _serialized(() async {
      var target = peer;
      var keyMismatch = false;
      final capPrefix = cap.radioKeyPrefix;

      if (capPrefix != null) {
        final byPrefix = byRadioKeyPrefix(capPrefix);
        if (byPrefix != null && byPrefix.id != target.id) {
          // Same person, two records: keep the one that has the radio key.
          final keep =
              byPrefix.radioPublicKey != null ? byPrefix : target;
          final drop = keep.id == byPrefix.id ? target : byPrefix;
          debugPrint(
              '[Peers] 🔀 Merging peer ${drop.id} into ${keep.id} (CAP key prefix)');
          target = await _merge(keep: keep, drop: drop);
        } else if (target.radioPublicKey != null) {
          keyMismatch = _hex(target.radioPublicKey!.take(6)) != capPrefix;
        } else if (target.radioKeyPrefix != capPrefix) {
          target = await _update(
              target.id, PeersCompanion(radioKeyPrefix: Value(capPrefix)));
        }
      }

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final alias = cap.alias?.trim();
      target = await _update(
        target.id,
        PeersCompanion(
          capFlags: Value(cap.flags),
          capObservedAt: Value(nowMs),
          // v1 carries no alias, so it must not clear one we already have.
          alias: alias == null
              ? const Value.absent()
              : Value(alias.isEmpty ? null : alias),
          aliasUpdatedAt:
              alias == null ? const Value.absent() : Value(nowMs),
        ),
      );

      return CapabilityOutcome(target, keyMismatch: keyMismatch);
    });
  }

  Future<PeerData> _merge(
      {required PeerData keep, required PeerData drop}) async {
    await _dao.mergePeers(keepId: keep.id, dropId: drop.id);
    _byId.remove(drop.id);
    final merged = (await _dao.getPeer(keep.id))!;
    _byId[keep.id] = merged;
    notifyListeners();
    return merged;
  }

  // --- Radio contact tracking ---

  void _switchCompanion(String? companionKey) {
    if (companionKey == _activeCompanionKey) return;
    _activeCompanionKey = companionKey;
    _contactsSub?.cancel();
    _contactsSub = null;
    if (companionKey == null || companionKey.isEmpty) return;
    _contactsSub = _contactsDao
        .watchContactsByCompanion(companionKey)
        .listen((contacts) => unawaited(_onRadioContacts(contacts)));
  }

  /// Keeps peers in step with the radio's contact list: follows renames of
  /// known keys, and binds a placeholder once an advert for its name arrives.
  Future<void> _onRadioContacts(List<ContactData> contacts) {
    return _serialized(() async {
      for (final contact in contacts) {
        final name = contact.name;
        if (name == null || name.isEmpty) continue;

        final known = byRadioKey(contact.publicKey);
        if (known != null) {
          if (known.radioName != name) {
            debugPrint(
                '[Peers] ✏️ Radio renamed: "${known.radioName}" → "$name"');
            await _update(known.id, PeersCompanion(radioName: Value(name)));
          }
          continue;
        }

        final placeholder = _placeholderFor(name);
        if (placeholder != null) {
          debugPrint('[Peers] 🔗 Bound "$name" to its radio key');
          await _update(placeholder.id, _keyFields(contact.publicKey));
        }
      }
    });
  }

  // --- Internals ---

  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _lock.then((_) => action());
    _lock = result.then((_) {}, onError: (_) {});
    return result;
  }

  ContactData _pickContact(List<ContactData> candidates) {
    if (candidates.length == 1) return candidates.first;
    // Several radios share the name: prefer the one we heard from most recently.
    candidates.sort((a, b) {
      final pa = byRadioKey(a.publicKey)?.lastSeen ?? 0;
      final pb = byRadioKey(b.publicKey)?.lastSeen ?? 0;
      return pb.compareTo(pa);
    });
    return candidates.first;
  }

  Future<PeerData> _peerForContact(
      ContactData contact, String radioName, int nowMs) async {
    final known = byRadioKey(contact.publicKey);
    if (known != null) return known;

    final placeholder = _placeholderFor(radioName);
    if (placeholder != null) {
      return _update(placeholder.id, _keyFields(contact.publicKey));
    }

    return _insert(PeersCompanion.insert(
      radioPublicKey: Value(contact.publicKey),
      radioKeyPrefix: Value(_hex(contact.publicKey.take(6))),
      radioName: Value(radioName),
      firstSeen: nowMs,
      lastSeen: nowMs,
    ));
  }

  /// A peer known only by [radioName]: no radio key and no app identity.
  PeerData? _placeholderFor(String radioName) {
    for (final p in _byId.values) {
      if (p.radioName == radioName &&
          p.radioPublicKey == null &&
          p.appIdentityId == null) {
        return p;
      }
    }
    return null;
  }

  PeersCompanion _keyFields(Uint8List key) => PeersCompanion(
        radioPublicKey: Value(key),
        radioKeyPrefix: Value(_hex(key.take(6))),
      );

  Future<PeerData> _touch(
    PeerData peer,
    String radioName,
    int nowMs, {
    required int channelHash,
    required bool isTeamChannel,
  }) {
    return _update(
      peer.id,
      PeersCompanion(
        radioName: Value(radioName),
        lastSeen: Value(nowMs),
        isTeamMember:
            isTeamChannel ? const Value(true) : const Value.absent(),
        lastTeamChannelHash:
            isTeamChannel ? Value(channelHash) : const Value.absent(),
      ),
    );
  }

  Future<PeerData> _insert(PeersCompanion peer) async {
    final id = await _dao.insertPeer(peer);
    final row = (await _dao.getPeer(id))!;
    _byId[id] = row;
    notifyListeners();
    return row;
  }

  Future<PeerData> _update(int id, PeersCompanion changes) async {
    await _dao.updatePeer(id, changes);
    final row = (await _dao.getPeer(id))!;
    final before = _byId[id];
    _byId[id] = row;
    // Most updates only move lastSeen; listeners care about identity.
    if (before == null || _identityChanged(before, row)) notifyListeners();
    return row;
  }

  static bool _identityChanged(PeerData a, PeerData b) {
    final ka = a.radioPublicKey;
    final kb = b.radioPublicKey;
    final keyChanged = (ka == null) != (kb == null) ||
        (ka != null && kb != null && !listEquals(ka, kb));
    return keyChanged ||
        a.radioName != b.radioName ||
        a.alias != b.alias ||
        a.appIdentityId != b.appIdentityId ||
        a.isTeamMember != b.isTeamMember;
  }

  static bool _startsWith(List<int> key, List<int> prefix) {
    if (prefix.length > key.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (key[i] != prefix[i]) return false;
    }
    return true;
  }

  static String _hex(Iterable<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
