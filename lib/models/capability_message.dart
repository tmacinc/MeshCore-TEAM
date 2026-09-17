// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:convert';

/// Peer capability advertisement message (`#CAP:`).
///
/// Wire formats:
///   v1: `#CAP:1:<flags_hex>`
///   v2: `#CAP:2:<flags_hex>:<radio_key_prefix>:<alias>`
///
///   - flags_hex: lower-case 2-char hex byte
///   - radio_key_prefix: first 6 bytes of the sender's radio public key as 12
///     lower-case hex chars, or `-` when the sender has no radio (Team Link)
///   - alias: the sender's team alias, UTF-8, may be empty, and is the last
///     field so it may contain `:`
///
/// The alias is why v2 exists: it binds a team name to a radio key for
/// everyone holding the channel key, without putting the name on every
/// telemetry packet.
///
/// Flag byte:
///   bit 0 (0x01): custom firmware
///   bit 1 (0x02): forwarding capable
///   bit 2 (0x04): autonomous capable
///   bit 3 (0x08): autonomous currently enabled
///   bit 4 (0x10): smart forwarding v2 currently active
///   bit 5–7: reserved, must be 0
///
/// Sent on the tracking channel only, never on a public or hashtag channel,
/// and never stored in chat. Missing or stale (>12h) capability state is
/// treated as stock firmware; an alias, once learned, is kept.
///
/// Older app versions require exactly two fields, so they drop v2 silently —
/// it is still intercepted by the `#CAP:` prefix and never shown as chat.
class CapabilityMessage {
  static const String prefix = '#CAP:';
  static const int currentVersion = 2;

  /// Alias limit on the wire. Bytes, not characters: emoji cost several.
  /// The firmware prepends "RadioName: " (up to 33 bytes) to every channel
  /// message, and MeshCore's text limit is about 160 bytes.
  static const int maxAliasBytes = 24;

  /// Placeholder key prefix for a sender with no radio (Team Link only).
  static const String noRadioKeyPrefix = '-';

  // Flag masks
  static const int flagCustomFirmware = 0x01;
  static const int flagForwardingCapable = 0x02;
  static const int flagAutonomousCapable = 0x04;
  static const int flagAutonomousEnabled = 0x08;
  static const int flagSmartForwardingActive = 0x10;

  final int version;
  final int flags;

  /// 12 lower-case hex chars, or null when the sender has no radio or sent v1.
  final String? radioKeyPrefix;

  /// Null for v1 (which carries no alias); empty means "no alias set".
  final String? alias;

  const CapabilityMessage({
    required this.version,
    required this.flags,
    this.radioKeyPrefix,
    this.alias,
  });

  // --- Flag accessors ---

  bool get isCustomFirmware => (flags & flagCustomFirmware) != 0;
  bool get supportsForwarding => (flags & flagForwardingCapable) != 0;
  bool get supportsAutonomous => (flags & flagAutonomousCapable) != 0;
  bool get autonomousEnabled => (flags & flagAutonomousEnabled) != 0;
  bool get smartForwardingActive => (flags & flagSmartForwardingActive) != 0;

  // --- Parse / build ---

  static bool isCapabilityMessage(String text) => text.startsWith(prefix);

  /// Returns null for any malformed input, and for an advert request
  /// (`#CAP:R:`), which [CapabilityRequest.parse] handles.
  static CapabilityMessage? parse(String text) {
    if (!text.startsWith(prefix)) return null;
    final body = text.substring(prefix.length);
    final parts = body.split(':');
    if (parts.length < 2) return null;

    final version = int.tryParse(parts[0]);
    if (version == null || version < 1) return null;

    final flags = int.tryParse(parts[1], radix: 16);
    if (flags == null) return null;

    if (parts.length == 2) {
      return CapabilityMessage(version: version, flags: flags & 0xFF);
    }

    final prefixField = parts[2].toLowerCase();
    final keyPrefix = RegExp(r'^[0-9a-f]{12}$').hasMatch(prefixField)
        ? prefixField
        : null;

    // The alias is last and may contain ':'. Anything after it belongs to a
    // newer version we don't know about, so it stays part of the alias only
    // if it was never separated — future fields go before the alias.
    final alias = parts.sublist(3).join(':');

    return CapabilityMessage(
      version: version,
      flags: flags & 0xFF,
      radioKeyPrefix: keyPrefix,
      alias: _sanitizeAlias(alias),
    );
  }

  /// Build the wire string for this message.
  String encode() {
    final hex = (flags & 0xFF).toRadixString(16).padLeft(2, '0');
    if (version < 2) return '$prefix$version:$hex';
    final keyPrefix = radioKeyPrefix ?? noRadioKeyPrefix;
    return '$prefix$version:$hex:$keyPrefix:${alias ?? ''}';
  }

  /// Build from current connected-firmware capability state.
  ///
  /// [supportsForwarding] and [supportsAutonomous] come from SELF_INFO.
  /// [autonomousEnabled] and [smartForwardingActive] come from app settings.
  factory CapabilityMessage.fromLocalState({
    bool supportsForwarding = false,
    bool supportsAutonomous = false,
    bool autonomousEnabled = false,
    bool smartForwardingActive = false,
    String? radioKeyPrefix,
    String? alias,
  }) {
    int flags = flagCustomFirmware; // always set — this app requires custom fw
    if (supportsForwarding) flags |= flagForwardingCapable;
    if (supportsAutonomous) flags |= flagAutonomousCapable;
    if (autonomousEnabled) flags |= flagAutonomousEnabled;
    if (smartForwardingActive) flags |= flagSmartForwardingActive;
    return CapabilityMessage(
      version: currentVersion,
      flags: flags,
      radioKeyPrefix: radioKeyPrefix?.toLowerCase(),
      alias: _sanitizeAlias(alias ?? ''),
    );
  }

  /// Trims an alias to something safe to send: no control characters, and at
  /// most [maxAliasBytes] UTF-8 bytes (cut on a character boundary).
  static String _sanitizeAlias(String alias) {
    final cleaned =
        alias.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
    if (utf8.encode(cleaned).length <= maxAliasBytes) return cleaned;

    final buffer = StringBuffer();
    var bytes = 0;
    for (final rune in cleaned.runes) {
      final char = String.fromCharCode(rune);
      final size = utf8.encode(char).length;
      if (bytes + size > maxAliasBytes) break;
      buffer.write(char);
      bytes += size;
    }
    return buffer.toString().trim();
  }

  @override
  String toString() =>
      'CapabilityMessage(v$version flags=0x${flags.toRadixString(16).padLeft(2, "0")}'
      ' customFw=$isCustomFirmware fwd=$supportsForwarding auto=$supportsAutonomous'
      ' autoEnabled=$autonomousEnabled smartFwd=$smartForwardingActive'
      ' keyPrefix=$radioKeyPrefix alias="$alias")';
}

/// Advert request (`#CAP:R:<key_prefix|->:<radio_name>`).
///
/// Asks one specific node to advertise itself. The self-advert we send on
/// hearing an unknown sender introduces *us*; this asks them to introduce
/// *themselves*, which is the only way to learn a key we don't have — a CAP
/// carries a key prefix, not the full key, and contacts must come from a
/// signed advert.
///
/// The radio name is last so it may contain `:`. Older app versions fail to
/// parse `R` as a version number and drop the message silently.
class CapabilityRequest {
  static const String prefix = '${CapabilityMessage.prefix}R:';

  /// 12 hex chars, or null when the requester has no key for the target
  /// (sent as `-`), which is also the case when the target switched radios.
  final String? targetKeyPrefix;

  final String targetRadioName;

  const CapabilityRequest({
    required this.targetRadioName,
    this.targetKeyPrefix,
  });

  static bool isRequest(String text) => text.startsWith(prefix);

  static CapabilityRequest? parse(String text) {
    if (!isRequest(text)) return null;
    final body = text.substring(prefix.length);
    final separator = body.indexOf(':');
    if (separator < 0) return null;

    final prefixField = body.substring(0, separator).toLowerCase();
    final name = body.substring(separator + 1).trim();
    if (name.isEmpty) return null;

    return CapabilityRequest(
      targetRadioName: name,
      targetKeyPrefix: RegExp(r'^[0-9a-f]{12}$').hasMatch(prefixField)
          ? prefixField
          : null,
    );
  }

  String encode() =>
      '$prefix${targetKeyPrefix ?? CapabilityMessage.noRadioKeyPrefix}:$targetRadioName';

  @override
  String toString() =>
      'CapabilityRequest(target="$targetRadioName" keyPrefix=$targetKeyPrefix)';
}
