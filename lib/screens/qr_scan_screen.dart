// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/app_localizations.dart';

class QrScanScreen extends StatefulWidget {
  /// Screen title, or null to use the localized default.
  ///
  /// Nullable rather than defaulted because a `const` default cannot read
  /// localizations — the fallback has to happen where there is a context.
  final String? title;

  const QrScanScreen({
    super.key,
    this.title,
  });

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.title ?? AppLocalizations.of(context)!.scanQrCode),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_handled) return;
          for (final barcode in capture.barcodes) {
            final raw = barcode.rawValue;
            if (raw != null && raw.isNotEmpty) {
              _handled = true;
              Navigator.of(context).pop(raw);
              return;
            }
          }
        },
      ),
    );
  }
}
