import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../game/daily_challenge.dart';
import '../../game/game_mode.dart';
import '../../game/level.dart';
import '../../providers/settings_provider.dart';
import '../../services/daily_progress.dart';
import '../../theme/app_theme.dart';
import '../../theme/mode_visuals.dart';
import '../../utils/formatters.dart';
import '../game_page.dart';
import 'section_card.dart';

/// 累计对局、消行与得分。
class RecordsSummaryCard extends StatelessWidget {
  const RecordsSummaryCard({super.key, required this.settings});

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

/// 最近七天的每日挑战成绩，可点任意一天重玩。
class DailyRecordsCard extends StatelessWidget {
  const DailyRecordsCard({super.key, required this.settings});

  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final days = DailyChallenge.recent(7);
    final today = days.first;
    final todayRecord = settings.dailyRecord(today.key);
    final streak = settings.dailyStreak(today.date);
    return SectionCard(
      title: '每日挑战',
      icon: Icons.today_outlined,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_outlined,
            size: 15,
            color: appGold,
          ),
          const SizedBox(width: 3),
          Text(
            '连续 $streak 天',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
      children: [
        Text(
          todayRecord.played
              ? '今日最高 ${formatThousands(todayRecord.bestScore)} 分'
                    ' · 已挑战 ${todayRecord.plays} 次'
              : '今天还没有挑战，同一副牌每天都在等你。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        for (final day in days)
          _DailyRow(
            challenge: day,
            played: settings.dailyRecord(day.key),
            isToday: identical(day, today),
          ),
        const SizedBox(height: 2),
        Text(
          '点击任一天可用当时的种子重玩，成绩仍记在该天。',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DailyRow extends StatelessWidget {
  const _DailyRow({
    required this.challenge,
    required this.played,
    required this.isToday,
  });

  final DailyChallenge challenge;
  final DailyRecord played;
  final bool isToday;

  Future<void> _open(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamePage(mode: GameMode.daily, daily: challenge),
      ),
    );
    if (context.mounted) context.read<SettingsProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasPlay = played.played;
    return InkWell(
      key: ValueKey('daily-row-${challenge.key}'),
      borderRadius: BorderRadius.circular(8),
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              child: Text(
                isToday ? '今天 · ${challenge.weekdayLabel}' : challenge.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isToday ? colors.primary : colors.onSurfaceVariant,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasPlay ? '${played.bestLines} 行 · ${played.plays} 次' : '未挑战',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Text(
              hasPlay ? '${formatThousands(played.bestScore)} 分' : '—',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: hasPlay ? FontWeight.w600 : FontWeight.w400,
                color: hasPlay ? colors.onSurface : colors.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: '用当日种子重玩',
              child: Icon(
                Icons.play_circle_outline_rounded,
                size: 17,
                color: colors.primary.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 关卡模式的通关进度与累计星级。
class LevelSummaryCard extends StatelessWidget {
  const LevelSummaryCard({super.key, required this.settings});

  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final done = settings.completedLevels;
    return SectionCard(
      title: '关卡模式',
      icon: Icons.flag_outlined,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 15, color: appGold),
          const SizedBox(width: 3),
          Text(
            '${settings.totalStars} / ${kLevels.length * 3}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: kLevels.isEmpty ? 0 : done / kLevels.length,
            minHeight: 5,
            backgroundColor: colors.outline.withValues(alpha: 0.35),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          done == 0
              ? '还没有通关记录，从第 1 关开始挑战吧。'
              : '已通关 $done / ${kLevels.length} 关',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 单个经典玩法的本地纪录。
class ModeRecordCard extends StatelessWidget {
  const ModeRecordCard({super.key, required this.settings, required this.mode});

  final SettingsProvider settings;
  final GameMode mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final plays = settings.plays(mode);
    final bestScore = settings.bestScore(mode);
    final bestLines = settings.bestLines(mode);
    final visual = modeVisualFor(mode, colors);
    return SectionCard(
      title: mode.label,
      icon: visual.icon,
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
