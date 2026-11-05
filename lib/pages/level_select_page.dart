import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/game_mode.dart';
import '../game/level.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'game_page.dart';
import 'widgets/section_card.dart';
import 'widgets/star_rating.dart';

/// 关卡选择：展示通关进度、星级与每关目标。
class LevelSelectPage extends StatelessWidget {
  const LevelSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('关卡模式'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, size: 17, color: appGold),
                const SizedBox(width: 4),
                Text(
                  '${settings.totalStars} / ${kLevels.length * 3}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 900 ? 32.0 : 16.0;
            final contentWidth = math.min(
              math.max(0.0, constraints.maxWidth - horizontal * 2),
              880.0,
            );
            final columns = contentWidth >= 780
                ? 4
                : contentWidth >= 540
                ? 3
                : 2;
            const gap = 12.0;
            final tileWidth = (contentWidth - gap * (columns - 1)) / columns;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
              child: Center(
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProgressCard(settings: settings),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final level in kLevels)
                            SizedBox(
                              width: tileWidth,
                              height: 170,
                              child: _LevelTile(
                                level: level,
                                settings: settings,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '通关上一关即可解锁下一关；剩余时间越多，星级越高。',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.settings});

  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final done = settings.completedLevels;
    return SectionCard(
      title: '挑战进度',
      icon: Icons.flag_outlined,
      trailing: Text(
        '$done / ${kLevels.length}',
        style: theme.textTheme.labelMedium?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: kLevels.isEmpty ? 0 : done / kLevels.length,
            minHeight: 6,
            backgroundColor: colors.outline.withValues(alpha: 0.35),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '已通关 $done 关',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            const Icon(Icons.star_rounded, size: 15, color: appGold),
            const SizedBox(width: 3),
            Text(
              '${settings.totalStars} 星',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.level, required this.settings});

  final LevelDefinition level;
  final SettingsProvider settings;

  Future<void> _open(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamePage(mode: GameMode.level, level: level),
      ),
    );
    if (context.mounted) context.read<SettingsProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final record = settings.levelRecord(level.id);
    final unlocked = settings.isLevelUnlocked(level.id);
    final radius = BorderRadius.circular(14);

    return Opacity(
      opacity: unlocked ? 1 : 0.62,
      child: Material(
        key: ValueKey('level-tile-${level.id}'),
        color: colors.surface,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: unlocked ? () => _open(context) : null,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: record.completed
                    ? appGold.withValues(alpha: 0.65)
                    : colors.outline.withValues(alpha: 0.8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: (unlocked ? colors.primary : colors.outline)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: unlocked
                          ? Text(
                              '${level.id}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : Icon(
                              Icons.lock_outline_rounded,
                              size: 17,
                              color: colors.onSurfaceVariant,
                            ),
                    ),
                    const Spacer(),
                    StarRating(stars: record.stars, size: 14),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  level.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  level.brief,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                Text(
                  '${level.targetLines} 行 · ${level.timeLimit.inSeconds} 秒'
                  '${level.hasGarbageRise ? ' · 垃圾行' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  !unlocked
                      ? '通关第 ${level.id - 1} 关解锁'
                      : record.completed
                      ? '最佳 ${formatThousands(record.bestScore)} 分'
                      : '尚未通关',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: record.completed ? appGold : colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
