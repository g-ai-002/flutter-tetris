import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import 'game_board.dart';
import 'game_controls.dart';
import 'next_piece_preview.dart';
import 'score_panel.dart';

class PortraitLayout extends StatelessWidget {
  final GameProvider game;
  final GameState state;
  final BoxConstraints constraints;

  const PortraitLayout({
    super.key,
    required this.game,
    required this.state,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final maxBoardHeight = constraints.maxHeight - 200;
    final maxBoardWidth = constraints.maxWidth - 32;
    final cellSize = min(maxBoardWidth / state.width, maxBoardHeight / state.height);
    final boardW = cellSize * state.width;
    final boardH = cellSize * state.height;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          ScorePanel(state: state),
          const SizedBox(height: 8),
          NextPiecePreview(state: state),
          const SizedBox(height: 8),
          GameBoard(
            game: game,
            state: state,
            boardW: boardW,
            boardH: boardH,
            cellSize: cellSize,
          ),
          _buildStatusOverlay(context, game, state),
          const SizedBox(height: 8),
          if (!state.isGameOver) GameControls(game: game),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatusOverlay(BuildContext context, GameProvider game, GameState state) {
    if (state.isGameOver) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: _restartButton(game),
      );
    }
    if (state.isPaused) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: _pausedText(context),
      );
    }
    return const SizedBox.shrink();
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
