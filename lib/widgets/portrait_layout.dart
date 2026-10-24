import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'game_board.dart';
import 'gesture_control.dart';
import 'layout_helpers.dart';

class PortraitLayout extends StatelessWidget {
  final GameProvider game;
  final GameState state;
  final ControlMode controlMode;

  const PortraitLayout({
    super.key,
    required this.game,
    required this.state,
    this.controlMode = ControlMode.both,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        children: [
          CompactInfoBar(state: state),
          const SizedBox(height: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (context, boardConstraints) {
                final cellSize = min(
                  boardConstraints.maxWidth / state.width,
                  boardConstraints.maxHeight / state.height,
                );
                Widget board = SizedBox(
                  width: cellSize * state.width,
                  height: cellSize * state.height,
                  child: GameBoard(game: game),
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
          const SizedBox(height: 6),
          ControlArea(
            game: game,
            state: state,
            controlMode: controlMode,
            compactControls: true,
          ),
        ],
      ),
    );
  }
}
