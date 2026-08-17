// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

/// A parsed raw radio packet, sourced from a PUSH_LOG_RX_DATA (0x88) BLE
/// frame: `[0x88][snr int8][rssi int8][raw mesh packet]`. The raw packet
/// structure itself matches MeshCore's over-the-air format (see
/// docs/packet_format.md in the firmware repo):
/// `[header][transport_codes?][path_length][path][payload]`.
///
/// This is the data firmware's own decoded message responses (V3) never
/// expose: the actual per-hop path bytes and true RSSI, plus one entry per
/// physical reception rather than one per logical (deduped) message.
class RawPacketFrame {
  /// Raw int8 SNR value scaled by 4 (matches Messages.snr's encoding from
  /// the V3 message responses -- same firmware-side scaling, no conversion
  /// needed to compare the two).
  final int snr;

  /// Raw RSSI in dBm.
  final int rssi;

  final int routeType;
  final int payloadType;
  final int payloadVersion;

  /// Raw wire path_length byte (hash-size mode packed with hop count).
  final int pathByte;

  /// Raw hop-hash bytes, hop_count * hash_size long.
  final Uint8List pathBytes;

  /// Remaining packet bytes after path -- ciphertext for TXT_MSG/GRP_TXT.
  final Uint8List payload;

  /// SHA-256(payload_type byte + payload bytes)[:16 hex, uppercase] --
  /// matches MeshCore firmware's Packet::calculatePacketHash(). Identical
  /// across flood-relayed copies of the same logical packet regardless of
  /// path, since it excludes routing/path bytes entirely.
  final String packetHash;

  final int receivedAtMs;

  RawPacketFrame({
    required this.snr,
    required this.rssi,
    required this.routeType,
    required this.payloadType,
    required this.payloadVersion,
    required this.pathByte,
    required this.pathBytes,
    required this.payload,
    required this.packetHash,
    required this.receivedAtMs,
  });
}

/// Payload type of a text/channel-text packet, per docs/packet_format.md.
const int payloadTypeTxtMsg = 0x02;
const int payloadTypeGrpTxt = 0x05;

/// Parses a PUSH_LOG_RX_DATA (0x88) BLE frame into a [RawPacketFrame].
/// Returns null for malformed/too-short frames.
RawPacketFrame? parseRawPacketLogFrame(Uint8List frame, {DateTime? now}) {
  // frame[0] is the 0x88 push code itself (caller strips or includes it --
  // this function expects it included, matching the raw BLE payload).
  // Minimum viable length: code + snr + rssi + header + path_byte.
  if (frame.length < 5) return null;

  final snr = frame[1].toSigned(8);
  final rssi = frame[2].toSigned(8);
  final packet = frame.sublist(3);

  return parseRawMeshPacket(packet, snr: snr, rssi: rssi, now: now);
}

/// Parses the raw mesh packet bytes (without the 0x88/snr/rssi BLE prefix).
/// Exposed separately so it can be unit-tested against known packet bytes.
RawPacketFrame? parseRawMeshPacket(
  Uint8List packet, {
  required int snr,
  required int rssi,
  DateTime? now,
}) {
  if (packet.length < 2) return null;

  var offset = 0;
  final header = packet[offset++];
  final routeType = header & 0x03;
  final payloadType = (header >> 2) & 0x0F;
  final payloadVersion = (header >> 6) & 0x03;

  // ROUTE_TYPE_TRANSPORT_FLOOD (0x00) and ROUTE_TYPE_TRANSPORT_DIRECT (0x03)
  // carry 4 bytes of transport codes before the path byte.
  if (routeType == 0x00 || routeType == 0x03) {
    if (packet.length < offset + 4) return null;
    offset += 4;
  }

  if (packet.length < offset + 1) return null;
  final pathByte = packet[offset++];
  final hashSize = ((pathByte & 0xC0) >> 6) + 1;
  final hopCount = pathByte & 0x3F;
  final pathByteLen = hopCount * hashSize;

  if (packet.length < offset + pathByteLen) return null;
  final pathBytes = packet.sublist(offset, offset + pathByteLen);
  offset += pathByteLen;

  final payload = packet.sublist(offset);

  final hashInput = Uint8List(1 + payload.length)
    ..[0] = payloadType
    ..setRange(1, 1 + payload.length, payload);
  final packetHash = crypto.sha256
      .convert(hashInput)
      .toString()
      .substring(0, 16)
      .toUpperCase();

  return RawPacketFrame(
    snr: snr,
    rssi: rssi,
    routeType: routeType,
    payloadType: payloadType,
    payloadVersion: payloadVersion,
    pathByte: pathByte,
    pathBytes: pathBytes,
    payload: payload,
    packetHash: packetHash,
    receivedAtMs: (now ?? DateTime.now()).millisecondsSinceEpoch,
  );
}

/// Short-lived buffer of recently-seen raw packets, used to correlate a
/// decoded chat message (arriving via the normal, separate sync path) back
/// to the raw reception(s) it came from. Bounded by both age and count so
/// it can't grow unbounded on a busy channel.
class RawPacketLog {
  static const Duration _maxAge = Duration(seconds: 60);
  static const int _maxEntries = 200;

  final List<RawPacketFrame> _frames = [];

  void add(RawPacketFrame frame) {
    _frames.add(frame);
    _prune();
  }

  /// All buffered frames matching [packetHash], oldest first.
  List<RawPacketFrame> byPacketHash(String packetHash) {
    _prune();
    return _frames.where((f) => f.packetHash == packetHash).toList();
  }

  /// All buffered frames of a given payload type, for brute-force matching
  /// against a known plaintext (caller re-encrypts and compares payload
  /// bytes directly rather than relying on this method to filter by hash).
  List<RawPacketFrame> byPayloadType(int payloadType) {
    _prune();
    return _frames.where((f) => f.payloadType == payloadType).toList();
  }

  void _prune() {
    final cutoff = DateTime.now().subtract(_maxAge).millisecondsSinceEpoch;
    _frames.removeWhere((f) => f.receivedAtMs < cutoff);
    if (_frames.length > _maxEntries) {
      _frames.removeRange(0, _frames.length - _maxEntries);
    }
  }
}
