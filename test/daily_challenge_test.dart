import 'package:flutter_tetris/game/daily_challenge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('每日挑战', () {
    test('同一天任意时刻种子一致，跨天不同', () {
      final morning = DailyChallenge.forDate(DateTime(2026, 11, 5, 8));
      final night = DailyChallenge.forDate(DateTime(2026, 11, 5, 23, 59));
      expect(morning.seed, night.seed);
      expect(morning.key, '20261105');
      expect(morning.label, '11 月 5 日');
      expect(morning.weekdayLabel, '周四');

      final next = DailyChallenge.forDate(DateTime(2026, 11, 6));
      expect(next.seed, isNot(morning.seed));
      expect(morning.seed, greaterThan(0));
    });

    test('最近七天从今天开始按日期倒退', () {
      final days = DailyChallenge.recent(7, now: DateTime(2026, 11, 5));
      expect(days.length, 7);
      expect(days.first.key, '20261105');
      expect(days[1].key, '20261104');
      expect(days.last.key, '20261030');
      expect(days.map((day) => day.seed).toSet().length, 7);
      expect(days.every((day) => day.seed > 0), isTrue);
    });

    test('刷新倒计时指向次日零点', () {
      final challenge = DailyChallenge.forDate(DateTime(2026, 11, 5));
      expect(challenge.refreshIn(DateTime(2026, 11, 5, 23)), const Duration(hours: 1));
      expect(challenge.refreshIn(DateTime(2026, 11, 6, 1)), Duration.zero);
    });

    test('战报包含日期、成绩与标签', () {
      final text = DailyChallenge.forDate(DateTime(2026, 11, 5))
          .shareText(score: 12345, lines: 42, level: 5);
      expect(text, contains('11 月 5 日'));
      expect(text, contains('12,345'));
      expect(text, contains('消行 42'));
      expect(text, contains(DailyChallenge.shareTag));
    });
  });
}
