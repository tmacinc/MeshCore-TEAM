// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:typed_data';

/// Decodes a raw wire path_length byte into (hopCount, hashSize), per
/// docs/packet_format.md: bits 0-5 are hop count, bits 6-7 are hash-size
/// mode (hashSize = mode + 1, so 1/2/3 bytes per hop; mode 3 is reserved).
({int hopCount, int hashSize}) decodePathByte(int pathByte) {
  final hopCount = pathByte & 0x3F;
  final hashSize = ((pathByte & 0xC0) >> 6) + 1;
  return (hopCount: hopCount, hashSize: hashSize);
}

/// Splits raw path bytes into per-hop identifier chunks, using the hop
/// count/hash size encoded in [pathByte]. Falls back to 1-byte chunks if
/// the byte counts don't line up (shouldn't happen for well-formed data,
/// but keeps this robust against unexpected input).
List<Uint8List> splitPathHops(int pathByte, Uint8List pathBytes) {
  final decoded = decodePathByte(pathByte);
  if (decoded.hopCount == 0 || pathBytes.isEmpty) return const [];

  final expectedLen = decoded.hopCount * decoded.hashSize;
  final hashSize = expectedLen == pathBytes.length ? decoded.hashSize : 1;

  final hops = <Uint8List>[];
  for (var i = 0; i + hashSize <= pathBytes.length; i += hashSize) {
    hops.add(pathBytes.sublist(i, i + hashSize));
  }
  return hops;
}

/// Formats a hop count for display: "Direct" for 0, "N hop(s)" otherwise.
/// Callers needing localized text should use AppLocalizations directly;
/// this is for the compact non-localized summary badge only (see
/// formatHopCountsBadge).
String hopCountBadgeToken(int hopCount) => hopCount == 0 ? 'd' : '$hopCount';

/// Compact multi-path summary badge, e.g. "d/1" for a message heard both
/// directly and via one relay hop. Mirrors the reference client's
/// formatHopCounts: sorted ascending, direct shown as "d".
String formatHopCountsBadge(List<int> hopCounts) {
  if (hopCounts.isEmpty) return '';
  final sorted = [...hopCounts]..sort();
  return sorted.map(hopCountBadgeToken).join('/');
}
