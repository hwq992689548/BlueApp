import 'dart:async';

import 'package:blue_app/core/log_entry.dart';
import 'package:blue_app/session/link_session.dart';
import 'package:blue_app/theme/blue_text_styles.dart';
import 'package:blue_app/theme/blue_theme.dart';
import 'package:blue_app/widgets/blue_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 收发控制台面板。
class BlueConsolePanel extends StatelessWidget {
  const BlueConsolePanel({super.key, required this.session, this.expanded = true, this.fillsHeight = false, this.onToggleExpanded});

  final LinkSession session;
  final bool expanded;
  final bool fillsHeight;
  final VoidCallback? onToggleExpanded;

  static String exportText(List<LogEntry> entries) {
    final lines = <String>[];
    for (final entry in entries) {
      lines.add(
        [
          entry.at.toIso8601String(),
          entry.direction.name,
          entry.hex,
          entry.ascii ?? '',
          entry.message ?? '',
        ].join('\t'),
      );
    }
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final palette = BlueTheme.of(context);
    return StreamBuilder<List<LogEntry>>(
      stream: session.logs$,
      initialData: const [],
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const [];
        final header = SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onToggleExpanded,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('CONSOLE', style: BlueTextStyles.section(context)),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => unawaited(_export(context, entries)),
                  child: Text('导出', style: TextStyle(color: palette.textSecondary, fontSize: 12)),
                ),
                TextButton(
                  onPressed: session.clearLogs,
                  child: Text('清空', style: TextStyle(color: palette.textSecondary, fontSize: 12)),
                ),
                if (onToggleExpanded != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onToggleExpanded,
                    icon: Icon(expanded ? Icons.expand_more : Icons.expand_less, color: palette.textSecondary),
                  ),
              ],
            ),
          ),
        );

        final logs = entries.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Text('收发与状态会显示在这里', style: BlueTextStyles.caption(context)),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[entries.length - 1 - index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SelectableText(_formatLog(entry), style: BlueTheme.mono(context, color: _logColor(context, entry.direction))),
                  );
                },
              );

        if (fillsHeight) {
          return ColoredBox(
            color: palette.panel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: header),
                Divider(height: 1, color: palette.border),
                Expanded(child: logs),
              ],
            ),
          );
        }

        return Container(
          height: expanded ? 180 : null,
          decoration: BoxDecoration(
            color: palette.panel,
            border: Border(top: BorderSide(color: palette.border)),
          ),
          child: Column(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              header,
              if (expanded) Expanded(child: logs),
            ],
          ),
        );
      },
    );
  }

  Future<void> _export(BuildContext context, List<LogEntry> entries) async {
    await Clipboard.setData(ClipboardData(text: exportText(entries)));
    if (!context.mounted) {
      return;
    }
    BlueToast.success(context, '已复制');
  }

  static String _formatLog(LogEntry entry) {
    final time = '${entry.at.hour.toString().padLeft(2, '0')}:${entry.at.minute.toString().padLeft(2, '0')}:${entry.at.second.toString().padLeft(2, '0')}';
    final buffer = StringBuffer('[$time] ${entry.direction.name.toUpperCase()}');
    final message = entry.message;
    if (message != null) {
      buffer.write(' $message');
    }
    if (entry.hex.isNotEmpty) {
      buffer.write('  ${entry.hex}');
    }
    return buffer.toString();
  }

  static Color _logColor(BuildContext context, LogDirection direction) {
    final palette = BlueTheme.of(context);
    return switch (direction) {
      LogDirection.tx => palette.tx,
      LogDirection.rx => palette.rx,
      LogDirection.info => palette.textSecondary,
    };
  }
}
