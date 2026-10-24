import 'package:flutter/material.dart';

/// 暂停浮层。
class TetrisPauseOverlay extends StatelessWidget {
  const TetrisPauseOverlay({super.key, required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '已暂停',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('按 P 键或点击继续'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onResume, child: const Text('继续')),
            ],
          ),
        ),
      ),
    );
  }
}

/// 游戏结束/挑战完成浮层。
class TetrisGameOverOverlay extends StatelessWidget {
  const TetrisGameOverOverlay({
    super.key,
    required this.title,
    required this.onRestart,
  });

  final String title;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.replay),
                label: const Text('重新开始'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
