import 'package:flutter_tetris/game/seeded_random.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('确定性随机数', () {
    test('同一种子在不同实例上产出相同序列', () {
      final a = SeededRandom(20261105);
      final b = SeededRandom(20261105);
      final first = [for (var i = 0; i < 20; i++) a.nextInt(1000)];
      final second = [for (var i = 0; i < 20; i++) b.nextInt(1000)];
      expect(first, second);
    });

    test('固定种子的首个结果保持稳定', () {
      expect(SeededRandom(1).nextInt(100), 71);
    });

    test('不同种子序列不同且取值在范围内', () {
      final a = SeededRandom(7);
      final b = SeededRandom(8);
      final left = [for (var i = 0; i < 30; i++) a.nextInt(16)];
      final right = [for (var i = 0; i < 30; i++) b.nextInt(16)];
      expect(left, isNot(right));
      expect(left.every((value) => value >= 0 && value < 16), isTrue);
    });

    test('零种子会被替换，非法上界抛错', () {
      final zero = SeededRandom(0);
      expect(zero.nextInt(10), inInclusiveRange(0, 9));
      expect(() => zero.nextInt(0), throwsArgumentError);
    });
  });
}
