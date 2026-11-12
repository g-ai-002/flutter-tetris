import 'package:flutter_tetris/game/daily_challenge.dart';
import 'package:flutter_tetris/game/game_mode.dart';
import 'package:flutter_tetris/services/daily_progress.dart';
import 'package:flutter_test/flutter_test.dart';

GameResult dailyResult({
  DateTime? date,
  String? key,
  int score = 1000,
  int lines = 10,
  int level = 2,
  int elapsedMs = 120000,
}) {
  return GameResult(
    mode: GameMode.daily,
    score: score,
    lines: lines,
    level: level,
    pieces: 40,
    maxCombo: 3,
    elapsed: Duration(milliseconds: elapsedMs),
    won: false,
    reason: '时间到',
    challengeKey: key ?? DailyChallenge.forDate(date ?? DateTime(2026, 11, 5)).key,
  );
}

void main() {
  group('每日挑战进度', () {
    test('合并只升高分与消行并累计对局次数', () {
      final first = DailyProgress.empty().merge(dailyResult());
      expect(first.newBestScore, isTrue);
      final progress = first.progress;
      final record = progress.record('20261105');
      expect(record.bestScore, 1000);
      expect(record.bestLines, 10);
      expect(record.plays, 1);
      expect(record.played, isTrue);

      final lower = progress.merge(dailyResult(score: 800, lines: 6, level: 4));
      expect(lower.newBestScore, isFalse);
      expect(lower.newBestLines, isFalse);
      expect(lower.progress.record('20261105').bestScore, 1000);
      expect(lower.progress.record('20261105').bestLines, 10);
      expect(lower.progress.record('20261105').bestLevel, 4);
      expect(lower.progress.record('20261105').plays, 2);

      final better = lower.progress.merge(dailyResult(score: 1500, lines: 12));
      expect(better.newBestScore, isTrue);
      expect(better.progress.record('20261105').bestScore, 1500);
      expect(better.progress.record('20261105').bestLines, 12);
    });

    test('序列化往返保留每一天的成绩', () {
      final progress = DailyProgress.empty()
          .merge(dailyResult(score: 900))
          .progress
          .merge(dailyResult(date: DateTime(2026, 11, 4), score: 700, lines: 8))
          .progress;
      final restored = DailyProgress.decode(progress.encode());
      expect(restored.record('20261105').bestScore, 900);
      expect(restored.record('20261104').bestScore, 700);
      expect(restored.playedDays, 2);
      expect(DailyProgress.decode('null').playedDays, 0);
      expect(DailyProgress.decode('broken').playedDays, 0);
    });

    test('连续打卡跨天累计，遇缺口归零', () {
      var progress = DailyProgress.empty();
      for (final day in [5, 4, 3, 1]) {
        progress = progress.merge(dailyResult(date: DateTime(2026, 11, day))).progress;
      }
      expect(progress.streak(DateTime(2026, 11, 5)), 3);
      expect(progress.streak(DateTime(2026, 11, 6)), 3);
      expect(progress.streak(DateTime(2026, 11, 8)), 0);
      expect(progress.playedDays, 4);
    });

    test('没有日期键的结果不写入进度', () {
      final merge = DailyProgress.empty().merge(
        const GameResult(
          mode: GameMode.daily,
          score: 100,
          lines: 1,
          level: 1,
          pieces: 4,
          maxCombo: 0,
          elapsed: Duration(seconds: 1),
          won: false,
          reason: '时间到',
        ),
      );
      expect(merge.isRecord, isFalse);
      expect(merge.progress.playedDays, 0);
    });
  });
}
