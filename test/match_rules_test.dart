import 'package:flutter_tetris/game/daily_challenge.dart';
import 'package:flutter_tetris/game/game_mode.dart';
import 'package:flutter_tetris/game/garbage.dart';
import 'package:flutter_tetris/game/level.dart';
import 'package:flutter_tetris/game/match_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('对局规则', () {
    test('经典模式没有目标行与限时', () {
      const rules = MatchRules(mode: GameMode.endless);
      expect(rules.title, '经典模式');
      expect(rules.isLevel, isFalse);
      expect(rules.levelId, isNull);
      expect(rules.targetLines, isNull);
      expect(rules.timeLimit, isNull);
      expect(rules.startLevel, 1);
      expect(rules.terrain, isEmpty);
      expect(rules.garbage, isNull);
      expect(rules.starsFor(Duration.zero), 0);
    });

    test('竞速与计时模式由玩法提供目标', () {
      const sprint = MatchRules(mode: GameMode.sprint);
      expect(sprint.targetLines, 40);
      expect(sprint.timeLimit, isNull);

      const ultra = MatchRules(mode: GameMode.ultra);
      expect(ultra.targetLines, isNull);
      expect(ultra.timeLimit, const Duration(seconds: 120));
    });

    test('关卡规则覆盖目标、限时、起始等级与垃圾行', () {
      const level = LevelDefinition(
        id: 7,
        name: '悬河',
        brief: '',
        targetLines: 15,
        timeLimit: Duration(seconds: 120),
        terrain: ['##.###.##.'],
        startLevel: 3,
        garbage: GarbageRule(interval: Duration(seconds: 24)),
        seed: 107,
      );
      const rules = MatchRules(mode: GameMode.level, level: level);

      expect(rules.title, '第 7 关 · 悬河');
      expect(rules.isLevel, isTrue);
      expect(rules.levelId, 7);
      expect(rules.targetLines, 15);
      expect(rules.timeLimit, const Duration(seconds: 120));
      expect(rules.startLevel, 3);
      expect(rules.terrain, ['##.###.##.']);
      expect(rules.garbage?.rowsPerRise, 1);
      expect(rules.starsFor(const Duration(seconds: 30)), 3);
      expect(rules.starsFor(const Duration(seconds: 110)), 1);
    });

    test('每日挑战提供日期标题、固定种子与两分钟限时', () {
      final daily = DailyChallenge.forDate(DateTime(2026, 11, 5));
      final rules = MatchRules(mode: GameMode.daily, daily: daily);
      expect(rules.title, '每日挑战 · 11 月 5 日');
      expect(rules.isDaily, isTrue);
      expect(rules.isLevel, isFalse);
      expect(rules.seed, daily.seed);
      expect(rules.targetLines, isNull);
      expect(rules.timeLimit, const Duration(seconds: 120));
      expect(rules.terrain, isEmpty);
      expect(rules.starsFor(Duration.zero), 0);
    });

    test('关卡没有垃圾行时规则为空', () {
      const level = LevelDefinition(
        id: 1,
        name: '初入长安',
        brief: '',
        targetLines: 3,
        timeLimit: Duration(seconds: 90),
        terrain: [],
        seed: 101,
      );
      const rules = MatchRules(mode: GameMode.level, level: level);
      expect(rules.garbage, isNull);
      expect(rules.timeLimit, const Duration(seconds: 90));
    });
  });
}
