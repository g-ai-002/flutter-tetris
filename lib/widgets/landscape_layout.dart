import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'game_board.dart';
import 'layout_helpers.dart';

class LandscapeLayout extends StatelessWidget {
  final GameProvider game;
  final GameState state;
  final ControlMode controlMode;
  final FocusNode focusNode;

  const LandscapeLayout({
    super.key,
    required this.game,
    required this.state,
    required this.focusNode,
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
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AspectRatio(
                aspectRatio: state.width / state.height,
                child: GameBoard(
                  game: game,
                  focusNode: focusNode,
                  gesturesEnabled: controlMode != ControlMode.buttons,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ControlArea(game: game, state: state, controlMode: controlMode),
        ],
      ),
    );
  }
}
