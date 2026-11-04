import 'package:flutter/material.dart';

import '../../game/tetromino.dart';
import '../../theme/block_painting.dart';

/// 方块小预览：暂存区与下一个队列共用。
class PiecePreview extends StatelessWidget {
  const PiecePreview({
    super.key,
    required this.type,
    required this.color,
    this.size = 44,
    this.faded = false,
  });

  /// 为 null 时绘制空框。
  final TetrominoType? type;
  final Color color;
  final double size;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: type == null
          ? DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.16),
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                border: Border.all(
                  color: colors.outline.withValues(alpha: 0.7),
                ),
              ),
            )
          : CustomPaint(
              painter: _PiecePainter(type: type!, color: color, faded: faded),
            ),
    );
  }
}

class _PiecePainter extends CustomPainter {
  const _PiecePainter({
    required this.type,
    required this.color,
    required this.faded,
  });

  final TetrominoType type;
  final Color color;
  final bool faded;

  @override
  void paint(Canvas canvas, Size size) {
    final blocks = kTetrominoShapes[type]![0];
    paintMiniPiece(
      canvas,
      size,
      blocks,
      faded ? color.withValues(alpha: 0.35) : color,
    );
  }

  @override
  bool shouldRepaint(covariant _PiecePainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.color != color ||
      oldDelegate.faded != faded;
}
