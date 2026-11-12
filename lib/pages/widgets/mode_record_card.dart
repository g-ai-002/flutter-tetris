import 'package:flutter/material.dart';

import '../../game/game_mode.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/mode_visuals.dart';
import '../../utils/formatters.dart';
import 'section_card.dart';
import 'stat_value.dart';

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
            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          )
        else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: StatValue(
                  label: '最高分',
                  value: formatThousands(bestScore),
                  accent: colors.primary,
                ),
              ),
              Expanded(
                child: StatValue(label: '最多消行', value: '$bestLines'),
              ),
              Expanded(
                child: StatValue(label: '对局', value: '$plays'),
              ),
              if (mode == GameMode.sprint)
                Expanded(
                  child: StatValue(
                    label: '最快',
                    value: settings.bestSprintTimeMs == null
                        ? '—'
                        : formatPreciseDuration(settings.bestSprintTimeMs!),
                    accent: appGold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            mode.tagline,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
