import 'package:flutter/material.dart';

import '../../game/achievement.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import 'section_card.dart';

/// 生涯成就：已解锁徽章墙与未达成进度。
class AchievementsCard extends StatelessWidget {
  const AchievementsCard({super.key, required this.settings});

  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final stats = settings.achievementStats;
    final unlocked = settings.unlockedAchievements;
    return SectionCard(
      title: '成就',
      icon: Icons.workspace_premium_outlined,
      trailing: Text(
        '${unlocked.length}/${Achievement.values.length}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      children: [
        Text(
          '对局表现会累计到生涯进度，解锁后永久保留。',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 520 ? 3 : 2;
            const spacing = 8.0;
            final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final achievement in Achievement.values)
                  _AchievementTile(
                    achievement: achievement,
                    unlocked: unlocked.contains(achievement),
                    progress: achievement.progressLabel(stats),
                    width: width,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.unlocked,
    required this.progress,
    required this.width,
  });

  final Achievement achievement;
  final bool unlocked;
  final String progress;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Tooltip(
      message: achievement.description,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: unlocked
              ? appGold.withValues(alpha: 0.08)
              : colors.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: unlocked
                ? appGold.withValues(alpha: 0.45)
                : colors.outline.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          children: [
            Icon(
              achievement.icon,
              size: 18,
              color: unlocked ? appGold : colors.onSurfaceVariant.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: unlocked ? colors.onSurface : colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    progress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: unlocked ? appGold : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
