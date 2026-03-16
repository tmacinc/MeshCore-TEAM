// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

/// Peer capability advertisement message (`#CAP:`).
///
/// Wire format: `#CAP:<version>:<flags_hex>`
///   - version: decimal integer, currently `1`
///   - flags_hex: lower-case 2-char hex byte
///
/// Flag byte v1:
///   bit 0 (0x01): custom firmware
///   bit 1 (0x02): forwarding capable
///   bit 2 (0x04): autonomous capable
///   bit 3 (0x08): autonomous currently enabled
///   bit 4 (0x10): smart forwarding v2 currently active
///   bit 5–7: reserved, must be 0
///
/// Sent on the telemetry channel only. Never stored in chat.
/// Missing or stale (>12h) state is treated as stock firmware.
class CapabilityMessage {
  static const String prefix = '#CAP:';
  static const int currentVersion = 1;

  // Flag masks (v1)
  static const int flagCustomFirmware = 0x01;
  static const int flagForwardingCapable = 0x02;
  static const int flagAutonomousCapable = 0x04;
  static const int flagAutonomousEnabled = 0x08;
  static const int flagSmartForwardingActive = 0x10;

  final int version;
  final int flags;

  const CapabilityMessage({required this.version, required this.flags});

  // --- Flag accessors ---

  bool get isCustomFirmware => (flags & flagCustomFirmware) != 0;
  bool get supportsForwarding => (flags & flagForwardingCapable) != 0;
  bool get supportsAutonomous => (flags & flagAutonomousCapable) != 0;
  bool get autonomousEnabled => (flags & flagAutonomousEnabled) != 0;
  bool get smartForwardingActive => (flags & flagSmartForwardingActive) != 0;

  // --- Parse / build ---

  static bool isCapabilityMessage(String text) => text.startsWith(prefix);

  /// Returns null for any malformed input.
  static CapabilityMessage? parse(String text) {
    if (!text.startsWith(prefix)) return null;
    final body = text.substring(prefix.length);
    final parts = body.split(':');
    if (parts.length != 2) return null;

    final version = int.tryParse(parts[0]);
    if (version == null || version < 1) return null;

    final flags = int.tryParse(parts[1], radix: 16);
    if (flags == null) return null;

    return CapabilityMessage(version: version, flags: flags & 0xFF);
  }

  /// Build the wire string for this message.
  String encode() {
    final hex = (flags & 0xFF).toRadixString(16).padLeft(2, '0');
    return '$prefix$version:$hex';
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
  }) {
    int flags = flagCustomFirmware; // always set — this app requires custom fw
    if (supportsForwarding) flags |= flagForwardingCapable;
    if (supportsAutonomous) flags |= flagAutonomousCapable;
    if (autonomousEnabled) flags |= flagAutonomousEnabled;
    if (smartForwardingActive) flags |= flagSmartForwardingActive;
    return CapabilityMessage(version: currentVersion, flags: flags);
  }

  @override
  String toString() =>
      'CapabilityMessage(v$version flags=0x${flags.toRadixString(16).padLeft(2, "0")}'
      ' customFw=$isCustomFirmware fwd=$supportsForwarding auto=$supportsAutonomous'
      ' autoEnabled=$autonomousEnabled smartFwd=$smartForwardingActive)';
}
