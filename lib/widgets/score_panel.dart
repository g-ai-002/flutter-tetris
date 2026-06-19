import 'package:flutter/material.dart';
import '../models/game_mode.dart';
import '../models/game_state.dart';

class ScorePanel extends StatelessWidget {
  final GameState state;
  const ScorePanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 16,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            _scoreItem('分数', state.score.toString()),
            _scoreItem('等级', state.level.toString()),
            _scoreItem('行数', state.linesCleared.toString()),
            _scoreItem('最高', state.highScore.toString()),
            if (state.gameMode == GameMode.timed)
              _scoreItem('剩余', _formatTime(state.remainingSeconds)),
            if (state.gameMode == GameMode.challenge)
              _scoreItem('目标', '${state.linesCleared}/${state.targetLines}'),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
