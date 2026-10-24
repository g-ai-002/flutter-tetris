import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../models/tetromino.dart';

/// 下一个方块预览的轻量 Flame 游戏。
///
/// 只做静态绘制，不参与主对局循环；[piece] 变化时由外层 widget 更新。
class NextPieceGame extends FlameGame {
  NextPieceGame({this.piece});

  Tetromino? piece;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await add(_NextPieceComponent(game: this));
  }
}

class _NextPieceComponent extends PositionComponent {
  _NextPieceComponent({required this.game});

  final NextPieceGame game;

  @override
  void render(Canvas canvas) {
    final piece = game.piece;
    if (piece == null) {
      return;
    }
    final viewSize = findGame()?.size ?? Vector2.zero();
    if (viewSize.x <= 0 || viewSize.y <= 0) {
      return;
    }

    final shape = piece.shape;
    final cell = viewSize.x / 4;
    final offsetX = (viewSize.x - shape[0].length * cell) / 2;
    final offsetY = (viewSize.y - shape.length * cell) / 2;
    final fill = Paint()..color = Color(piece.color);
    final highlight = Paint()..color = Colors.white.withValues(alpha: 0.25);

    for (var row = 0; row < shape.length; row++) {
      for (var col = 0; col < shape[row].length; col++) {
        if (shape[row][col] == 0) {
          continue;
        }
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            offsetX + col * cell + 1,
            offsetY + row * cell + 1,
            cell - 2,
            cell - 2,
          ),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, fill);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              offsetX + col * cell + 1,
              offsetY + row * cell + 1,
              cell - 2,
              (cell - 2) / 2,
            ),
            const Radius.circular(3),
          ),
          highlight,
        );
      }
    }
  }
}
