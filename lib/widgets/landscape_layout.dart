import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'game_board.dart';
import 'layout_helpers.dart';

class LandscapeLayout extends StatelessWidget {
  final GameProvider game;
  final ControlMode controlMode;
  final FocusNode focusNode;

  const LandscapeLayout({
    super.key,
    required this.game,
    required this.focusNode,
    this.controlMode = ControlMode.both,
  });

  @override
  Widget build(BuildContext context) {
    final width = game.state.width;
    final height = game.state.height;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Consumer<GameProvider>(
            builder: (context, provider, _) =>
                CompactInfoColumn(state: provider.state),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AspectRatio(
                aspectRatio: width / height,
                child: GameBoard(
                  game: game,
                  focusNode: focusNode,
                  gesturesEnabled: controlMode != ControlMode.buttons,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ControlArea(game: game, controlMode: controlMode),
        ],
      ),
    );
  }
}
