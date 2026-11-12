import 'package:flutter/material.dart';

import '../../services/log_service.dart';

/// 日志查看浮层：不改变设置页布局，关闭后回到原位置。
Future<void> showLogViewerDialog(BuildContext context) {
  final lines = LogService.getRecentLogs(300);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return Dialog(
        child: SizedBox(
          width: 680,
          height: 480,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                child: Row(
                  children: [
                    Text('最近日志', style: theme.textTheme.titleSmall),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: '关闭',
                    ),
                  ],
                ),
              ),
              Divider(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: SelectableText(
                      lines.isEmpty ? '暂无日志' : lines.join('\n'),
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.55,
                        color: theme.colorScheme.onSurface,
                        fontFamily: 'Consolas',
                        fontFamilyFallback: const ['Menlo', 'monospace'],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
