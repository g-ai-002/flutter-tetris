import 'package:flutter_tetris/game/achievement.dart';
import 'package:flutter_tetris/game/daily_challenge.dart';
import 'package:flutter_tetris/game/game_mode.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

GameResult result({
  GameMode mode = GameMode.endless,
  int score = 1200,
  int lines = 7,
  int level = 1,
  int pieces = 30,
  int maxCombo = 2,
  int elapsedMs = 60000,
  bool won = false,
  int? levelId,
  int stars = 0,
  String? challengeKey,
  int tetrises = 0,
  int tSpins = 0,
  int perfectClears = 0,
}) {
  return GameResult(
    mode: mode,
    score: score,
    lines: lines,
    level: level,
    pieces: pieces,
    maxCombo: maxCombo,
    elapsed: Duration(milliseconds: elapsedMs),
    won: won,
    reason: won ? '完成 40 行' : '方块堆到了顶部',
    levelId: levelId,
    stars: stars,
    challengeKey: challengeKey,
    tetrises: tetrises,
    tSpins: tSpins,
    perfectClears: perfectClears,
  );
}

void main() {
  group('本地存储', () {
    test('偏好默认值与写入', () async {
      final storage = await prepareStorage();
      expect(storage.darkMode, isFalse);
      expect(storage.soundEnabled, isTrue);
      expect(storage.musicEnabled, isTrue);
      expect(storage.hapticsEnabled, isTrue);
      expect(storage.showGhost, isTrue);
      expect(storage.showGrid, isTrue);

      await storage.setDarkMode(true);
      await storage.setShowGhost(false);
      await storage.setShowGrid(false);
      await storage.setSoundEnabled(false);
      await storage.setMusicEnabled(false);
      await storage.setHapticsEnabled(false);

      expect(storage.darkMode, isTrue);
      expect(storage.showGhost, isFalse);
      expect(storage.showGrid, isFalse);
      expect(storage.soundEnabled, isFalse);
      expect(storage.musicEnabled, isFalse);
      expect(storage.hapticsEnabled, isFalse);
    });

    test('记录最高分、累计统计与对局次数', () async {
      final storage = await prepareStorage();
      final outcome = await storage.recordResult(result());
      expect(outcome.newBestScore, isTrue);
      expect(outcome.newBestTime, isFalse);
      expect(storage.bestScore(GameMode.endless), 1200);
      expect(storage.bestLines(GameMode.endless), 7);
      expect(storage.plays(GameMode.endless), 1);
      expect(storage.gamesPlayed, 1);
      expect(storage.totalLines, 7);
      expect(storage.totalScore, 1200);

      final lower = await storage.recordResult(result(score: 900, lines: 3));
      expect(lower.newBestScore, isFalse);
      expect(storage.bestScore(GameMode.endless), 1200);
      expect(storage.bestLines(GameMode.endless), 7);
      expect(storage.plays(GameMode.endless), 2);
      expect(storage.totalLines, 10);
    });

    test('40 行竞速单独记录最快时间', () async {
      final storage = await prepareStorage();
      final first = await storage.recordResult(
        result(mode: GameMode.sprint, score: 300, lines: 40, elapsedMs: 95000, won: true),
      );
      expect(first.newBestTime, isTrue);
      expect(storage.bestSprintTimeMs, 95000);

      await storage.recordResult(
        result(mode: GameMode.sprint, score: 400, lines: 40, elapsedMs: 120000, won: true),
      );
      expect(storage.bestSprintTimeMs, 95000);

      final faster = await storage.recordResult(
        result(mode: GameMode.sprint, score: 500, lines: 40, elapsedMs: 80000, won: true),
      );
      expect(faster.newBestTime, isTrue);
      expect(storage.bestSprintTimeMs, 80000);
      expect(storage.bestScore(GameMode.sprint), 500);
    });

    test('未完成 40 行不写入最快时间', () async {
      final storage = await prepareStorage();
      final outcome = await storage.recordResult(
        result(mode: GameMode.sprint, lines: 12, elapsedMs: 1000),
      );
      expect(outcome.newBestTime, isFalse);
      expect(storage.bestSprintTimeMs, isNull);
    });

    test('清空纪录保留界面偏好', () async {
      final storage = await prepareStorage();
      await storage.setDarkMode(true);
      await storage.recordResult(result());
      await storage.clearRecords();

      expect(storage.bestScore(GameMode.endless), 0);
      expect(storage.gamesPlayed, 0);
      expect(storage.totalLines, 0);
      expect(storage.totalScore, 0);
      expect(storage.darkMode, isTrue);
    });

    test('关卡纪录保存星级、最高分并解锁下一关', () async {
      final storage = await prepareStorage();
      expect(storage.isLevelUnlocked(1), isTrue);
      expect(storage.isLevelUnlocked(2), isFalse);

      final first = await storage.recordResult(
        result(
          mode: GameMode.level,
          levelId: 1,
          score: 1000,
          lines: 3,
          won: true,
          stars: 2,
          elapsedMs: 45000,
        ),
      );
      expect(first.newBestScore, isTrue);
      expect(first.newBestStars, isTrue);
      expect(storage.levelRecord(1).completed, isTrue);
      expect(storage.levelRecord(1).stars, 2);
      expect(storage.levelRecord(1).bestScore, 1000);
      expect(storage.levelRecord(1).bestTimeMs, 45000);
      expect(storage.isLevelUnlocked(2), isTrue);
      expect(storage.completedLevels, 1);
      expect(storage.totalStars, 2);

      final better = await storage.recordResult(
        result(
          mode: GameMode.level,
          levelId: 1,
          score: 800,
          lines: 3,
          won: true,
          stars: 3,
          elapsedMs: 30000,
        ),
      );
      expect(better.newBestScore, isFalse);
      expect(better.newBestStars, isTrue);
      expect(better.newBestTime, isTrue);
      expect(storage.levelRecord(1).stars, 3);
      expect(storage.levelRecord(1).bestScore, 1000);
      expect(storage.levelRecord(1).bestTimeMs, 30000);
      expect(storage.totalStars, 3);
    });

    test('关卡失败不写入通关与星级', () async {
      final storage = await prepareStorage();
      final outcome = await storage.recordResult(
        result(mode: GameMode.level, levelId: 2, score: 300, lines: 4),
      );
      expect(outcome.newBestStars, isFalse);
      expect(storage.levelRecord(2).completed, isFalse);
      expect(storage.levelRecord(2).stars, 0);
      expect(storage.isLevelUnlocked(2), isFalse);
    });

    test('清空纪录同时删除关卡进度', () async {
      final storage = await prepareStorage();
      await storage.recordResult(
        result(mode: GameMode.level, levelId: 1, won: true, stars: 3, elapsedMs: 20000),
      );
      expect(storage.completedLevels, 1);
      await storage.clearRecords();
      expect(storage.completedLevels, 0);
      expect(storage.totalStars, 0);
      expect(storage.levelRecord(1).completed, isFalse);
    });

    test('每日挑战按日期记录成绩与连续打卡', () async {
      final storage = await prepareStorage();
      final today = DailyChallenge.today();
      final yesterday = DailyChallenge.forDate(
        DateTime(today.date.year, today.date.month, today.date.day - 1),
      );

      final first = await storage.recordResult(
        result(mode: GameMode.daily, score: 1500, lines: 12, level: 3, challengeKey: today.key),
      );
      expect(first.newBestScore, isTrue);
      expect(storage.dailyRecord(today.key).bestScore, 1500);
      expect(storage.dailyRecord(today.key).bestLines, 12);
      expect(storage.dailyRecord(today.key).plays, 1);
      expect(storage.bestScore(GameMode.daily), 1500);
      expect(storage.dailyStreak(today.date), 1);

      final lower = await storage.recordResult(
        result(mode: GameMode.daily, score: 900, lines: 8, challengeKey: today.key),
      );
      expect(lower.newBestScore, isFalse);
      expect(storage.dailyRecord(today.key).bestScore, 1500);
      expect(storage.dailyRecord(today.key).plays, 2);

      await storage.recordResult(
        result(mode: GameMode.daily, score: 600, lines: 5, challengeKey: yesterday.key),
      );
      expect(storage.dailyStreak(today.date), 2);

      await storage.clearRecords();
      expect(storage.dailyRecord(today.key).played, isFalse);
      expect(storage.dailyStreak(today.date), 0);
    });

    test('生涯统计累计四行、T-Spin、全消与最高连击', () async {
      final storage = await prepareStorage();
      await storage.recordResult(
        result(score: 8000, lines: 20, maxCombo: 9, tetrises: 2, tSpins: 1, perfectClears: 1),
      );
      await storage.recordResult(
        result(score: 12000, lines: 4, maxCombo: 4, tetrises: 1, tSpins: 2),
      );

      expect(storage.totalTetris, 3);
      expect(storage.totalTSpins, 3);
      expect(storage.totalPerfectClears, 1);
      expect(storage.bestCombo, 9);
      expect(storage.bestScoreOverall, 12000);

      final stats = storage.achievementStats;
      expect(stats.games, 2);
      expect(stats.totalLines, 24);
      expect(stats.tetrises, 3);
      expect(stats.tSpins, 3);
      expect(stats.perfectClears, 1);
      expect(stats.bestCombo, 9);
      expect(stats.bestScore, 12000);
    });

    test('首局按表现解锁成就且不会重复解锁', () async {
      final storage = await prepareStorage();
      final first = await storage.recordResult(
        result(maxCombo: 5, tetrises: 1, tSpins: 1, perfectClears: 1),
      );
      expect(
        first.unlocked,
        containsAll([
          Achievement.firstGame,
          Achievement.tetris1,
          Achievement.tspin1,
          Achievement.perfect1,
          Achievement.combo5,
        ]),
      );
      expect(storage.unlockedAchievements, containsAll(first.unlocked));

      final second = await storage.recordResult(result(tetrises: 1));
      expect(second.unlocked, isEmpty);
      expect(storage.unlockedAchievements, containsAll(first.unlocked));
    });

    test('累计跨过目标后解锁成就', () async {
      final storage = await prepareStorage({
        'games_played': 9,
        'total_tetris': 9,
        'total_tspins': 9,
        'total_lines': 99,
      });
      final outcome = await storage.recordResult(
        result(score: 10000, lines: 1, maxCombo: 10, tetrises: 1, tSpins: 1),
      );

      expect(
        outcome.unlocked,
        containsAll([
          Achievement.tenGames,
          Achievement.tetris10,
          Achievement.tspin10,
          Achievement.lines100,
          Achievement.combo10,
          Achievement.score10k,
        ]),
      );
      expect(storage.unlockedAchievements, containsAll(outcome.unlocked));
      expect(storage.unlockedAchievements.length, outcome.unlocked.length);
    });

    test('清空纪录同时清空成就与生涯计数', () async {
      final storage = await prepareStorage();
      await storage.recordResult(result(tetrises: 2, tSpins: 1, perfectClears: 1, maxCombo: 6));
      expect(storage.unlockedAchievements, isNotEmpty);

      await storage.clearRecords();

      expect(storage.unlockedAchievements, isEmpty);
      expect(storage.totalTetris, 0);
      expect(storage.totalTSpins, 0);
      expect(storage.totalPerfectClears, 0);
      expect(storage.bestCombo, 0);
      expect(storage.bestScoreOverall, 0);
      expect(storage.achievementStats.games, 0);
    });
  });
}
