import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/game_mode.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'widgets/section_card.dart';

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
                _SummaryCard(settings: settings),
                const SizedBox(height: 12),
                for (final mode in GameMode.values) ...[
                  _ModeCard(settings: settings, mode: mode),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.settings});

  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '累计',
      icon: Icons.insights_outlined,
      children: [
        Row(
          children: [
            _SummaryStat(
              label: '对局',
              value: '${settings.gamesPlayed}',
              suffix: '局',
            ),
            _SummaryStat(
              label: '累计消行',
              value: formatThousands(settings.totalLines),
              suffix: '行',
            ),
            _SummaryStat(
              label: '累计得分',
              value: formatThousands(settings.totalScore),
              suffix: '分',
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.suffix,
  });

  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 2),
              Text(
                suffix,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.settings, required this.mode});

  final SettingsProvider settings;
  final GameMode mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final plays = settings.plays(mode);
    final bestScore = settings.bestScore(mode);
    final bestLines = settings.bestLines(mode);
    final icon = switch (mode) {
      GameMode.endless => Icons.all_inclusive_rounded,
      GameMode.sprint => Icons.timer_outlined,
      GameMode.ultra => Icons.bolt_rounded,
    };
    return SectionCard(
      title: mode.label,
      icon: icon,
      children: [
        if (plays == 0)
          Text(
            '还没有对局记录，去玩一局吧。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          )
        else ...[
          Row(
            children: [
              _ModeStat(
                label: '最高分',
                value: formatThousands(bestScore),
                accent: colors.primary,
              ),
              _ModeStat(label: '最多消行', value: '$bestLines'),
              _ModeStat(label: '对局', value: '$plays'),
              if (mode == GameMode.sprint)
                _ModeStat(
                  label: '最快',
                  value: settings.bestSprintTimeMs == null
                      ? '—'
                      : formatPreciseDuration(settings.bestSprintTimeMs!),
                  accent: appGold,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            mode.tagline,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ModeStat extends StatelessWidget {
  const _ModeStat({required this.label, required this.value, this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: accent ?? colors.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
