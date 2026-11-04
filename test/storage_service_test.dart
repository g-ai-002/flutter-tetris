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
  });
}
