import 'package:flutter_tetris/game/board.dart';
import 'package:flutter_tetris/game/srs.dart';
import 'package:flutter_tetris/game/tetromino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SRS 旋转与踢墙', () {
    late Board board;

    setUp(() => board = Board());

    test('开阔场地顺时针旋转成功', () {
      const piece = ActivePiece(type: TetrominoType.t, x: 3, y: 5);
      final rotated = tryRotate(board, piece, 1);
      expect(rotated, isNotNull);
      expect(rotated!.rotation, 1);
      expect(rotated.x, 3);
      expect(rotated.y, 5);
    });

    test('抵住左墙时借踢墙完成旋转', () {
      // T 形竖立态，包围盒向左伸出一格，顺时针旋转需要左移后仍越界，
      // 标准踢墙表会把它推到右侧一格。
      const piece = ActivePiece(type: TetrominoType.t, x: -1, y: 5, rotation: 1);
      expect(board.fits(piece.blocks), isTrue);
      final rotated = tryRotate(board, piece, 1);
      expect(rotated, isNotNull);
      expect(rotated!.rotation, 2);
      expect(rotated.x, 0);
    });

    test('被完全堵死时旋转失败', () {
      for (var y = 0; y < board.rows; y++) {
        for (var x = 0; x < board.columns; x++) {
          board.setCell(x, y, TetrominoType.z);
        }
      }
      const piece = ActivePiece(type: TetrominoType.t, x: 3, y: 5);
      expect(tryRotate(board, piece, 1), isNull);
      expect(tryRotate(board, piece, -1), isNull);
    });

    test('O 形旋转不移动也不变形', () {
      const piece = ActivePiece(type: TetrominoType.o, x: 3, y: 8);
      final rotated = tryRotate(board, piece, 1)!;
      expect(rotated.rotation, 1);
      expect(rotated.x, piece.x);
      expect(rotated.y, piece.y);
      expect(rotated.blocks.toSet(), piece.blocks.toSet());
    });

    test('逆时针旋转回到出生态', () {
      const piece = ActivePiece(type: TetrominoType.i, x: 3, y: 5);
      final left = tryRotate(board, piece, -1)!;
      expect(left.rotation, 3);
      final back = tryRotate(board, left, 1)!;
      expect(back.rotation, 0);
      expect(back.blocks, containsAll(piece.blocks));
    });

    test('非法方向返回 null', () {
      const piece = ActivePiece(type: TetrominoType.l, x: 3, y: 5);
      expect(tryRotate(board, piece, 0), isNull);
      expect(tryRotate(board, piece, 2), isNull);
    });
  });
}
