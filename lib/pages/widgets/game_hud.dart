import 'package:flutter/material.dart';

import '../../game/game_mode.dart';
import '../../game/tetris_controller.dart';
import '../../utils/formatters.dart';
import 'stat_value.dart';

/// 分数、行数、等级与时间的展示，宽屏侧栏与窄屏顶栏共用。
class GameHud extends StatelessWidget {
  const GameHud({super.key, required this.controller, this.compact = false});

  final TetrisController controller;
  final bool compact;

  /// 有剩余时间的玩法显示倒计时，其余显示已用时间。
  String get _timeLabel => controller.limit == null ? '用时' : '剩余';

  String get _timeValue {
    if (controller.limit != null) {
      return formatDuration(controller.remaining.inMilliseconds);
    }
    if (controller.mode == GameMode.sprint) {
      return formatPreciseDuration(controller.elapsed.inMilliseconds);
    }
    return formatDuration(controller.elapsed.inMilliseconds);
  }

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompact(context) : _buildWide(context);
  }

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '分数',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    formatThousands(controller.score),
                    maxLines: 1,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            _HudStat(compact: true, label: '行', value: '${controller.lines}'),
            _HudStat(compact: true, label: '级', value: '${controller.level}'),
            _HudStat(
              compact: true,
              label: _timeLabel,
              value: _timeValue,
              narrow: true,
            ),
          ],
        ),
        if (controller.targetLines != null) ...[
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: controller.progress,
              minHeight: 4,
              backgroundColor: colors.outline.withValues(alpha: 0.4),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWide(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '分数',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatThousands(controller.score),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _HudStat(label: '消行', value: '${controller.lines}'),
        _HudStat(label: '等级', value: '${controller.level}'),
        _HudStat(label: _timeLabel, value: _timeValue),
        _HudStat(label: '最高连击', value: '${controller.maxCombo}'),
        if (controller.targetLines != null) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: controller.progress,
              minHeight: 5,
              backgroundColor: colors.outline.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${controller.lines} / ${controller.targetLines} 行',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
        if (controller.garbageInterval != null) ...[
          const SizedBox(height: 10),
          Text(
            '垃圾行 ${controller.garbageSecondsLeft} 秒后上涌',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
        if (controller.mode == GameMode.ultra ||
            controller.mode == GameMode.daily) ...[
          const SizedBox(height: 10),
          Text(
            controller.mode == GameMode.daily ? '每日挑战 · 限时 2 分钟' : '限时 2 分钟',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _HudStat extends StatelessWidget {
  const _HudStat({
    required this.label,
    required this.value,
    this.compact = false,
    this.narrow = false,
  });

  final String label;
  final String value;
  final bool compact;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: compact
          ? const EdgeInsets.only(left: 14)
          : const EdgeInsets.only(bottom: 8),
      child: compact
          ? StatValue(
              label: label,
              value: value,
              labelFirst: true,
              alignment: CrossAxisAlignment.end,
              valueStyle: theme.textTheme.titleSmall?.copyWith(
                fontSize: narrow ? 12.5 : 14,
              ),
            )
          : StatValue.inline(label: label, value: value),
    );
  }
}
