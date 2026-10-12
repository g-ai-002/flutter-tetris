import 'package:flutter/material.dart';
import '../models/game_state.dart';
import 'next_piece_painter.dart';

/// 下一个方块的紧凑预览，尺寸由 [size] 控制。
class NextPiecePreview extends StatelessWidget {
  final GameState state;
  final double size;

  const NextPiecePreview({super.key, required this.state, this.size = 48});

  @override
  Widget build(BuildContext context) {
    if (state.nextPiece == null) return const SizedBox.shrink();
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: NextPiecePainter(piece: state.nextPiece!),
      ),
    );
  }
}
