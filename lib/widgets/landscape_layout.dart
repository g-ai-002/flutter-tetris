import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import 'game_board.dart';
import 'game_controls.dart';
import 'next_piece_preview.dart';
import 'score_panel.dart';

class LandscapeLayout extends StatelessWidget {
  final GameProvider game;
  final GameState state;
  final BoxConstraints constraints;

  const LandscapeLayout({
    super.key,
    required this.game,
    required this.state,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final maxBoardHeight = constraints.maxHeight - 16;
    final cellSize = maxBoardHeight / state.height;
    final boardW = cellSize * state.width;

    return Row(
      children: [
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScorePanel(state: state),
              const SizedBox(height: 16),
              NextPiecePreview(state: state),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GameBoard(
          game: game,
          state: state,
          boardW: boardW,
          boardH: maxBoardHeight,
          cellSize: cellSize,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.isGameOver)
                _restartButton(game)
              else if (state.isPaused)
                _pausedText(context)
              else
                GameControls(game: game),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _restartButton(GameProvider game) {
    return ElevatedButton.icon(
      onPressed: () => game.start(),
      icon: const Icon(Icons.replay),
      label: const Text('重新开始'),
    );
  }

  Widget _pausedText(BuildContext context) {
    return Text(
      '已暂停',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}
