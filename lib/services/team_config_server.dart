// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// A lightweight local HTTP server that serves a `.teamcfg.zip` file for
/// offline config sharing. The sender hosts this on a hotspot/Wi-Fi network
/// and displays a QR code with the download URL.
class TeamConfigServer {
  HttpServer? _server;
  Uint8List? _zipBytes;
  String? _fileName;
  int _downloadCount = 0;

  /// Whether the server is currently running.
  bool get isRunning => _server != null;

  /// The port the server is listening on.
  int? get port => _server?.port;

  /// Number of times the config has been downloaded.
  int get downloadCount => _downloadCount;

  /// Start the server on an available port, serving the given ZIP bytes.
  ///
  /// Returns the URL that clients should use to download the config.
  /// The caller is responsible for determining the device IP and building
  /// the full URL for the QR code.
  Future<int> start({
    required Uint8List zipBytes,
    required String fileName,
  }) async {
    if (_server != null) {
      await stop();
    }

    _zipBytes = zipBytes;
    _fileName = fileName;
    _downloadCount = 0;

    final handler =
        const Pipeline().addMiddleware(_corsMiddleware()).addHandler(_router);

    // Bind to all interfaces so hotspot clients can reach us.
    _server = await shelf_io.serve(
      handler,
      InternetAddress.anyIPv4,
      0, // Let the OS pick an available port.
    );

    return _server!.port;
  }

  /// Stop the server and free resources.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _zipBytes = null;
    _fileName = null;
  }

  Response _router(Request request) {
    final path = request.url.path;

    if (path == '' || path == '/') {
      // Simple landing page with download link.
      return Response.ok(
        '<html><body style="font-family:sans-serif;text-align:center;padding:40px">'
        '<h2>MeshCore TEAM Config</h2>'
        '<p>${_fileName ?? 'team_config.teamcfg.zip'}</p>'
        '<a href="/download" style="font-size:1.2em">Download Config</a>'
        '</body></html>',
        headers: {'content-type': 'text/html'},
      );
    }

    if (path == 'download') {
      if (_zipBytes == null) {
        return Response.notFound('No config available');
      }
      _downloadCount++;
      final safeName = _fileName ?? 'team_config.teamcfg.zip';
      return Response.ok(
        _zipBytes!,
        headers: {
          'content-type': 'application/zip',
          'content-disposition': 'attachment; filename="$safeName"',
          'content-length': '${_zipBytes!.length}',
        },
      );
    }

    return Response.notFound('Not found');
  }

  /// CORS middleware to allow browser-based downloads from any origin.
  static Middleware _corsMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok(
            '',
            headers: _corsHeaders,
          );
        }
        final response = await innerHandler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  /// Get the device's local IP address on the Wi-Fi/hotspot interface.
  ///
  /// Returns the first non-loopback IPv4 address found, preferring
  /// wlan/Wi-Fi interfaces.
  static Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      // Prefer wlan/Wi-Fi/ap interfaces (common for hotspot).
      for (final iface in interfaces) {
        final name = iface.name.toLowerCase();
        if (name.contains('wlan') ||
            name.contains('wi-fi') ||
            name.contains('ap') ||
            name.contains('swlan') ||
            name.contains('hotspot')) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback) return addr.address;
          }
        }
      }

      // Fall back to any non-loopback IPv4 address.
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }
}
