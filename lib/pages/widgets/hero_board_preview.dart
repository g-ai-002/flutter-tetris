import 'package:flutter/material.dart';

import '../../game/tetromino.dart';
import '../../theme/block_painting.dart';
import '../../theme/block_palette.dart';

/// 首页装饰：一局进行中的缩略棋盘，右下角盖一方朱印。
class HeroBoardPreview extends StatelessWidget {
  const HeroBoardPreview({
    super.key,
    required this.palette,
    this.size = const Size(150, 195),
  });

  final BlockPalette palette;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.boardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: palette.wellShadow,
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: CustomPaint(
          size: size,
          painter: _HeroBoardPainter(palette: palette),
        ),
      ),
    );
  }
}

class _HeroBoardPainter extends CustomPainter {
  const _HeroBoardPainter({required this.palette});

  final BlockPalette palette;

  static const List<String> _rows = [
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..I.......',
    '..I....S..',
    '.......SS.',
    '..T....S..',
    '.TTT..J...',
    '..L..JJJ..',
    'IIII.OOLL.',
    '.ZZ.OO.LL.',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    paintBoardBackground(canvas, rect, palette);

    final cell = size.width / 10;
    final gridPaint = Paint()
      ..color = palette.gridLine
      ..strokeWidth = 0.7;
    for (var x = 1; x < 10; x++) {
      canvas.drawLine(
        Offset(x * cell, 0),
        Offset(x * cell, size.height),
        gridPaint,
      );
    }
    final top = size.height - _rows.length * cell;
    for (var y = 1; y < _rows.length; y++) {
      final dy = top + y * cell;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    for (var row = 0; row < _rows.length; row++) {
      final line = _rows[row];
      for (var col = 0; col < line.length; col++) {
        final type = tetrominoFromCode(line[col]);
        if (type == null) continue;
        final cellRect = Rect.fromLTWH(
          col * cell,
          top + row * cell,
          cell,
          cell,
        );
        paintBlock(canvas, cellRect, palette.colorOf(type));
      }
    }

    // 正在下落的 T 形方块。
    const active = ActivePiece(type: TetrominoType.t, x: 4, y: 0);
    for (final block in active.blocks) {
      final cellRect = Rect.fromLTWH(
        block.x * cell,
        top + block.y * cell,
        cell,
        cell,
      );
      paintBlock(
        canvas,
        cellRect,
        palette.colorOf(TetrominoType.t),
        active: true,
      );
    }

    _paintSeal(canvas, size);
  }

  void _paintSeal(Canvas canvas, Size size) {
    final sealSize = size.width * 0.15;
    final rect = Rect.fromLTWH(
      size.width - sealSize - 9,
      size.height - sealSize - 9,
      sealSize,
      sealSize,
    );
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(-0.06);
    final shape = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: sealSize, height: sealSize),
      Radius.circular(sealSize * 0.14),
    );
    canvas.drawRRect(shape, Paint()..color = const Color(0xFFB03A2E));
    final painter = TextPainter(
      text: TextSpan(
        text: '方',
        style: TextStyle(
          color: const Color(0xFFFFF6EA),
          fontSize: sealSize * 0.62,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HeroBoardPainter oldDelegate) =>
      oldDelegate.palette != palette;
}
