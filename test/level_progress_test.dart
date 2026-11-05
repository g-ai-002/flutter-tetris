import 'package:flutter_tetris/game/game_mode.dart';
import 'package:flutter_tetris/services/level_progress.dart';
import 'package:flutter_test/flutter_test.dart';

GameResult result({
  int? levelId = 1,
  int score = 1000,
  int stars = 0,
  int elapsedMs = 30000,
  bool won = false,
}) => GameResult(
  mode: levelId == null ? GameMode.endless : GameMode.level,
  score: score,
  lines: 10,
  level: 1,
  pieces: 20,
  maxCombo: 1,
  elapsed: Duration(milliseconds: elapsedMs),
  won: won,
  reason: won ? '完成' : '结束',
  levelId: levelId,
  stars: stars,
);

void main() {
  group('关卡进度', () {
    test('空进度只开放第一关', () {
      final progress = LevelProgress.empty();
      expect(progress.record(1).completed, isFalse);
      expect(progress.isUnlocked(1), isTrue);
      expect(progress.isUnlocked(2), isFalse);
      expect(progress.completedCount, 0);
      expect(progress.totalStars, 0);
    });

    test('无法解析的 JSON 退回空进度', () {
      expect(LevelProgress.decode(null).completedCount, 0);
      expect(LevelProgress.decode('').completedCount, 0);
      expect(LevelProgress.decode('not json').completedCount, 0);
      expect(LevelProgress.decode('[1,2]').completedCount, 0);
      expect(LevelProgress.decode('{"x":{"stars":3}}').completedCount, 0);
    });

    test('序列化与解析保持纪录字段', () {
      final merged = LevelProgress.empty()
          .merge(result(score: 1200, won: true, stars: 2))
          .progress;
      final decoded = LevelProgress.decode(merged.encode());
      final record = decoded.record(1);
      expect(record.completed, isTrue);
      expect(record.stars, 2);
      expect(record.bestScore, 1200);
      expect(record.bestTimeMs, 30000);
      expect(decoded.isUnlocked(2), isTrue);
      expect(decoded.completedCount, 1);
      expect(decoded.totalStars, 2);
    });

    test('通关写入完成状态、星级与最快用时', () {
      final merge = LevelProgress.empty().merge(
        result(score: 900, won: true, stars: 3, elapsedMs: 20000),
      );
      expect(merge.newBestScore, isTrue);
      expect(merge.newBestStars, isTrue);
      expect(merge.newBestTime, isTrue);
      expect(merge.isRecord, isTrue);
      expect(merge.progress.record(1).completed, isTrue);
      expect(merge.progress.record(1).stars, 3);
      expect(merge.progress.record(1).bestTimeMs, 20000);
    });

    test('失败不写完成状态与星级，但仍记录最高分', () {
      final merge = LevelProgress.empty().merge(result(score: 400));
      expect(merge.newBestScore, isTrue);
      expect(merge.newBestStars, isFalse);
      expect(merge.newBestTime, isFalse);
      expect(merge.progress.record(1).completed, isFalse);
      expect(merge.progress.record(1).stars, 0);
      expect(merge.progress.isUnlocked(2), isFalse);
    });

    test('纪录只升不降', () {
      final first = LevelProgress.empty()
          .merge(result(won: true, stars: 2, elapsedMs: 50000))
          .progress;
      final second = first.merge(
        result(score: 800, won: true, stars: 3, elapsedMs: 60000),
      );
      expect(second.newBestScore, isFalse);
      expect(second.newBestStars, isTrue);
      expect(second.newBestTime, isFalse);
      expect(second.progress.record(1).bestScore, 1000);
      expect(second.progress.record(1).stars, 3);
      expect(second.progress.record(1).bestTimeMs, 50000);

      final faster = second.progress.merge(
        result(score: 1200, won: true, stars: 3, elapsedMs: 40000),
      );
      expect(faster.newBestScore, isTrue);
      expect(faster.newBestStars, isFalse);
      expect(faster.newBestTime, isTrue);
      expect(faster.progress.record(1).bestTimeMs, 40000);
    });

    test('非关卡结果不改变进度', () {
      final merge = LevelProgress.empty().merge(result(levelId: null));
      expect(merge.newBestScore, isFalse);
      expect(merge.newBestStars, isFalse);
      expect(merge.newBestTime, isFalse);
      expect(merge.progress.records, isEmpty);
    });
  });
}
