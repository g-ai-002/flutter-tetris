import 'package:flutter_tetris/game/tetromino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('方块定义', () {
    test('每种方块四个旋转态都恰好四格', () {
      for (final type in TetrominoType.values) {
        final states = kTetrominoShapes[type]!;
        expect(states.length, 4, reason: type.code);
        for (final state in states) {
          expect(state.length, 4, reason: '${type.code} 旋转态格数');
          expect(state.toSet().length, 4, reason: '${type.code} 旋转态重复格');
        }
      }
    });

    test('O 形旋转后形状不变，其它方块四个旋转态互不相同', () {
      for (final type in TetrominoType.values) {
        final states = kTetrominoShapes[type]!;
        final signatures = states
            .map((state) => (state.map((b) => '${b.x},${b.y}').toList()..sort()).join('|'))
            .toSet();
        if (type == TetrominoType.o) {
          expect(signatures.length, 1);
        } else {
          expect(signatures.length, 4, reason: type.code);
        }
      }
    });

    test('出生位置统一从第 3 列开始，落在场地中央', () {
      for (final type in TetrominoType.values) {
        final piece = ActivePiece(type: type, x: kSpawnColumn, y: 0);
        final xs = piece.blocks.map((b) => b.x).toList()..sort();
        expect(xs.first >= 3, isTrue, reason: type.code);
        expect(xs.last <= 6, isTrue, reason: type.code);
      }
    });

    test('方块代号完整', () {
      expect(TetrominoType.values.map((t) => t.code).join(), 'IOTSZJL');
    });
  });
}
