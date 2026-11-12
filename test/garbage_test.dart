import 'package:flutter_tetris/game/garbage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('垃圾行生成', () {
    test('未配置规则时不产出缺口', () {
      final spawner = GarbageSpawner(seed: 1);
      expect(spawner.enabled, isFalse);
      expect(spawner.secondsLeft, isNull);
      expect(spawner.advance(const Duration(seconds: 10), 10), isEmpty);
      expect(spawner.rises, 0);
    });

    test('按间隔产出缺口并给出剩余秒数', () {
      final spawner = GarbageSpawner(
        rule: const GarbageRule(interval: Duration(seconds: 2)),
        seed: 3,
      );
      expect(spawner.secondsLeft, 2);
      expect(spawner.advance(const Duration(seconds: 1), 10), isEmpty);
      expect(spawner.secondsLeft, 1);

      final due = spawner.advance(const Duration(seconds: 1), 10);
      expect(due.length, 1);
      expect(due.single.length, 1);
      expect(due.single.single, inInclusiveRange(0, 9));
      expect(spawner.rises, 1);
      expect(spawner.secondsLeft, 2);
    });

    test('一次推进可以补上多个到期批次', () {
      final spawner = GarbageSpawner(
        rule: const GarbageRule(interval: Duration(seconds: 1), rowsPerRise: 3),
        seed: 4,
      );
      final due = spawner.advance(const Duration(milliseconds: 2500), 10);
      expect(due.length, 2);
      expect(due.every((holes) => holes.length == 3), isTrue);
      expect(spawner.rises, 2);
      expect(spawner.secondsLeft, 0);
    });

    test('相同种子产出相同缺口，重置后从头复现', () {
      const rule = GarbageRule(interval: Duration(seconds: 1), rowsPerRise: 2);
      List<int> run() {
        final spawner = GarbageSpawner(rule: rule, seed: 99);
        return [
          for (var i = 0; i < 3; i++) ...spawner.advance(const Duration(seconds: 1), 10).single,
        ];
      }

      final first = run();
      expect(run(), first);

      final spawner = GarbageSpawner(rule: rule, seed: 99);
      final before = [...spawner.advance(const Duration(seconds: 1), 10).single];
      spawner.reset();
      expect(spawner.rises, 0);
      expect(spawner.secondsLeft, 1);
      final after = [...spawner.advance(const Duration(seconds: 1), 10).single];
      expect(after, before);
    });

    test('零间隔与非法列数不会产出缺口', () {
      final spawner = GarbageSpawner(rule: const GarbageRule(interval: Duration.zero), seed: 1);
      expect(spawner.advance(const Duration(seconds: 1), 10), isEmpty);

      final valid = GarbageSpawner(
        rule: const GarbageRule(interval: Duration(seconds: 1)),
        seed: 1,
      );
      expect(valid.advance(const Duration(seconds: 1), 0), isEmpty);
    });
  });
}
