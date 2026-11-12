import 'package:flutter/material.dart';

import '../../game/tetris_controller.dart';
import '../../input/key_bindings.dart';
import '../../theme/app_theme.dart';
import 'game_hud.dart';
import 'piece_slot.dart';
import 'status_chip.dart';

/// 宽屏左侧栏：暂存、分隔线与对局数值。
class GameLeftRail extends StatelessWidget {
  const GameLeftRail({
    super.key,
    required this.controller,
    required this.palette,
    required this.bindings,
  });

  final TetrisController controller;
  final BlockPalette palette;
  final KeyBindings bindings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (controller.rules.holdEnabled) ...[
          PieceSlot(
            label: '暂存',
            type: controller.holdType,
            palette: palette,
            size: 62,
            onTap: controller.canHold ? controller.hold : null,
            hint: controller.canHold ? '${bindings.labelsFor(GameAction.hold).first} / 点击' : null,
          ),
          const SizedBox(height: 18),
        ],
        Divider(color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 14),
        GameHud(controller: controller),
      ],
    );
  }
}

/// 宽屏右侧栏：五个预览与连续奖励提示。
class GameRightRail extends StatelessWidget {
  const GameRightRail({super.key, required this.controller, required this.palette});

  final TetrisController controller;
  final BlockPalette palette;

  @override
  Widget build(BuildContext context) {
    final previews = controller.rules.previewCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NextQueue(
          controller: controller,
          palette: palette,
          count: previews,
          firstSize: 52,
          restSize: 44,
          gap: 7,
        ),
        const Spacer(),
        if (controller.combo >= 2) ...[
          StatusChip(
            accent: Theme.of(context).colorScheme.primary,
            filled: true,
            child: Text(
              '连击 ×${controller.combo}',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
        ],
        if (controller.backToBack)
          StatusChip(
            accent: appGold,
            child: Text(
              '连续奖励',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: appGold, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

/// 窄屏左侧栏：紧凑的暂存与三个预览，尺寸跟随栏宽。
class GameCompactRail extends StatelessWidget {
  const GameCompactRail({
    super.key,
    required this.controller,
    required this.palette,
    this.width = 58,
  });

  final TetrisController controller;
  final BlockPalette palette;
  final double width;

  @override
  Widget build(BuildContext context) {
    final previews = controller.rules.previewCount.clamp(0, 3);
    final slot = width * 0.66;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (controller.rules.holdEnabled) ...[
          PieceSlot(
            label: '暂存',
            type: controller.holdType,
            palette: palette,
            size: slot,
            onTap: controller.canHold ? controller.hold : null,
          ),
          const SizedBox(height: 8),
        ],
        NextQueue(
          controller: controller,
          palette: palette,
          count: previews,
          firstSize: slot * 0.92,
          restSize: slot * 0.86,
          gap: 5,
          compact: true,
        ),
      ],
    );
  }
}

/// 预览队列：第一块更大，其余同尺寸，超出栏高的部分自然裁掉。
class NextQueue extends StatelessWidget {
  const NextQueue({
    super.key,
    required this.controller,
    required this.palette,
    required this.count,
    required this.firstSize,
    required this.restSize,
    required this.gap,
    this.compact = false,
  });

  final TetrisController controller;
  final BlockPalette palette;
  final int count;
  final double firstSize;
  final double restSize;
  final double gap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final next = controller.nextQueue;
    final colors = Theme.of(context).colorScheme;
    final style = compact
        ? TextStyle(fontSize: 9, letterSpacing: 1.2, color: colors.onSurfaceVariant)
        : Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: colors.onSurfaceVariant, letterSpacing: 2);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('下一个', style: style),
        SizedBox(height: compact ? 4 : 8),
        for (var i = 0; i < count && i < next.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          PieceSlot(
            label: '',
            type: next[i],
            palette: palette,
            size: i == 0 ? firstSize : restSize,
            showLabel: false,
          ),
        ],
      ],
    );
  }
}

/// 桌面端的键盘提示条，按键取自当前键位配置。
class GameKeyboardHint extends StatelessWidget {
  const GameKeyboardHint({super.key, required this.bindings, this.showHold = true});

  final KeyBindings bindings;

  /// 街机模式没有暂存，提示条随之隐藏该键。
  final bool showHold;

  String _first(GameAction action) => bindings.labelsFor(action).first;

  List<(GameAction, String, String)> get _items => [
    (GameAction.moveLeft, '${_first(GameAction.moveLeft)}/${_first(GameAction.moveRight)}', '移动'),
    (GameAction.softDrop, _first(GameAction.softDrop), '软降'),
    (GameAction.hardDrop, _first(GameAction.hardDrop), '硬降'),
    (GameAction.rotateClockwise, _first(GameAction.rotateClockwise), '旋转'),
    if (showHold) (GameAction.hold, _first(GameAction.hold), '暂存'),
    (GameAction.pause, _first(GameAction.pause), '暂停'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final (action, key, label) in _items)
            Row(
              key: ValueKey('key-hint-${action.name}'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
                  ),
                  child: Text(key, style: theme.textTheme.labelSmall?.copyWith(fontSize: 9.5)),
                ),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
        ],
      ),
    );
  }
}
