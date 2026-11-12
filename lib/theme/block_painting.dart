import 'package:flutter/material.dart';

import '../game/tetromino.dart';
import 'block_palette.dart';

/// 方块绘制：棋盘组件与小尺寸预览共用同一套笔触。
/// 渐变着色器与纯色画笔按颜色、尺寸缓存，逐帧绘制不再新建绘制对象。

/// 新建画笔的次数，用于校验缓存命中。
@visibleForTesting
int debugBlockPaintBuilds = 0;

final Map<(Color, double, double, double, bool), Paint> _fillPaints = {};
final Map<(Color, double), Paint> _flatPaints = {};

/// 仅供测试：清空缓存并重置计数。
@visibleForTesting
void resetBlockPaintCacheForTest() {
  _fillPaints.clear();
  _flatPaints.clear();
  debugBlockPaintBuilds = 0;
}

const int _maxCachedPaints = 256;

/// 立体方块的填充画笔：先按格子尺寸建好着色器，绘制时平移到格子位置。
Paint _fillPaint(Color color, Size size, double opacity, bool active) {
  final key = (color, size.width, size.height, opacity, active);
  final cached = _fillPaints[key];
  if (cached != null) return cached;
  if (_fillPaints.length >= _maxCachedPaints) _fillPaints.clear();
  final top = Color.lerp(color, Colors.white, active ? 0.42 : 0.30)!;
  final bottom = Color.lerp(color, Colors.black, 0.22)!;
  final bounds = (Offset.zero & size).deflate(size.width * 0.055);
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
    ).createShader(bounds);
  debugBlockPaintBuilds++;
  _fillPaints[key] = paint;
  return paint;
}

/// 纯色画笔：描边宽度为 0 时是填充，画笔本身不可变，可安全复用。
Paint _flatPaint(Color color, [double strokeWidth = 0]) {
  final key = (color, strokeWidth);
  final cached = _flatPaints[key];
  if (cached != null) return cached;
  if (_flatPaints.length >= _maxCachedPaints) _flatPaints.clear();
  debugBlockPaintBuilds++;
  final paint = Paint()
    ..color = color
    ..style = strokeWidth > 0 ? PaintingStyle.stroke : PaintingStyle.fill
    ..strokeWidth = strokeWidth;
  _flatPaints[key] = paint;
  return paint;
}

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
  final size = Size(rect.width, rect.height);
  final gap = rect.width * 0.055;
  final shape = RRect.fromRectAndRadius(
    (Offset.zero & size).deflate(gap),
    Radius.circular(rect.width * 0.18),
  );

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

  canvas
    ..save()
    ..translate(rect.left, rect.top)
    ..drawRRect(shape, _fillPaint(color, size, opacity, active))
    ..drawRRect(
      highlight,
      _flatPaint(Colors.white.withValues(alpha: 0.22 * opacity)),
    )
    ..drawRRect(
      shape,
      _flatPaint(Colors.black.withValues(alpha: 0.20 * opacity), 1),
    )
    ..restore();
}

/// 绘制幽灵方块：淡填充 + 虚线感描边。
void paintGhostBlock(Canvas canvas, Rect rect, Color color) {
  if (rect.width <= 1 || rect.height <= 1) return;
  final gap = rect.width * 0.055;
  final shape = RRect.fromRectAndRadius(
    rect.deflate(gap),
    Radius.circular(rect.width * 0.18),
  );
  canvas.drawRRect(shape, _flatPaint(color.withValues(alpha: 0.10)));
  canvas.drawRRect(shape, _flatPaint(color.withValues(alpha: 0.48), 1.6));
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
