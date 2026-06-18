import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import 'game_board.dart';
import 'game_controls.dart';
import 'next_piece_preview.dart';
import 'score_panel.dart';
import 'status_overlay.dart';

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
              StatusOverlay(
                game: game,
                isGameOver: state.isGameOver,
                isPaused: state.isPaused,
              ),
              if (!state.isGameOver && !state.isPaused)
                GameControls(game: game),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
