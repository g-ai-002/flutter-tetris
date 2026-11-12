import 'package:flutter_tetris/game/achievement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('成就判定', () {
    test('空白统计下没有任何成就是已解锁的', () {
      const stats = AchievementStats();
      expect(Achievement.unlockedIn(stats), isEmpty);
      for (final achievement in Achievement.values) {
        expect(achievement.progress(stats), 0);
        expect(achievement.unlockedBy(stats), isFalse);
      }
    });

    test('对局数与消行按目标累计并封顶', () {
      const stats = AchievementStats(games: 12, totalLines: 800);
      expect(Achievement.firstGame.unlockedBy(stats), isTrue);
      expect(Achievement.tenGames.unlockedBy(stats), isTrue);
      expect(Achievement.hundredGames.unlockedBy(stats), isFalse);
      expect(Achievement.lines100.unlockedBy(stats), isTrue);
      expect(Achievement.lines1000.progress(stats), 800);
      expect(Achievement.hundredGames.progressLabel(const AchievementStats(games: 12)), '12/100');
    });

    test('技巧类成就读取四行、T-Spin 与全消次数', () {
      const stats = AchievementStats(tetrises: 10, tSpins: 4, perfectClears: 1, bestCombo: 6);
      expect(Achievement.tetris1.unlockedBy(stats), isTrue);
      expect(Achievement.tetris10.unlockedBy(stats), isTrue);
      expect(Achievement.tspin1.unlockedBy(stats), isTrue);
      expect(Achievement.tspin10.unlockedBy(stats), isFalse);
      expect(Achievement.perfect1.unlockedBy(stats), isTrue);
      expect(Achievement.perfect3.unlockedBy(stats), isFalse);
      expect(Achievement.combo5.unlockedBy(stats), isTrue);
      expect(Achievement.combo10.unlockedBy(stats), isFalse);
      expect(Achievement.tspin1.progressLabel(stats), '已达成');
      expect(Achievement.combo10.progressLabel(stats), '6/10');
    });

    test('分数与竞速成就按阈值判定', () {
      const stats = AchievementStats(bestScore: 12000, bestSprintMs: 110000);
      expect(Achievement.score10k.unlockedBy(stats), isTrue);
      expect(Achievement.score50k.unlockedBy(stats), isFalse);
      expect(Achievement.sprint180.unlockedBy(stats), isTrue);
      expect(Achievement.sprint120.unlockedBy(stats), isTrue);

      const slow = AchievementStats(bestSprintMs: 200000);
      expect(Achievement.sprint180.unlockedBy(slow), isFalse);
      expect(Achievement.sprint120.unlockedBy(slow), isFalse);
      expect(Achievement.sprint180.progressLabel(slow), '未达成');
    });

    test('关卡、星级与每日连续打卡参与判定', () {
      const stats = AchievementStats(completedLevels: 6, totalStars: 24, dailyStreak: 7);
      expect(Achievement.levels6.unlockedBy(stats), isTrue);
      expect(Achievement.stars24.unlockedBy(stats), isTrue);
      expect(Achievement.daily7.unlockedBy(stats), isTrue);
      expect(Achievement.unlockedIn(stats).length, 3);
    });

    test('成就标题与目标唯一且进度文案可读', () {
      expect(Achievement.values.length, 20);
      expect(
        Achievement.values.map((achievement) => achievement.title).toSet(),
        hasLength(Achievement.values.length),
      );
      expect(
        Achievement.values.map((achievement) => achievement.target).every((target) => target > 0),
        isTrue,
      );
      const stats = AchievementStats(games: 100);
      expect(Achievement.hundredGames.progressLabel(stats), '已达成');
      expect(Achievement.firstGame.progressLabel(const AchievementStats()), '未达成');
    });
  });
}
