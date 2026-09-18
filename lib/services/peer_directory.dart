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
  ///
  /// Display only. Two people may pick the same alias and are both shown
  /// under it: everything that identifies them (map markers, message
  /// senders, contacts) keys on the peer or its radio key, never the name,
  /// so they stay separate. Telling them apart is up to the group.
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

      // Someone who told us they moved radios but keeps the name: their old
      // radio's contact is still here under that name. Only the radio they
      // named counts as them.
      final movedTo = _keylessFor(radioName)?.radioKeyPrefix;
      final onRadio = radioContacts
          .where((c) =>
              (c.name ?? '') == radioName &&
              (movedTo == null || _hex(c.publicKey.take(6)) == movedTo))
          .toList();
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

      var placeholder = _keylessFor(radioName);
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
      var target = _byId[peer.id] ?? peer;
      var keyMismatch = false;
      final capPrefix = cap.radioKeyPrefix;

      if (cap.appId != null) {
        final claim = await _claimForApp(target, cap.appId!, capPrefix);
        target = claim.peer;
        // They moved to a radio we hold no key for: ask it to advertise.
        keyMismatch = claim.droppedKey;
      }

      if (capPrefix != null) {
        final byPrefix = byRadioKeyPrefix(capPrefix);
        if (byPrefix != null && byPrefix.id != target.id) {
          if (_differentApps(byPrefix, target)) {
            // The radio changed hands; its previous user is still a person.
            target = await _takeRadio(from: byPrefix, to: target);
          } else {
            // Same person, two records: keep the one that has the radio key.
            final keep =
                byPrefix.radioPublicKey != null ? byPrefix : target;
            final drop = keep.id == byPrefix.id ? target : byPrefix;
            debugPrint(
                '[Peers] 🔀 Merging peer ${drop.id} into ${keep.id} (CAP key prefix)');
            target = await _merge(keep: keep, drop: drop);
          }
        } else if (target.radioPublicKey != null) {
          keyMismatch = keyMismatch ||
              _hex(target.radioPublicKey!.take(6)) != capPrefix;
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

  /// Makes the peer for [appId] the sender of a message that arrived as
  /// [sender], who was resolved from the radio name alone.
  ///
  /// A peer is a person, which on the mesh means an app install; the radio is
  /// something they carry. So when an install we know turns up on another
  /// radio, their peer moves to it and keeps its alias, history and last
  /// position, rather than a second person appearing under the new radio.
  Future<({PeerData peer, bool droppedKey})> _claimForApp(
      PeerData sender, String appId, String? capPrefix) async {
    final claimed = await _claim(sender, appId);
    // The message names the radio it came from. A key we hold for any other
    // radio is out of date: forget it, and the next advert binds the new one.
    if (capPrefix == null) return (peer: claimed, droppedKey: false);
    final key = claimed.radioPublicKey;
    final current = key != null ? _hex(key.take(6)) : claimed.radioKeyPrefix;
    if (current == capPrefix) return (peer: claimed, droppedKey: false);
    final moved = await _update(
        claimed.id,
        PeersCompanion(
          radioPublicKey: const Value(null),
          radioKeyPrefix: Value(capPrefix),
        ));
    return (peer: moved, droppedKey: key != null);
  }

  Future<PeerData> _claim(PeerData sender, String appId) async {
    final owner = byAppId(appId);

    if (owner == null) {
      if (sender.appIdentityId == null) {
        return _update(
            sender.id, PeersCompanion(appIdentityId: Value(appId)));
      }
      // Someone else's radio, now used by an install we haven't met: a new
      // person. The radio's previous user keeps their history without it.
      debugPrint(
          '[Peers] 📻 "${sender.radioName}" is now used by someone new');
      final newcomer = await _insert(PeersCompanion.insert(
        appIdentityId: Value(appId),
        radioName: Value(sender.radioName),
        isTeamMember: Value(sender.isTeamMember),
        lastTeamChannelHash: Value(sender.lastTeamChannelHash),
        firstSeen: sender.lastSeen,
        lastSeen: sender.lastSeen,
      ));
      return _takeRadio(from: sender, to: newcomer);
    }

    if (owner.id == sender.id) return owner;

    debugPrint(
        '[Peers] 📻 ${displayName(owner)} is now on "${sender.radioName}"');
    if (sender.appIdentityId == null) {
      // A placeholder or key-only record for their new radio: it is them.
      return _merge(keep: owner, drop: sender);
    }
    return _takeRadio(from: sender, to: owner);
  }

  /// Moves [from]'s radio (key, prefix and name) to [to]. [from] stays as a
  /// person with no radio, keeping their history and last position.
  Future<PeerData> _takeRadio(
      {required PeerData from, required PeerData to}) async {
    // Cleared first: a radio key belongs to one peer at a time.
    await _update(
        from.id,
        const PeersCompanion(
          radioPublicKey: Value(null),
          radioKeyPrefix: Value(null),
        ));
    return _update(
        to.id,
        PeersCompanion(
          radioPublicKey: Value(from.radioPublicKey),
          radioKeyPrefix: Value(from.radioKeyPrefix),
          radioName: Value(_newerName(from, to)),
          isTeamMember: Value(from.isTeamMember || to.isTeamMember),
          lastTeamChannelHash:
              Value(from.lastTeamChannelHash ?? to.lastTeamChannelHash),
          lastSeen: Value(
              from.lastSeen > to.lastSeen ? from.lastSeen : to.lastSeen),
        ));
  }

  /// The radio name of whichever of [a] and [b] was heard most recently.
  static String? _newerName(PeerData a, PeerData b) {
    final newer = a.lastSeen >= b.lastSeen ? a : b;
    return newer.radioName ?? (identical(newer, a) ? b : a).radioName;
  }

  static bool _differentApps(PeerData a, PeerData b) =>
      a.appIdentityId != null &&
      b.appIdentityId != null &&
      a.appIdentityId != b.appIdentityId;

  /// Folds [drop] into [keep]: history, messages and last position move
  /// over. [drop]'s radio replaces [keep]'s when it has one, since the merge
  /// happens because this person was just heard on it; anything else [keep]
  /// is missing is filled in from [drop].
  Future<PeerData> _merge(
      {required PeerData keep, required PeerData drop}) async {
    await _dao.mergePeers(keepId: keep.id, dropId: drop.id);
    _byId.remove(drop.id);

    final dropHasRadio =
        drop.radioPublicKey != null || drop.radioKeyPrefix != null;
    // Only the key prefix is known for drop's radio; keep's full key is
    // still right if it is that same radio.
    final keepKeyStillRight = drop.radioPublicKey == null &&
        keep.radioPublicKey != null &&
        _hex(keep.radioPublicKey!.take(6)) == drop.radioKeyPrefix;
    final takeRadio = dropHasRadio && !keepKeyStillRight;
    final merged = await _update(
      keep.id,
      PeersCompanion(
        radioPublicKey:
            takeRadio ? Value(drop.radioPublicKey) : const Value.absent(),
        radioKeyPrefix:
            takeRadio ? Value(drop.radioKeyPrefix) : const Value.absent(),
        radioName: Value(_newerName(drop, keep)),
        appIdentityId: keep.appIdentityId == null
            ? Value(drop.appIdentityId)
            : const Value.absent(),
        alias: keep.alias == null ? Value(drop.alias) : const Value.absent(),
        isTeamMember: drop.isTeamMember && !keep.isTeamMember
            ? const Value(true)
            : const Value.absent(),
        lastSeen: drop.lastSeen > keep.lastSeen
            ? Value(drop.lastSeen)
            : const Value.absent(),
      ),
    );
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
    unawaited(_releaseOwnRadio(companionKey));
    _contactsSub = _contactsDao
        .watchContactsByCompanion(companionKey)
        .listen((contacts) => unawaited(_onRadioContacts(contacts)));
  }

  /// A teammate's old radio can be the one this phone just connected to.
  /// It is ours now: they keep their history and last position, without it.
  Future<void> _releaseOwnRadio(String companionKey) {
    return _serialized(() async {
      final wanted = companionKey.toLowerCase();
      for (final p in _byId.values.toList()) {
        final key = p.radioPublicKey;
        if (key == null || _hex(key) != wanted) continue;
        debugPrint(
            '[Peers] 📻 ${displayName(p)} was using this radio; kept without it');
        await _update(
            p.id,
            const PeersCompanion(
              radioPublicKey: Value(null),
              radioKeyPrefix: Value(null),
            ));
      }
    });
  }

  /// Runs the radio-contact sync directly; the app drives it from the
  /// contact list stream instead.
  @visibleForTesting
  Future<void> syncWithRadioContactsForTest(List<ContactData> contacts) =>
      _onRadioContacts(contacts);

  /// Keeps peers in step with the radio's contact list: follows renames of
  /// known keys, and binds a placeholder once an advert for its name arrives.
  Future<void> _onRadioContacts(List<ContactData> contacts) {
    return _serialized(() async {
      for (final contact in contacts) {
        final name = contact.name;
        if (name == null || name.isEmpty) continue;

        final known = byRadioKey(contact.publicKey);
        if (known != null) {
          var current = known;
          if (known.radioName != name) {
            debugPrint(
                '[Peers] ✏️ Radio renamed: "${known.radioName}" → "$name"');
            current = await _update(
                known.id, PeersCompanion(radioName: Value(name)));
          }
          // Positions heard under the new name before this advert arrived
          // created a placeholder for it. It is this same radio: fold it in,
          // or it lingers on the map as a second, stale person.
          final placeholder = _keylessFor(name, key: contact.publicKey);
          if (placeholder != null &&
              placeholder.id != current.id &&
              !_differentApps(placeholder, current)) {
            debugPrint(
                '[Peers] 🔀 Merging placeholder "$name" into its renamed radio');
            await _merge(keep: current, drop: placeholder);
          }
          continue;
        }

        final placeholder = _keylessFor(name, key: contact.publicKey);
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

    final placeholder = _keylessFor(radioName, key: contact.publicKey);
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

  /// The peer waiting for a radio key under [radioName]: a placeholder known
  /// only by that name, or someone who told us (via `#CAP:`) they moved to a
  /// radio of that name before its advert reached us.
  ///
  /// Given [key], a peer that already knows its radio's key prefix only
  /// matches that radio. A Link-only peer (app identity, no radio) never
  /// matches: a shared name is no reason to give them one.
  PeerData? _keylessFor(String radioName, {List<int>? key}) {
    PeerData? best;
    for (final p in _byId.values) {
      if (p.radioName != radioName || p.radioPublicKey != null) continue;
      if (p.appIdentityId != null && p.radioKeyPrefix == null) continue;
      if (key != null &&
          p.radioKeyPrefix != null &&
          p.radioKeyPrefix != _hex(key.take(6))) {
        continue;
      }
      if (best == null || p.lastSeen > best.lastSeen) best = p;
    }
    return best;
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
    if (before == null || _identityChanged(before, row)) {
        notifyListeners();
    }
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
