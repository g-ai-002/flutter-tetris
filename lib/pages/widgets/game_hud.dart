import 'package:flutter/material.dart';

import '../../game/game_mode.dart';
import '../../game/tetris_controller.dart';
import '../../utils/formatters.dart';
import 'stat_value.dart';

/// 分数、行数、等级与时间的展示：宽屏侧栏、竖屏顶栏与横屏状态条共用同一套取值。
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
    // 计时走独立通知：只有数值组件按 20Hz 刷新，侧栏与操作区不跟着重建。
    return ValueListenableBuilder<Duration>(
      valueListenable: controller.clock,
      builder: (context, value, _) => _content(context),
    );
  }

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final score = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '分数',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatThousands(controller.score),
            maxLines: 1,
            style: (compact ? theme.textTheme.headlineSmall : theme.textTheme.headlineMedium)
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  height: 1.05,
                ),
          ),
        ),
      ],
    );
    final stats = <Widget>[
      _stat(compact ? '行' : '消行', '${controller.lines}', compact),
      _stat(compact ? '级' : '等级', '${controller.level}', compact),
      _stat(_timeLabel, _timeValue, compact, small: true),
      if (!compact) _stat('最高连击', '${controller.maxCombo}', false),
    ];
    final progress = controller.targetLines == null
        ? null
        : ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: controller.progress,
              minHeight: compact ? 4 : 5,
              backgroundColor: colors.outline.withValues(alpha: 0.4),
            ),
          );

    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(flex: 5, child: score),
              for (final stat in stats)
                Flexible(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomRight,
                      child: stat,
                    ),
                  ),
                ),
            ],
          ),
          if (progress != null) ...[const SizedBox(height: 7), progress],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        score,
        const SizedBox(height: 12),
        for (final stat in stats) ...[
          SizedBox(width: double.infinity, child: stat),
          const SizedBox(height: 7),
        ],
        if (progress != null) ...[progress, const SizedBox(height: 5)],
        if (controller.targetLines != null)
          _note(context, '${controller.lines} / ${controller.targetLines} 行'),
        if (controller.garbageInterval != null)
          _note(context, '垃圾行 ${controller.garbageSecondsLeft} 秒后上涌'),
        if (controller.mode == GameMode.ultra || controller.mode == GameMode.daily)
          _note(context, controller.mode == GameMode.daily ? '每日挑战 · 限时 2 分钟' : '限时 2 分钟'),
      ],
    );
  }

  Widget _stat(String label, String value, bool compact, {bool small = false}) {
    if (!compact) return StatValue.inline(label: label, value: value);
    return StatValue(
      label: label,
      value: value,
      labelFirst: true,
      alignment: CrossAxisAlignment.end,
      valueStyle: TextStyle(
        fontSize: small ? 12.5 : 14,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _note(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

/// 横屏状态条：返回、分数、三项数值与帮助 / 暂停，高度压到 38 像素。
class GameHudBar extends StatelessWidget {
  const GameHudBar({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onHelp,
    required this.onPause,
  });

  final TetrisController controller;
  final VoidCallback onBack;
  final VoidCallback onHelp;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          _BarButton(icon: Icons.arrow_back_rounded, onPressed: onBack, tip: '返回'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(width: 300, child: GameHud(controller: controller, compact: true)),
              ),
            ),
          ),
          _BarButton(icon: Icons.help_outline, onPressed: onHelp, tip: '玩法与操作'),
          _BarButton(
            icon: controller.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            onPressed: onPause,
            tip: controller.isPaused ? '继续' : '暂停',
          ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({required this.icon, required this.onPressed, required this.tip});

  final IconData icon;
  final VoidCallback onPressed;
  final String tip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 38, height: 38),
      iconSize: 20,
      icon: Icon(icon),
    );
  }
}
