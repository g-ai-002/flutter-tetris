import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import 'game_board.dart';
import 'layout_helpers.dart';

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
        SizedBox(width: 120, child: InfoPanel(state: state)),
        const SizedBox(width: 8),
        GameBoard(
          game: game,
          state: state,
          boardW: boardW,
          boardH: maxBoardHeight,
          cellSize: cellSize,
        ),
        const SizedBox(width: 8),
        Expanded(child: ControlArea(game: game, state: state)),
        const SizedBox(width: 8),
      ],
    );
  }
}
