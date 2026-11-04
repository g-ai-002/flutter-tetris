import 'package:flutter_tetris/game/board.dart';
import 'package:flutter_tetris/game/tetromino.dart';
import 'package:flutter_tetris/game/tspin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('T-Spin 判定', () {
    late Board board;

    setUp(() => board = Board());

    test('四角被占且最后动作是旋转，判定为完整 T-Spin', () {
      for (final point in const [(3, 4), (5, 4), (3, 6), (5, 6)]) {
        board.setCell(point.$1, point.$2, TetrominoType.z);
      }
      final info = detectTSpin(
        board: board,
        piece: const ActivePiece(
          type: TetrominoType.t,
          x: 3,
          y: 4,
          rotation: 1,
        ),
        lastActionRotate: true,
      );
      expect(info.isTSpin, isTrue);
      expect(info.isMini, isFalse);
    });

    test('前角只占一个时判定为 T-Spin Mini', () {
      for (final point in const [(3, 4), (5, 4), (3, 6)]) {
        board.setCell(point.$1, point.$2, TetrominoType.z);
      }
      final info = detectTSpin(
        board: board,
        piece: const ActivePiece(
          type: TetrominoType.t,
          x: 3,
          y: 4,
          rotation: 1,
        ),
        lastActionRotate: true,
      );
      expect(info.isTSpin, isTrue);
      expect(info.isMini, isTrue);
    });

    test('最后一次动作不是旋转时不算 T-Spin', () {
      for (var x = 0; x < board.columns; x++) {
        for (var y = 0; y < board.rows; y++) {
          board.setCell(x, y, TetrominoType.j);
        }
      }
      final info = detectTSpin(
        board: board,
        piece: const ActivePiece(
          type: TetrominoType.t,
          x: 3,
          y: 4,
          rotation: 1,
        ),
        lastActionRotate: false,
      );
      expect(info.isTSpin, isFalse);
      expect(info.isMini, isFalse);
    });

    test('角数不足或不是 T 形都不算', () {
      board.setCell(3, 4, TetrominoType.z);
      board.setCell(5, 4, TetrominoType.z);
      expect(
        detectTSpin(
          board: board,
          piece: const ActivePiece(type: TetrominoType.t, x: 3, y: 4),
          lastActionRotate: true,
        ).isTSpin,
        isFalse,
      );
      expect(
        detectTSpin(
          board: board,
          piece: const ActivePiece(type: TetrominoType.l, x: 3, y: 4),
          lastActionRotate: true,
        ).isTSpin,
        isFalse,
      );
    });
  });
}
