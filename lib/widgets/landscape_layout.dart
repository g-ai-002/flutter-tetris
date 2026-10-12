import 'dart:math';
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
  final ControlMode controlMode;

  const LandscapeLayout({
    super.key,
    required this.game,
    required this.state,
    this.controlMode = ControlMode.both,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          CompactInfoColumn(state: state),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, boardConstraints) {
                final cellSize = min(
                  boardConstraints.maxWidth / state.width,
                  boardConstraints.maxHeight / state.height,
                );
                Widget board = GameBoard(
                  game: game,
                  state: state,
                  boardW: cellSize * state.width,
                  boardH: cellSize * state.height,
                  cellSize: cellSize,
                );
                if (controlMode != ControlMode.buttons) {
                  board = GestureControl(
                    onTap: () => handleBoardTap(game),
                    onSwipe: (direction) => handleBoardSwipe(game, direction),
                    child: board,
                  );
                }
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: board,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          ControlArea(game: game, state: state, controlMode: controlMode),
        ],
      ),
    );
  }
}
