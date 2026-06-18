import 'package:flutter/material.dart';
import '../models/game_state.dart';

class ScorePanel extends StatelessWidget {
  final GameState state;
  const ScorePanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _scoreItem('分数', state.score.toString()),
            const SizedBox(width: 24),
            _scoreItem('等级', state.level.toString()),
            const SizedBox(width: 24),
            _scoreItem('行数', state.linesCleared.toString()),
            const SizedBox(width: 24),
            _scoreItem('最高', state.highScore.toString()),
          ],
        ),
      ),
    );
  }

  Widget _scoreItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
