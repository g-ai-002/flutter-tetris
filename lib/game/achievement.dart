import 'package:flutter/material.dart';

/// 生涯统计快照：成就进度只依赖这些累计值。
class AchievementStats {
  const AchievementStats({
    this.games = 0,
    this.totalLines = 0,
    this.totalScore = 0,
    this.bestScore = 0,
    this.bestCombo = 0,
    this.tetrises = 0,
    this.tSpins = 0,
    this.perfectClears = 0,
    this.bestSprintMs,
    this.completedLevels = 0,
    this.totalStars = 0,
    this.dailyStreak = 0,
  });

  final int games;
  final int totalLines;
  final int totalScore;
  final int bestScore;
  final int bestCombo;
  final int tetrises;
  final int tSpins;
  final int perfectClears;
  final int? bestSprintMs;
  final int completedLevels;
  final int totalStars;
  final int dailyStreak;
}

/// 二十枚成就徽章：目标值与进度计算集中在枚举里，界面只负责展示。
enum Achievement {
  firstGame('初来乍到', '完成第一局游戏', Icons.flag_rounded, 1),
  tenGames('渐入佳境', '累计完成 10 局', Icons.repeat_rounded, 10),
  hundredGames('百局老手', '累计完成 100 局', Icons.military_tech_rounded, 100),
  lines100('小有积累', '累计消除 100 行', Icons.view_agenda_rounded, 100),
  lines1000('千行不辍', '累计消除 1,000 行', Icons.stacked_bar_chart_rounded, 1000),
  tetris1('四行齐消', '首次一次消除 4 行', Icons.bolt_rounded, 1),
  tetris10('雷霆十连', '累计 10 次四行消除', Icons.flash_on_rounded, 10),
  tspin1('转角相会', '首次完成 T-Spin 消除', Icons.rotate_90_degrees_ccw_rounded, 1),
  tspin10('旋出花来', '累计 10 次 T-Spin 消除', Icons.cyclone_rounded, 10),
  perfect1('片甲不留', '首次清空整个场地', Icons.auto_awesome_rounded, 1),
  perfect3('三度空场', '累计 3 次清空场地', Icons.diamond_rounded, 3),
  combo5('连消不断', '单局最高连击达到 5', Icons.link_rounded, 5),
  combo10('十连如流', '单局最高连击达到 10', Icons.all_inclusive_rounded, 10),
  score10k('万分俱乐部', '单局得分达到 10,000', Icons.savings_rounded, 10000),
  score50k('五万分高手', '单局得分达到 50,000', Icons.workspace_premium_rounded, 50000),
  sprint180('三分钟冲刺', '3 分钟内完成 40 行竞速', Icons.timer_rounded, 1),
  sprint120('两分钟冲刺', '2 分钟内完成 40 行竞速', Icons.speed_rounded, 1),
  levels6('过半关卡', '通关 6 个关卡', Icons.map_rounded, 6),
  stars24('星光熠熠', '关卡累计获得 24 颗星', Icons.star_rounded, 24),
  daily7('七日不辍', '每日挑战连续打卡 7 天', Icons.calendar_month_rounded, 7);

  const Achievement(this.title, this.description, this.icon, this.target);

  final String title;
  final String description;
  final IconData icon;
  final int target;

  /// 当前进度，已按目标值封顶。
  int progress(AchievementStats stats) {
    final value = switch (this) {
      firstGame || tenGames || hundredGames => stats.games,
      lines100 || lines1000 => stats.totalLines,
      tetris1 || tetris10 => stats.tetrises,
      tspin1 || tspin10 => stats.tSpins,
      perfect1 || perfect3 => stats.perfectClears,
      combo5 || combo10 => stats.bestCombo,
      score10k || score50k => stats.bestScore,
      sprint180 => _sprintDone(stats, 180),
      sprint120 => _sprintDone(stats, 120),
      levels6 => stats.completedLevels,
      stars24 => stats.totalStars,
      daily7 => stats.dailyStreak,
    };
    return value.clamp(0, target);
  }

  bool unlockedBy(AchievementStats stats) => progress(stats) >= target;

  /// 进度文案：已达成统一显示，未达成时展示当前值与目标值。
  String progressLabel(AchievementStats stats) {
    final current = progress(stats);
    if (current >= target) return '已达成';
    if (target == 1) return '未达成';
    return '$current/$target';
  }

  int _sprintDone(AchievementStats stats, int seconds) {
    final best = stats.bestSprintMs;
    return best != null && best <= seconds * 1000 ? 1 : 0;
  }

  /// 某份统计下已解锁的成就集合。
  static Set<Achievement> unlockedIn(AchievementStats stats) => {
    for (final achievement in values)
      if (achievement.unlockedBy(stats)) achievement,
  };
}
