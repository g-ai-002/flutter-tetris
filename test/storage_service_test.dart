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
        result(
          mode: GameMode.sprint,
          score: 300,
          lines: 40,
          elapsedMs: 95000,
          won: true,
        ),
      );
      expect(first.newBestTime, isTrue);
      expect(storage.bestSprintTimeMs, 95000);

      await storage.recordResult(
        result(
          mode: GameMode.sprint,
          score: 400,
          lines: 40,
          elapsedMs: 120000,
          won: true,
        ),
      );
      expect(storage.bestSprintTimeMs, 95000);

      final faster = await storage.recordResult(
        result(
          mode: GameMode.sprint,
          score: 500,
          lines: 40,
          elapsedMs: 80000,
          won: true,
        ),
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
        result(
          mode: GameMode.level,
          levelId: 1,
          won: true,
          stars: 3,
          elapsedMs: 20000,
        ),
      );
      expect(storage.completedLevels, 1);
      await storage.clearRecords();
      expect(storage.completedLevels, 0);
      expect(storage.totalStars, 0);
      expect(storage.levelRecord(1).completed, isFalse);
    });
  });
}
