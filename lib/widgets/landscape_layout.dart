import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'game_board.dart';
import 'gesture_control.dart';
import 'layout_helpers.dart';

class LandscapeLayout extends StatelessWidget {
  final GameProvider game;
  final GameState state;
  final BoxConstraints constraints;
  final ControlMode controlMode;

  const LandscapeLayout({
    super.key,
    required this.game,
    required this.state,
    required this.constraints,
    this.controlMode = ControlMode.both,
  });

  @override
  Widget build(BuildContext context) {
    final maxBoardHeight = constraints.maxHeight - 16;
    final cellSize = maxBoardHeight / state.height;
    final boardW = cellSize * state.width;

    Widget board = GameBoard(
      game: game,
      state: state,
      boardW: boardW,
      boardH: maxBoardHeight,
      cellSize: cellSize,
    );
    if (controlMode != ControlMode.buttons) {
      board = GestureControl(
        onTap: () => handleBoardTap(game),
        onSwipe: (direction) => handleBoardSwipe(game, direction),
        child: board,
      );
    }

    return Row(
      children: [
        const SizedBox(width: 8),
        SizedBox(width: 120, child: InfoPanel(state: state)),
        const SizedBox(width: 8),
        board,
        const SizedBox(width: 8),
        Expanded(child: ControlArea(game: game, state: state, controlMode: controlMode)),
        const SizedBox(width: 8),
      ],
    );
  }
}
