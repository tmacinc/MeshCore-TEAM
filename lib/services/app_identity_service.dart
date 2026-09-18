// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// App-wide cryptographic identity: an Ed25519 keypair generated once per
/// install, with the private key seed kept in platform secure storage
/// (Android Keystore-backed prefs / iOS Keychain). It never leaves the
/// device and there is no shared secret anywhere in the app or repo.
///
/// Used today to sign Team Link relay requests; designed to also sign
/// future group-visible claims (e.g. mesh-anonymity alias announcements),
/// so it deliberately lives outside cloud_sync/.
class AppIdentityService {
  static const _storageKey = 'app_identity_ed25519_seed';

  final FlutterSecureStorage _storage;
  final _ed = Ed25519();

  SimpleKeyPair? _keyPair;
  Uint8List? _publicKeyBytes;

  AppIdentityService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  /// Load the keypair, generating and persisting one on first use.
  Future<void> ensureInitialized() async {
    if (_keyPair != null) return;
    final storedSeed = await _storage.read(key: _storageKey);
    if (storedSeed != null) {
      _keyPair = await _ed.newKeyPairFromSeed(base64.decode(storedSeed));
    } else {
      final keyPair = await _ed.newKeyPair();
      final seed = await keyPair.extractPrivateKeyBytes();
      await _storage.write(key: _storageKey, value: base64.encode(seed));
      _keyPair = keyPair;
    }
    final pub = await _keyPair!.extractPublicKey();
    _publicKeyBytes = Uint8List.fromList(pub.bytes);
  }

  /// Base64 Ed25519 public key — the client identity sent to the server.
  String get publicKeyB64 {
    _requireInit();
    return base64.encode(_publicKeyBytes!);
  }

  /// First 8 bytes of SHA256(public key) — embedded in envelope headers.
  Uint8List get uploaderId {
    _requireInit();
    return Uint8List.fromList(
        crypto.sha256.convert(_publicKeyBytes!).bytes.sublist(0, 8));
  }

  /// Sign an arbitrary string; returns base64 signature.
  Future<String> sign(String message) async {
    _requireInit();
    final sig = await _ed.sign(utf8.encode(message), keyPair: _keyPair!);
    return base64.encode(sig.bytes);
  }

  /// Durable user handle: hex SHA256 of the radio's 32-byte public key.
  /// Hashes the key (not the advertised name), so it stays stable even if
  /// the radio's mesh name is randomized for anonymity later.
  static String radioHashFromCompanionHex(String companionPublicKeyHex) {
    final bytes = Uint8List(companionPublicKeyHex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] =
          int.parse(companionPublicKeyHex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return crypto.sha256.convert(bytes).toString();
  }

  /// Fallback user handle for phones with no radio at all (local-only
  /// channels): hex SHA256 of this install's own app identity, in place of a
  /// radio public key. Safe under the existing trust model — the server
  /// treats this handle purely as an informational label, never an access
  /// boundary (the group HMAC is the real gate) — so substituting the app's
  /// own identity here doesn't change what the server can verify or enforce.
  String get selfRadioHashFallback {
    _requireInit();
    return crypto.sha256.convert(_publicKeyBytes!).toString();
  }

  void _requireInit() {
    if (_keyPair == null) {
      throw StateError('AppIdentityService not initialized');
    }
  }
}
