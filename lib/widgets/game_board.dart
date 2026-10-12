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
    return Container(
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
    );
  }
}
