import 'board.dart';
import 'tetromino.dart';

/// SRS 踢墙位移表，y 轴向下（与标准表的 y 轴向上相反）。
///
/// 键为「起始旋转态 -> 目标旋转态」，列表第一项通常为 (0,0)。
const Map<String, List<Block>> kJlstzKicks = {
  '01': [Block(0, 0), Block(-1, 0), Block(-1, -1), Block(0, 2), Block(-1, 2)],
  '10': [Block(0, 0), Block(1, 0), Block(1, 1), Block(0, -2), Block(1, -2)],
  '12': [Block(0, 0), Block(1, 0), Block(1, 1), Block(0, -2), Block(1, -2)],
  '21': [Block(0, 0), Block(-1, 0), Block(-1, -1), Block(0, 2), Block(-1, 2)],
  '23': [Block(0, 0), Block(1, 0), Block(1, -1), Block(0, 2), Block(1, 2)],
  '32': [Block(0, 0), Block(-1, 0), Block(-1, 1), Block(0, -2), Block(-1, -2)],
  '30': [Block(0, 0), Block(-1, 0), Block(-1, 1), Block(0, -2), Block(-1, -2)],
  '03': [Block(0, 0), Block(1, 0), Block(1, -1), Block(0, 2), Block(1, 2)],
};

const Map<String, List<Block>> kIKicks = {
  '01': [Block(0, 0), Block(-2, 0), Block(1, 0), Block(-2, 1), Block(1, -2)],
  '10': [Block(0, 0), Block(2, 0), Block(-1, 0), Block(2, -1), Block(-1, 2)],
  '12': [Block(0, 0), Block(-1, 0), Block(2, 0), Block(-1, -2), Block(2, 1)],
  '21': [Block(0, 0), Block(1, 0), Block(-2, 0), Block(1, 2), Block(-2, -1)],
  '23': [Block(0, 0), Block(2, 0), Block(-1, 0), Block(2, -1), Block(-1, 2)],
  '32': [Block(0, 0), Block(-2, 0), Block(1, 0), Block(-2, 1), Block(1, -2)],
  '30': [Block(0, 0), Block(1, 0), Block(-2, 0), Block(1, 2), Block(-2, -1)],
  '03': [Block(0, 0), Block(-1, 0), Block(2, 0), Block(-1, -2), Block(2, 1)],
};

/// 返回旋转后的方块；被墙、地面或堆叠挡住时返回 null。
///
/// [direction] 为 1 顺时针、-1 逆时针，180 度旋转不参与踢墙。
ActivePiece? tryRotate(Board board, ActivePiece piece, int direction) {
  if (direction != 1 && direction != -1) return null;
  final from = piece.rotation;
  final to = (from + direction + 4) % 4;
  if (piece.type == TetrominoType.o) {
    return piece.copyWith(rotation: to);
  }
  final kicks = piece.type == TetrominoType.i ? kIKicks : kJlstzKicks;
  final offsets = kicks['$from$to'] ?? const [Block(0, 0)];
  for (final offset in offsets) {
    final candidate = ActivePiece(
      type: piece.type,
      x: piece.x + offset.x,
      y: piece.y + offset.y,
      rotation: to,
    );
    if (board.fits(candidate.blocks)) return candidate;
  }
  return null;
}
