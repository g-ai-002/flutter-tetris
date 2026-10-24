import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/overlays/tetris_overlays.dart';
import '../game/tetris_game.dart';
import '../models/game_mode.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';

/// 棋盘组件：用 [GameWidget] 承载 Flame 对局，并注册暂停/结束浮层。
class GameBoard extends StatefulWidget {
  const GameBoard({
    super.key,
    required this.game,
    required this.focusNode,
    this.gesturesEnabled = true,
  });

  final GameProvider game;
  final FocusNode focusNode;
  final bool gesturesEnabled;

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  TetrisGame? _game;
  Brightness? _brightness;
  bool? _gestures;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    final provider = context.read<GameProvider>();
    if (_game != null &&
        _brightness == brightness &&
        _gestures == widget.gesturesEnabled &&
        _game!.provider == provider) {
      return;
    }

    _brightness = brightness;
    _gestures = widget.gesturesEnabled;
    final colors = Theme.of(context).colorScheme;
    _game = TetrisGame(
      provider: provider,
      surfaceColor: colors.surface,
      gridColor: colors.outline.withValues(alpha: 0.22),
      gesturesEnabled: widget.gesturesEnabled,
    );
  }

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
    final game = _game;
    if (game == null) {
      return const SizedBox.expand();
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: GameWidget<TetrisGame>(
          game: game,
          focusNode: widget.focusNode,
          // 键盘已由 TetrisGame 的 KeyboardEvents 处理，聚焦即接管按键。
          autofocus: true,
          overlayBuilderMap: {
            TetrisGame.pauseOverlayId: (context, _) => TetrisPauseOverlay(
                  onResume: () {
                    widget.game.togglePause();
                    widget.focusNode.requestFocus();
                  },
                ),
            TetrisGame.gameOverOverlayId: (context, _) =>
                TetrisGameOverOverlay(
                  title: _resultTitle(widget.game.state),
                  onRestart: () {
                    widget.game.start();
                    widget.focusNode.requestFocus();
                  },
                ),
          },
        ),
      ),
    );
  }
}
