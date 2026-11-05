import 'package:flutter_tetris/game/board.dart';
import 'package:flutter_tetris/game/tetromino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('场地', () {
    late Board board;

    setUp(() => board = Board());

    test('默认 10 列 21 行，其中顶部 1 行隐藏', () {
      expect(board.columns, 10);
      expect(board.rows, 21);
      expect(board.hiddenRows, 1);
    });

    test('越界与已占用格子不能放置', () {
      const i = ActivePiece(type: TetrominoType.i, x: 0, y: 0);
      expect(board.fits(i.blocks), isTrue);
      expect(
        board.fits(const ActivePiece(type: TetrominoType.i, x: 7, y: 0).blocks),
        isFalse,
      );
      expect(
        board.fits(
          const ActivePiece(type: TetrominoType.i, x: -1, y: 0).blocks,
        ),
        isFalse,
      );
      expect(
        board.fits(
          const ActivePiece(type: TetrominoType.o, x: 3, y: 20).blocks,
        ),
        isFalse,
      );
      board.setCell(4, 20, TetrominoType.t);
      expect(
        board.fits(
          const ActivePiece(type: TetrominoType.o, x: 3, y: 19).blocks,
        ),
        isFalse,
      );
    });

    test('落定后可读取格子类型', () {
      const piece = ActivePiece(type: TetrominoType.t, x: 3, y: 5);
      board.lock(piece.blocks, piece.type);
      for (final block in piece.blocks) {
        expect(board.at(block.x, block.y), TetrominoType.t);
      }
      expect(board.filledCount, 4);
      expect(board.isEmpty, isFalse);
      board.reset();
      expect(board.isEmpty, isTrue);
    });

    test('识别并删除满行，上方内容整体下移', () {
      for (var x = 0; x < board.columns; x++) {
        board.setCell(x, 20, TetrominoType.i);
        board.setCell(x, 19, TetrominoType.o);
      }
      board.setCell(0, 18, TetrominoType.t);
      expect(board.fullRows(), [20, 19]);

      board.removeRows([20, 19]);
      expect(board.fullRows(), isEmpty);
      expect(board.at(0, 20), TetrominoType.t);
      expect(board.at(0, 19), isNull);
      expect(board.filledCount, 1);
    });

    test('堆叠高度从底部计算', () {
      expect(board.stackHeight, 0);
      board.setCell(5, 20, TetrominoType.z);
      expect(board.stackHeight, 1);
      board.setCell(5, 11, TetrominoType.z);
      expect(board.stackHeight, 10);
    });

    test('调试字符画只包含可视区域', () {
      board.setCell(0, 20, TetrominoType.j);
      final lines = board.debugString().split('\n');
      expect(lines.length, 20);
      expect(lines.last.startsWith('J'), isTrue);
      expect(lines.first.length, 10);
    });

    test('载入关卡地形时贴底摆放并标记垃圾格', () {
      board.loadTerrain(['##.######.', '###.######']);
      expect(board.at(0, 20), TetrominoType.o);
      expect(board.at(3, 20), isNull);
      expect(board.isGarbage(0, 20), isTrue);
      expect(board.at(0, 19), TetrominoType.o);
      expect(board.at(2, 19), isNull);
      expect(board.filledCount, 17);

      board.loadTerrain(['IIIIIIIIII']);
      expect(board.at(0, 20), TetrominoType.i);
      expect(board.isGarbage(0, 20), isFalse);
    });

    test('删除满行时垃圾标记一起下移', () {
      board.loadTerrain(['##.######.', '###.######']);
      board.setCell(3, 20, TetrominoType.t);
      expect(board.fullRows(), [20]);
      board.removeRows([20]);
      expect(board.at(0, 20), TetrominoType.o);
      expect(board.isGarbage(0, 20), isTrue);
      expect(board.at(2, 20), isNull);
      expect(board.isGarbage(2, 20), isFalse);
    });

    test('垃圾行上涌时整体上移并保留缺口', () {
      board.loadTerrain(['###.######']);
      expect(board.raiseGarbage([4]), isFalse);
      expect(board.isGarbage(4, 20), isFalse);
      expect(board.at(4, 20), isNull);
      expect(board.isGarbage(0, 20), isTrue);
      expect(board.at(0, 19), TetrominoType.o);
      expect(board.at(3, 19), isNull);
      expect(board.filledCount, 18);
    });

    test('顶部被垃圾行挤出时返回溢出', () {
      board.setCell(0, 0, TetrominoType.t);
      expect(board.raiseGarbage([5]), isTrue);
    });
  });
}
