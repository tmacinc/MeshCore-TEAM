// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Re-implements MeshCore firmware's channel-message encryption
/// (`Utils::encrypt`, AES-128 in raw ECB mode, key = 16-byte channel
/// secret) so a message we already know the plaintext of (decoded for us
/// by firmware) can be re-encrypted and byte-matched against a raw
/// PUSH_LOG_RX_DATA packet's ciphertext -- an exact, unambiguous way to
/// find which raw reception(s) a decoded message came from, without
/// needing to decrypt anything ourselves.
///
/// Plaintext layout (over-the-air, before firmware repacks it for the
/// companion app's V3 message response): 4-byte little-endian timestamp,
/// 1 byte packing `attempt` (bits 0-1) and `txtType` (bits 2-7), then the
/// UTF-8 text. Encrypted in raw ECB blocks with no chaining; only the
/// trailing partial block is zero-padded -- an exact multiple of 16 bytes
/// gets no extra padding block, matching Utils::encrypt exactly.
Uint8List encryptChannelMessage({
  required Uint8List channelSecret,
  required int timestamp,
  required int attempt,
  required int txtType,
  required String text,
}) {
  final textBytes = utf8.encode(text);
  final plaintext = Uint8List(5 + textBytes.length);
  final byteData = ByteData.view(plaintext.buffer);
  byteData.setUint32(0, timestamp, Endian.little);
  plaintext[4] = (attempt & 0x03) | ((txtType & 0x3F) << 2);
  plaintext.setRange(5, plaintext.length, textBytes);

  final cipher = ECBBlockCipher(AESEngine())
    ..init(true, KeyParameter(channelSecret));

  final fullBlocks = plaintext.length ~/ 16;
  final remainder = plaintext.length % 16;
  final outLen = (fullBlocks + (remainder > 0 ? 1 : 0)) * 16;
  final out = Uint8List(outLen);

  for (var i = 0; i < fullBlocks; i++) {
    cipher.processBlock(plaintext, i * 16, out, i * 16);
  }
  if (remainder > 0) {
    final padded = Uint8List(16);
    padded.setRange(0, remainder, plaintext, fullBlocks * 16);
    cipher.processBlock(padded, 0, out, fullBlocks * 16);
  }

  return out;
}
