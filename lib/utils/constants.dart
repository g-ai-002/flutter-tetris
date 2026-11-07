/// Web 端字体：CanvasKit 没有系统中文字体回退，使用 soup_fonts 的思源黑体。
const String kWebFontFamily = 'SourceHanSansCN';

class AppConstants {
  AppConstants._();

  static const String appName = '俄罗斯方块';
  static const String appEnglishName = 'TETRIS';
  static const String version = '0.7.1';
  static const String appDirName = 'FlutterTetris';

  static const String prefKeyDarkMode = 'dark_mode';
  static const String prefKeyBlockSkin = 'block_skin';
  static const String prefKeySound = 'sound_enabled';
  static const String prefKeyMusic = 'music_enabled';
  static const String prefKeyHaptics = 'haptics_enabled';
  static const String prefKeyShowGhost = 'show_ghost';
  static const String prefKeyShowGrid = 'show_grid';
  static const String prefKeyKeyBindings = 'key_bindings';

  static const String prefKeyGamesPlayed = 'games_played';
  static const String prefKeyTotalLines = 'total_lines';
  static const String prefKeyTotalScore = 'total_score';
  static const String prefKeyTotalTetris = 'total_tetris';
  static const String prefKeyTotalTSpins = 'total_tspins';
  static const String prefKeyTotalPerfectClears = 'total_perfect_clears';
  static const String prefKeyBestCombo = 'best_combo';
  static const String prefKeyBestScoreOverall = 'best_score_overall';
  static const String prefKeyAchievements = 'achievements';
  static const String prefKeyBestSprintTime = 'best_sprint_time_ms';
  static const String prefKeyLevelRecords = 'level_records';
  static const String prefKeyDailyRecords = 'daily_records';

  static String bestScoreKey(String mode) => 'best_score_$mode';
  static String bestLinesKey(String mode) => 'best_lines_$mode';
  static String playsKey(String mode) => 'plays_$mode';
}
