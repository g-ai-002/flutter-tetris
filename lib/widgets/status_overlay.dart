import 'package:flutter/material.dart';
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
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () => game.start(),
          icon: const Icon(Icons.replay),
          label: const Text('重新开始'),
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
