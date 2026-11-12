import 'board.dart';
import 'tetromino.dart';

/// T-Spin 判定结果。
class TSpinInfo {
  const TSpinInfo({required this.isTSpin, required this.isMini});

  const TSpinInfo.none() : isTSpin = false, isMini = false;

  final bool isTSpin;
  final bool isMini;
}

/// 三角判定：T 形方块最后一次动作是旋转，且中心格四角至少三处被占据。
/// 前两个角没有同时被占据时记为 T-Spin Mini。
TSpinInfo detectTSpin({
  required Board board,
  required ActivePiece piece,
  required bool lastActionRotate,
}) {
  if (piece.type != TetrominoType.t || !lastActionRotate) {
    return const TSpinInfo.none();
  }
  final corners = _cornersOf(piece);
  var occupied = 0;
  for (final point in corners) {
    if (_isBlocked(board, point.$1, point.$2)) occupied++;
  }
  if (occupied < 3) return const TSpinInfo.none();

  final fronts = switch (piece.rotation) {
    0 => [corners[0], corners[1]],
    1 => [corners[1], corners[3]],
    2 => [corners[2], corners[3]],
    _ => [corners[0], corners[2]],
  };
  final filled = fronts.where((p) => _isBlocked(board, p.$1, p.$2)).length;
  return TSpinInfo(isTSpin: true, isMini: filled < 2);
}

List<(int, int)> _cornersOf(ActivePiece piece) {
  final cx = piece.x + 1;
  final cy = piece.y + 1;
  return [(cx - 1, cy - 1), (cx + 1, cy - 1), (cx - 1, cy + 1), (cx + 1, cy + 1)];
}

bool _isBlocked(Board board, int x, int y) {
  if (x < 0 || x >= board.columns || y >= board.rows) return true;
  if (y < 0) return false;
  return board.at(x, y) != null;
}
