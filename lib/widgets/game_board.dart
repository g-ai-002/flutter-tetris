import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import 'board_painter.dart';

class GameBoard extends StatelessWidget {
  final GameProvider game;
  final GameState state;
  final double boardW;
  final double boardH;
  final double cellSize;

  const GameBoard({
    super.key,
    required this.game,
    required this.state,
    required this.boardW,
    required this.boardH,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (state.isGameOver) {
          game.start();
        } else if (!state.isPaused) {
          game.rotate();
        }
      },
      onPanEnd: (details) {
        if (state.isGameOver || state.isPaused) return;
        final velocity = details.velocity.pixelsPerSecond;
        final dx = velocity.dx.abs();
        final dy = velocity.dy.abs();
        if (dx > dy && dx > 200) {
          if (velocity.dx > 0) {
            game.moveRight();
          } else {
            game.moveLeft();
          }
        } else if (dy > dx && dy > 200 && velocity.dy > 0) {
          game.hardDrop();
        }
      },
      child: Container(
        width: boardW,
        height: boardH,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CustomPaint(
            painter: BoardPainter(state: state, cellSize: cellSize),
          ),
        ),
      ),
    );
  }
}
