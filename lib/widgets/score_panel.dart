import 'package:flutter/material.dart';
import '../models/game_mode.dart';
import '../models/game_state.dart';

/// 紧凑的分数统计面板：小字号排布，尽量少占用屏幕空间。
class ScorePanel extends StatelessWidget {
  final GameState state;
  const ScorePanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 2,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
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
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
