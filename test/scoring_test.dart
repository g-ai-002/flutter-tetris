import 'package:flutter_tetris/game/scoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('计分', () {
    test('普通消行按等级放大', () {
      expect(clearScore(lines: 1, level: 1), 100);
      expect(clearScore(lines: 2, level: 1), 300);
      expect(clearScore(lines: 3, level: 1), 500);
      expect(clearScore(lines: 4, level: 2), 1600);
      expect(clearScore(lines: 0, level: 5), 0);
    });

    test('T-Spin 与 Mini 使用不同基础分', () {
      expect(clearScore(lines: 0, level: 1, tSpin: true), 400);
      expect(clearScore(lines: 1, level: 1, tSpin: true), 800);
      expect(clearScore(lines: 2, level: 1, tSpin: true), 1200);
      expect(clearScore(lines: 3, level: 1, tSpin: true), 1600);
      expect(clearScore(lines: 1, level: 1, tSpin: true, mini: true), 200);
    });

    test('连续奖励提升到 1.5 倍', () {
      expect(clearScore(lines: 4, level: 1, backToBack: true), 1200);
      expect(clearScore(lines: 1, level: 2, backToBack: true), 300);
    });

    test('连击与全消奖励累加', () {
      expect(clearScore(lines: 1, level: 1, combo: 2), 200);
      expect(clearScore(lines: 4, level: 1, perfectClear: true), 2800);
      expect(
        clearScore(
          lines: 4,
          level: 2,
          backToBack: true,
          perfectClear: true,
          combo: 1,
        ),
        6500,
      );
    });
  });

  group('等级与速度', () {
    test('每十行升一级，最高 15 级', () {
      expect(levelForLines(0), 1);
      expect(levelForLines(9), 1);
      expect(levelForLines(10), 2);
      expect(levelForLines(39), 4);
      expect(levelForLines(400), 15);
    });

    test('下落间隔随等级递减并收敛', () {
      expect(gravityForLevel(1).inMilliseconds, 1000);
      expect(gravityForLevel(5).inMilliseconds, 355);
      expect(gravityForLevel(15).inMilliseconds, 7);
      expect(gravityForLevel(99).inMilliseconds, 7);
    });
  });
}
