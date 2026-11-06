import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../game/daily_challenge.dart';
import '../../game/game_mode.dart';
import '../../providers/settings_provider.dart';
import '../../services/daily_progress.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../game_page.dart';
import 'section_card.dart';

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
