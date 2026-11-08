import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../game/game_mode.dart';
import '../../input/key_bindings.dart';
import '../../providers/settings_provider.dart';
import 'gamepad_guide.dart';

/// 规则与操作说明。
Future<void> showHelpDialog(BuildContext context) {
  final bindings = context.read<SettingsProvider>().keyBindings;
  String keys(GameAction action) => bindings.labelsFor(action).join(' / ');
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final bodyStyle = theme.textTheme.bodySmall?.copyWith(
        height: 1.7,
        color: theme.colorScheme.onSurfaceVariant,
      );
      return AlertDialog(
        title: const Text('玩法与操作'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '堆叠方块填满整行即可消除，消除越多得分越高；'
                  '一次消除 4 行可获得额外奖励，连续消行还有连击加分。'
                  '每消除 10 行提升一级，下落速度随之加快。',
                  style: bodyStyle,
                ),
                const SizedBox(height: 14),
                Text('键盘', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  '${keys(GameAction.moveLeft)} / '
                  '${keys(GameAction.moveRight)} 左右移动　'
                  '${keys(GameAction.softDrop)} 软降　'
                  '${keys(GameAction.hardDrop)} 硬降\n'
                  '${keys(GameAction.rotateClockwise)} 顺时针旋转　'
                  '${keys(GameAction.rotateCounterClockwise)} 逆时针旋转\n'
                  '${keys(GameAction.hold)} 暂存　'
                  '${keys(GameAction.pause)} 暂停　'
                  '${keys(GameAction.restart)} 重新开始',
                  style: bodyStyle,
                ),
                const SizedBox(height: 6),
                Text(
                  '可在设置页自定义键位。',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Text('手柄', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                const GamepadGuide(),
                const SizedBox(height: 14),
                Text('触屏与鼠标', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  '点击棋盘旋转，左右拖动移动，向下拖动软降，向上滑动暂存；'
                  '触屏设备底部只保留「左移 / 硬降 / 右移」三键。',
                  style: bodyStyle,
                ),
                const SizedBox(height: 14),
                Text('模式', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                for (final mode in GameMode.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '· ${mode.label}：${mode.tagline}',
                      style: bodyStyle,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('知道了'),
          ),
        ],
      );
    },
  );
}
