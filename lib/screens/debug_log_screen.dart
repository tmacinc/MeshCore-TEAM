// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:meshcore_team/services/debug_log_service.dart';

import '../l10n/app_localizations.dart';

class DebugLogScreen extends StatefulWidget {
  const DebugLogScreen({super.key});

  @override
  State<DebugLogScreen> createState() => _DebugLogScreenState();
}

class _DebugLogScreenState extends State<DebugLogScreen> {
  final Set<LogCategory> _activeFilters = Set.of(LogCategory.values);
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    DebugLogService.instance.addListener(_onLogsChanged);
  }

  @override
  void dispose() {
    DebugLogService.instance.removeListener(_onLogsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onLogsChanged() {
    if (!mounted) return;
    setState(() {});
    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final logService = DebugLogService.instance;
    final filtered = logService.filtered(_activeFilters);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.debugLogsTitleWithCount(filtered.length)),
        actions: [
          IconButton(
            icon: Icon(
              _autoScroll ? Icons.vertical_align_bottom : Icons.pause,
            ),
            tooltip: _autoScroll ? l10n.autoScrollOn : l10n.autoScrollOff,
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: l10n.exportLogs,
            onPressed: () => _exportLogs(logService),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.clearLogs,
            onPressed: () {
              logService.clear();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text(l10n.noLogEntries))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _buildLogTile(filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: LogCategory.values.map((cat) {
          final selected = _activeFilters.contains(cat);
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(_categoryLabel(cat, l10n)),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _activeFilters.add(cat);
                  } else {
                    _activeFilters.remove(cat);
                  }
                });
              },
              avatar: Icon(_iconForCategory(cat), size: 16),
              selectedColor: _colorForCategory(cat).withAlpha(50),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogTile(LogEntry entry) {
    final color = _colorForCategory(entry.category);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.formattedTime,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withAlpha(153),
            ),
          ),
          const SizedBox(width: 6),
          Icon(_iconForCategory(entry.category), size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              entry.message,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: entry.category == LogCategory.error
                    ? Colors.red
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportLogs(DebugLogService logService) async {
    final text = logService.exportAsText(categories: _activeFilters);
    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noLogsToExport)),
      );
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final file = File('${dir.path}/team_debug_log_$timestamp.txt');
      await file.writeAsString(text);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'TEAM Debug Log $timestamp',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.exportFailedError(e.toString()))),
      );
    }
  }

  String _categoryLabel(LogCategory cat, AppLocalizations l10n) {
    return switch (cat) {
      LogCategory.sync => l10n.logCategorySync,
      LogCategory.ble => l10n.logCategoryBle,
      LogCategory.telemetry => l10n.logCategoryTelemetry,
      LogCategory.forwarding => l10n.logCategoryForwarding,
      LogCategory.error => l10n.error,
      LogCategory.general => l10n.logCategoryGeneral,
    };
  }

  IconData _iconForCategory(LogCategory category) {
    return switch (category) {
      LogCategory.sync => Icons.sync,
      LogCategory.ble => Icons.bluetooth,
      LogCategory.telemetry => Icons.gps_fixed,
      LogCategory.forwarding => Icons.alt_route,
      LogCategory.error => Icons.error_outline,
      LogCategory.general => Icons.info_outline,
    };
  }

  Color _colorForCategory(LogCategory category) {
    return switch (category) {
      LogCategory.sync => Colors.blue,
      LogCategory.ble => Colors.indigo,
      LogCategory.telemetry => Colors.teal,
      LogCategory.forwarding => Colors.orange,
      LogCategory.error => Colors.red,
      LogCategory.general => Colors.grey,
    };
  }
}
