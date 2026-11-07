import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../flame/tetris_game.dart';
import '../../theme/block_palette.dart';

/// 棋盘舞台：10:20 的场地按可用空间取最大尺寸，外加实体感边框与投影。
class BoardStage extends StatelessWidget {
  const BoardStage({
    super.key,
    required this.game,
    required this.gameKey,
    required this.palette,
    this.maxWidth = 460,
  });

  final TetrisGame game;
  final Key gameKey;
  final BlockPalette palette;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = math
            .min(constraints.maxWidth / 10, constraints.maxHeight / 20)
            .clamp(4.0, maxWidth / 10);
        final width = cell * 10;
        final height = cell * 20;
        return Center(
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.boardBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: palette.wellShadow,
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              // 键盘焦点由对局页统一持有；Flame 默认 autofocus 会抢走焦点并拦截按键。
              child: GameWidget<TetrisGame>(
                key: gameKey,
                game: game,
                autofocus: false,
              ),
            ),
          ),
        );
      },
    );
  }
}
