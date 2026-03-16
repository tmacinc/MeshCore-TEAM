// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/repositories/channel_repository.dart';

class DeepLinkListener extends StatefulWidget {
  final Widget child;

  const DeepLinkListener({
    super.key,
    required this.child,
  });

  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        unawaited(_handleUri(initial));
      }
    } catch (_) {
      // Best-effort
    }

    _sub = _appLinks.uriLinkStream.listen((uri) {
      unawaited(_handleUri(uri));
    });
  }

  bool _isChannelAddUri(Uri uri) {
    return uri.scheme == 'meshcore' &&
        uri.host == 'channel' &&
        uri.pathSegments.length == 1 &&
        uri.pathSegments[0] == 'add';
  }

  Future<void> _handleUri(Uri uri) async {
    if (!_isChannelAddUri(uri)) return;
    if (_handling) return;
    _handling = true;

    try {
      final repo = context.read<ChannelRepository>();
      final imported = await repo.importChannel(uri.toString(), '');

      if (!mounted) return;

      if (imported == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid channel link')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added: ${imported.name}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      _handling = false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
