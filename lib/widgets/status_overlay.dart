import 'package:flutter/material.dart';
import '../models/game_mode.dart';
import '../providers/game_provider.dart';

class StatusOverlay extends StatelessWidget {
  final GameProvider game;
  final bool isGameOver;
  final bool isPaused;

  const StatusOverlay({
    super.key,
    required this.game,
    required this.isGameOver,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    if (isGameOver) {
      final state = game.state;
      final theme = Theme.of(context);
      String message;
      if (state.isCompleted) {
        message = '挑战完成！';
      } else if (state.gameMode == GameMode.timed) {
        message = '时间到！';
      } else {
        message = '游戏结束';
      }

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => game.start(),
              icon: const Icon(Icons.replay),
              label: const Text('重新开始'),
            ),
          ],
        ),
      );
    }
    if (isPaused) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '已暂停',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
