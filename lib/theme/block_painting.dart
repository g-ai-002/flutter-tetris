import 'package:flutter/material.dart';

import '../game/tetromino.dart';
import 'block_palette.dart';

/// 方块绘制：棋盘组件与小尺寸预览共用同一套笔触。

/// 绘制棋盘底色，场地与首页缩略棋盘共用同一套皮肤渐变。
void paintBoardBackground(Canvas canvas, Rect rect, BlockPalette palette) {
  canvas.drawRect(
    rect,
    Paint()..shader = palette.boardGradient.createShader(rect),
  );
}

/// 绘制一块已落定的方块。
/// [rect] 为格子的完整区域，内部会留出缝隙并描边，
/// 顶部提亮、底部压暗，模拟实体方块的立体感。
void paintBlock(
  Canvas canvas,
  Rect rect,
  Color color, {
  double opacity = 1,
  bool active = false,
}) {
  if (rect.width <= 1 || rect.height <= 1) return;
  final gap = rect.width * 0.055;
  final shape = RRect.fromRectAndRadius(
    rect.deflate(gap),
    Radius.circular(rect.width * 0.18),
  );

  final top = Color.lerp(color, Colors.white, active ? 0.42 : 0.30)!;
  final bottom = Color.lerp(color, Colors.black, 0.22)!;
  final paint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        top.withValues(alpha: opacity),
        color.withValues(alpha: opacity),
        bottom.withValues(alpha: opacity),
      ],
      stops: const [0, 0.55, 1],
    ).createShader(shape.outerRect);
  canvas.drawRRect(shape, paint);

  // 顶部高光，让方块在深色背景上也有厚度。
  final highlight = RRect.fromRectAndRadius(
    Rect.fromLTWH(
      shape.left + shape.width * 0.14,
      shape.top + shape.height * 0.10,
      shape.width * 0.72,
      shape.height * 0.18,
    ),
    Radius.circular(shape.width * 0.09),
  );
  canvas.drawRRect(
    highlight,
    Paint()..color = Colors.white.withValues(alpha: 0.22 * opacity),
  );

  canvas.drawRRect(
    shape,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black.withValues(alpha: 0.20 * opacity),
  );
}

/// 绘制幽灵方块：淡填充 + 虚线感描边。
void paintGhostBlock(Canvas canvas, Rect rect, Color color) {
  if (rect.width <= 1 || rect.height <= 1) return;
  final gap = rect.width * 0.055;
  final shape = RRect.fromRectAndRadius(
    rect.deflate(gap),
    Radius.circular(rect.width * 0.18),
  );
  canvas.drawRRect(shape, Paint()..color = color.withValues(alpha: 0.10));
  canvas.drawRRect(
    shape,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = color.withValues(alpha: 0.48),
  );
}

/// 小预览里绘制方块，按包围盒居中。
void paintMiniPiece(Canvas canvas, Size size, List<Block> blocks, Color color) {
  if (blocks.isEmpty) return;
  var minX = blocks.first.x;
  var maxX = blocks.first.x;
  var minY = blocks.first.y;
  var maxY = blocks.first.y;
  for (final block in blocks) {
    if (block.x < minX) minX = block.x;
    if (block.x > maxX) maxX = block.x;
    if (block.y < minY) minY = block.y;
    if (block.y > maxY) maxY = block.y;
  }
  final cols = maxX - minX + 1;
  final rows = maxY - minY + 1;
  final cell = (size.shortestSide * 0.82) / (cols > rows ? cols : rows);
  final width = cols * cell;
  final height = rows * cell;
  final left = (size.width - width) / 2;
  final top = (size.height - height) / 2;
  for (final block in blocks) {
    final rect = Rect.fromLTWH(
      left + (block.x - minX) * cell,
      top + (block.y - minY) * cell,
      cell,
      cell,
    );
    paintBlock(canvas, rect, color);
  }
}
