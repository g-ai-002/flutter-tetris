import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'game_controls.dart';
import 'gesture_control.dart';
import 'next_piece_preview.dart';
import 'score_panel.dart';
import 'status_overlay.dart';

/// 棋盘点击：游戏结束时重新开始，进行中旋转方块。
void handleBoardTap(GameProvider game) {
  final state = game.state;
  if (state.isGameOver) {
    game.start();
  } else if (!state.isPaused) {
    game.rotate();
  }
}

/// 棋盘滑动：按方向执行移动/旋转/硬降。
void handleBoardSwipe(GameProvider game, GestureDirection direction) {
  final state = game.state;
  if (state.isGameOver || state.isPaused) return;
  switch (direction) {
    case GestureDirection.up:
      game.rotate();
    case GestureDirection.down:
      game.hardDrop();
    case GestureDirection.left:
      game.moveLeft();
    case GestureDirection.right:
      game.moveRight();
  }
}

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
  final ControlMode controlMode;

  const ControlArea({
    super.key,
    required this.game,
    required this.state,
    this.controlMode = ControlMode.both,
  });

  @override
  Widget build(BuildContext context) {
    final showButtons = controlMode != ControlMode.gesture;
    final showHint = controlMode != ControlMode.buttons;
    final playing = !state.isGameOver && !state.isPaused;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StatusOverlay(
          game: game,
          isGameOver: state.isGameOver,
          isPaused: state.isPaused,
        ),
        if (playing && showButtons) GameControls(game: game),
        if (playing && showHint)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '点击/上滑旋转 · 左右滑动移动 · 下滑硬降',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
