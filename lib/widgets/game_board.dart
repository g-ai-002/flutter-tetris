import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/tetris_game.dart';
import '../providers/game_provider.dart';

/// 棋盘组件：用 [GameWidget] 承载 Flame 对局。
class GameBoard extends StatefulWidget {
  const GameBoard({super.key, required this.game});

  final GameProvider game;

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  TetrisGame? _game;
  Brightness? _brightness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    final provider = context.read<GameProvider>();
    if (_game != null &&
        _brightness == brightness &&
        _game!.provider == provider) {
      return;
    }

    _brightness = brightness;
    final colors = Theme.of(context).colorScheme;
    _game = TetrisGame(
      provider: provider,
      surfaceColor: colors.surface,
      gridColor: colors.outline.withValues(alpha: 0.22),
    );
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
        child: GameWidget<TetrisGame>(game: game),
      ),
    );
  }
}
