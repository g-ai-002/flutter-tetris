import 'package:flutter_tetris/game/bag.dart';
import 'package:flutter_tetris/game/tetromino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('七包随机', () {
    test('每七个方块包含全部七种类型', () {
      final bag = SevenBag(seed: 42);
      for (var round = 0; round < 5; round++) {
        final drawn = <TetrominoType>{};
        for (var i = 0; i < 7; i++) {
          drawn.add(bag.next());
        }
        expect(drawn.length, 7);
      }
    });

    test('预览不消耗队列，且与后续取出顺序一致', () {
      final bag = SevenBag(seed: 7);
      final preview = bag.peek(5);
      expect(preview.length, 5);
      for (final type in preview) {
        expect(bag.next(), type);
      }
      expect(bag.peek(5).length, 5);
    });

    test('相同种子产生相同序列', () {
      final a = SevenBag(seed: 2026);
      final b = SevenBag(seed: 2026);
      for (var i = 0; i < 70; i++) {
        expect(a.next(), b.next());
      }
    });

    test('重置后重新开始抽取完整七包', () {
      final bag = SevenBag(seed: 3);
      for (var i = 0; i < 7; i++) {
        bag.next();
      }
      bag.reset();
      final drawn = <TetrominoType>{};
      for (var i = 0; i < 7; i++) {
        drawn.add(bag.next());
      }
      expect(drawn.length, 7);
    });
  });
}
