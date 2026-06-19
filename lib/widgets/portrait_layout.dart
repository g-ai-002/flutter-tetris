import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import 'game_board.dart';
import 'layout_helpers.dart';

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
          InfoPanel(state: state, spacing: 8),
          const SizedBox(height: 8),
          GameBoard(
            game: game,
            state: state,
            boardW: boardW,
            boardH: boardH,
            cellSize: cellSize,
          ),
          ControlArea(game: game, state: state),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
