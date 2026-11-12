import 'package:flutter/material.dart';

import '../../game/level.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import 'section_card.dart';

/// 关卡模式的通关进度与累计星级。
class LevelSummaryCard extends StatelessWidget {
  const LevelSummaryCard({super.key, required this.settings, this.title = '关卡模式'});

  final SettingsProvider settings;

  /// 关卡选择页复用此卡片并把标题改为「挑战进度」。
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final done = settings.completedLevels;
    return SectionCard(
      title: title,
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
          done == 0 ? '还没有通关记录，从第 1 关开始挑战吧。' : '已通关 $done / ${kLevels.length} 关',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
