import 'package:flutter/material.dart';

import '../../game/game_mode.dart';
import '../../game/tetris_controller.dart';
import '../../utils/formatters.dart';

/// 暂停弹窗：继续、重开或返回首页。
Future<void> showPauseDialog(
  BuildContext context, {
  required TetrisController controller,
  required VoidCallback onRestart,
  required VoidCallback onExit,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final level = controller.levelDef;
      final label = level == null ? controller.mode.label : '第 ${level.id} 关 · ${level.name}';
      return AlertDialog(
        title: const Text('已暂停'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label · 分数 ${formatThousands(controller.score)}'),
            const SizedBox(height: 6),
            Text(
              '消行 ${controller.lines} · 等级 ${controller.level}',
              style: Theme.of(dialogContext).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(dialogContext).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onExit();
            },
            child: Text(level == null ? '返回首页' : '返回关卡'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onRestart();
            },
            child: const Text('重新开始'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              controller.resume();
            },
            child: const Text('继续游戏'),
          ),
        ],
      );
    },
  );
}
