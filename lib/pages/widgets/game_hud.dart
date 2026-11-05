import 'package:flutter/material.dart';

import '../../game/game_mode.dart';
import '../../game/tetris_controller.dart';
import '../../utils/formatters.dart';

/// 分数、行数、等级与时间的展示，宽屏侧栏与窄屏顶栏共用。
class GameHud extends StatelessWidget {
  const GameHud({super.key, required this.controller, this.compact = false});

  final TetrisController controller;
  final bool compact;

  String get _timeLabel => switch (controller.mode) {
    GameMode.ultra || GameMode.level => '剩余',
    _ => '用时',
  };

  String get _timeValue {
    switch (controller.mode) {
      case GameMode.ultra:
      case GameMode.level:
        return formatDuration(controller.remaining.inMilliseconds);
      case GameMode.sprint:
        return formatPreciseDuration(controller.elapsed.inMilliseconds);
      case GameMode.endless:
        return formatDuration(controller.elapsed.inMilliseconds);
    }
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
            _CompactStat(label: '行', value: '${controller.lines}'),
            _CompactStat(label: '级', value: '${controller.level}'),
            _CompactStat(label: _timeLabel, value: _timeValue, wide: true),
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
        _WideStat(label: '消行', value: '${controller.lines}'),
        _WideStat(label: '等级', value: '${controller.level}'),
        _WideStat(label: _timeLabel, value: _timeValue),
        _WideStat(label: '最高连击', value: '${controller.maxCombo}'),
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
        if (controller.mode == GameMode.ultra) ...[
          const SizedBox(height: 10),
          Text(
            '限时 2 分钟',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({
    required this.label,
    required this.value,
    this.wide = false,
  });

  final String label;
  final String value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              fontSize: wide ? 12.5 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _WideStat extends StatelessWidget {
  const _WideStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
