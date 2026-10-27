import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/overlays/tetris_overlays.dart';
import '../game/tetris_game.dart';
import '../models/game_mode.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';

/// 整页游戏画布：用 [GameWidget] 承载 Flame 对局，并注册暂停/结束浮层。
///
/// 画布铺满整个游戏页，棋盘位置由页面里的棋盘槽位决定；HUD 与虚拟按键由
/// Flutter 叠加在画布之上。
class GameBoard extends StatelessWidget {
  const GameBoard({
    super.key,
    required this.game,
    required this.gameProvider,
    required this.focusNode,
  });

  final TetrisGame game;
  final GameProvider gameProvider;
  final FocusNode focusNode;

  String _resultTitle(GameState state) {
    if (state.isCompleted) {
      return '挑战完成！';
    }
    if (state.gameMode == GameMode.timed) {
      return '时间到！';
    }
    return '游戏结束';
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget<TetrisGame>(
      game: game,
      focusNode: focusNode,
      // 键盘已由 TetrisGame 的 KeyboardEvents 处理，聚焦即接管按键。
      autofocus: true,
      overlayBuilderMap: {
        TetrisGame.pauseOverlayId: (context, _) => TetrisPauseOverlay(
              onResume: () {
                gameProvider.togglePause();
                // 主循环在暂停时已停，浮层按钮需要显式恢复。
                game.resumeFromOverlay();
                focusNode.requestFocus();
              },
            ),
        TetrisGame.gameOverOverlayId: (context, _) => TetrisGameOverOverlay(
              title: _resultTitle(gameProvider.state),
              onRestart: () {
                gameProvider.start();
                game.resumeFromOverlay();
                focusNode.requestFocus();
              },
            ),
      },
    );
  }
}
