import 'package:flutter_tetris/game/level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('关卡定义', () {
    test('12 关编号连续，地形与目标合法', () {
      expect(kLevels.length, 12);
      for (var i = 0; i < kLevels.length; i++) {
        final level = kLevels[i];
        expect(level.id, i + 1);
        expect(level.name, isNotEmpty);
        expect(level.targetLines, greaterThan(0));
        expect(level.timeLimit.inSeconds, greaterThan(0));
        expect(level.terrain.length, lessThanOrEqualTo(18));
        expect(level.seed, greaterThan(0));
        for (final row in level.terrain) {
          expect(row.length, 10, reason: '第 ${level.id} 关地形行宽应为 10');
          expect(RegExp(r'^[.#IOTSZJL]+$').hasMatch(row), isTrue);
        }
      }
      expect(kLevels.map((level) => level.seed).toSet().length, kLevels.length);
    });

    test('评星按剩余时间比例划分', () {
      const level = LevelDefinition(
        id: 1,
        name: '测试',
        brief: '',
        targetLines: 1,
        timeLimit: Duration(seconds: 100),
        terrain: [],
        seed: 1,
      );
      expect(level.starsFor(Duration.zero), 3);
      expect(level.starsFor(const Duration(seconds: 65)), 3);
      expect(level.starsFor(const Duration(seconds: 66)), 2);
      expect(level.starsFor(const Duration(seconds: 88)), 2);
      expect(level.starsFor(const Duration(seconds: 89)), 1);
      expect(level.starsFor(const Duration(seconds: 100)), 1);
    });

    test('按编号查找与下一关', () {
      expect(levelById(1)?.name, '初入长安');
      expect(levelById(12)?.name, '长安归');
      expect(levelById(13), isNull);
      expect(nextLevelOf(kLevels.first)?.id, 2);
      expect(nextLevelOf(kLevels.last), isNull);
    });

    test('垃圾行关卡带有上涌间隔', () {
      expect(kLevels.where((level) => level.hasGarbageRise).length, 5);
      expect(kLevels.first.hasGarbageRise, isFalse);
      expect(kLevels.last.startLevel, greaterThan(1));
    });
  });
}
