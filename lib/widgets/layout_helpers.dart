import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import 'game_controls.dart';
import 'next_piece_preview.dart';
import 'score_panel.dart';
import 'status_overlay.dart';

class InfoPanel extends StatelessWidget {
  final GameState state;
  final double spacing;

  const InfoPanel({super.key, required this.state, this.spacing = 16});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScorePanel(state: state),
        SizedBox(height: spacing),
        NextPiecePreview(state: state),
      ],
    );
  }
}

class ControlArea extends StatelessWidget {
  final GameProvider game;
  final GameState state;

  const ControlArea({super.key, required this.game, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StatusOverlay(
          game: game,
          isGameOver: state.isGameOver,
          isPaused: state.isPaused,
        ),
        if (!state.isGameOver && !state.isPaused) GameControls(game: game),
      ],
    );
  }
}
