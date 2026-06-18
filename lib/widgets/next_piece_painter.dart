import 'package:flutter/material.dart';
import '../models/tetromino.dart';

class NextPiecePainter extends CustomPainter {
  final Tetromino piece;

  NextPiecePainter({required this.piece});

  @override
  void paint(Canvas canvas, Size size) {
    final shape = piece.shape;
    final cellSize = size.width / 4;
    final offsetX = (size.width - shape[0].length * cellSize) / 2;
    final offsetY = (size.height - shape.length * cellSize) / 2;

    for (var r = 0; r < shape.length; r++) {
      for (var c = 0; c < shape[r].length; c++) {
        if (shape[r][c] == 0) continue;
        final x = offsetX + c * cellSize;
        final y = offsetY + r * cellSize;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 1, y + 1, cellSize - 2, cellSize - 2),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, Paint()..color = Color(piece.color));
        canvas.drawRRect(
          rect,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.25)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant NextPiecePainter oldDelegate) =>
      piece.type != oldDelegate.piece.type;
}
