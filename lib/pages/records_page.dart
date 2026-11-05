import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/game_mode.dart';
import '../providers/settings_provider.dart';
import 'widgets/records_cards.dart';

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasRecords = settings.gamesPlayed > 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('本地纪录'),
        actions: [
          if (hasRecords)
            IconButton(
              tooltip: '清空纪录',
              onPressed: () => _confirmClear(context, settings),
              icon: const Icon(Icons.delete_outline_rounded, size: 21),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                RecordsSummaryCard(settings: settings),
                const SizedBox(height: 12),
                DailyRecordsCard(settings: settings),
                const SizedBox(height: 12),
                LevelSummaryCard(settings: settings),
                const SizedBox(height: 12),
                for (final mode in const [
                  GameMode.endless,
                  GameMode.sprint,
                  GameMode.ultra,
                ]) ...[
                  ModeRecordCard(settings: settings, mode: mode),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 4),
                Text(
                  '纪录保存在本机，不会上传到任何服务器。',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清空本地纪录？'),
        content: const Text('最高分、最快时间与累计统计都会被删除，此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (ok == true) await settings.clearRecords();
  }
}
