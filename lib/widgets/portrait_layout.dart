import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'game_board.dart';
import 'layout_helpers.dart';

class PortraitLayout extends StatelessWidget {
  final GameProvider game;
  final ControlMode controlMode;
  final FocusNode focusNode;

  const PortraitLayout({
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
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        children: [
          Consumer<GameProvider>(
            builder: (context, provider, _) =>
                CompactInfoBar(state: provider.state),
          ),
          const SizedBox(height: 6),
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
          const SizedBox(height: 6),
          ControlArea(
            game: game,
            controlMode: controlMode,
            compactControls: true,
          ),
        ],
      ),
    );
  }
}
