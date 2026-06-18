import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/tetromino.dart';

class BoardPainter extends CustomPainter {
  final GameState state;
  final double cellSize;

  BoardPainter({required this.state, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas);
    _drawLockedCells(canvas);
    _drawGhost(canvas);
    _drawCurrentPiece(canvas);
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    for (var r = 0; r <= state.height; r++) {
      canvas.drawLine(
        Offset(0, r * cellSize),
        Offset(state.width * cellSize, r * cellSize),
        paint,
      );
    }
    for (var c = 0; c <= state.width; c++) {
      canvas.drawLine(
        Offset(c * cellSize, 0),
        Offset(c * cellSize, state.height * cellSize),
        paint,
      );
    }
  }

  void _drawLockedCells(Canvas canvas) {
    for (var r = 0; r < state.height; r++) {
      for (var c = 0; c < state.width; c++) {
        final color = state.board[r][c];
        if (color != 0) {
          _drawCell(canvas, c, r, Color(color));
        }
      }
    }
  }

  void _drawGhost(Canvas canvas) {
    final ghostY = state.ghostY;
    if (ghostY == state.currentY) return;
    final shape = state.currentPiece.shape;
    final paint = Paint()
      ..color = Color(state.currentPiece.color).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Color(state.currentPiece.color).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var r = 0; r < shape.length; r++) {
      for (var c = 0; c < shape[r].length; c++) {
        if (shape[r][c] == 0) continue;
        final x = (state.currentX + c) * cellSize;
        final y = (ghostY + r) * cellSize;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 1, y + 1, cellSize - 2, cellSize - 2),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, paint);
        canvas.drawRRect(rect, borderPaint);
      }
    }
  }

  void _drawCurrentPiece(Canvas canvas) {
    final shape = state.currentPiece.shape;
    for (var r = 0; r < shape.length; r++) {
      for (var c = 0; c < shape[r].length; c++) {
        if (shape[r][c] == 0) continue;
        final y = (state.currentY + r) * cellSize;
        if (y < 0) continue;
        _drawCell(canvas, state.currentX + c, state.currentY + r,
            Color(state.currentPiece.color));
      }
    }
  }

  void _drawCell(Canvas canvas, int col, int row, Color color) {
    final x = col * cellSize;
    final y = row * cellSize;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x + 1, y + 1, cellSize - 2, cellSize - 2),
      const Radius.circular(3),
    );
    // main fill
    canvas.drawRRect(rect, Paint()..color = color);
    // highlight
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 1, y + 1, cellSize - 2, (cellSize - 2) / 2),
        const Radius.circular(3),
      ),
      highlight,
    );
    // border
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;
}

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
