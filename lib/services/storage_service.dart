import 'package:shared_preferences/shared_preferences.dart';

import '../game/achievement.dart';
import '../game/game_mode.dart';
import '../input/key_bindings.dart';
import '../theme/block_skin.dart';
import '../utils/constants.dart';
import 'daily_progress.dart';
import 'level_progress.dart';

/// 一局结束后的纪录变化。
class RecordOutcome {
  const RecordOutcome({
    required this.newBestScore,
    required this.newBestTime,
    this.newBestStars = false,
    this.unlocked = const [],
  });

  final bool newBestScore;

  /// 40 行竞速或关卡刷新最快用时。
  final bool newBestTime;

  /// 关卡刷新星级。
  final bool newBestStars;

  /// 本局新解锁的成就。
  final List<Achievement> unlocked;

  bool get isRecord => newBestScore || newBestTime || newBestStars;
}

/// 轻量偏好与本地纪录存储：写入失败时静默忽略，不影响游戏主流程。
class StorageService {
  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> get instance async {
    final existing = _instance;
    if (existing != null) return existing;
    final service = StorageService._();
    service._prefs = await SharedPreferences.getInstance();
    _instance = service;
    return service;
  }

  /// 仅供测试：清空单例，配合 SharedPreferences 的 mock 数据使用。
  static void resetForTests() => _instance = null;

  SharedPreferences get _p {
    final prefs = _prefs;
    if (prefs == null) throw StateError('StorageService 尚未初始化');
    return prefs;
  }

  Future<void> _write(Future<bool> Function(SharedPreferences prefs) action) async {
    try {
      await action(_p);
    } catch (_) {
      // 偏好写入失败不影响当前对局。
    }
  }

  bool get darkMode => _p.getBool(AppConstants.prefKeyDarkMode) ?? false;
  Future<void> setDarkMode(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyDarkMode, value));

  BlockSkin get blockSkin => BlockSkin.fromName(_p.getString(AppConstants.prefKeyBlockSkin));
  Future<void> setBlockSkin(BlockSkin value) =>
      _write((p) => p.setString(AppConstants.prefKeyBlockSkin, value.name));

  bool get soundEnabled => _p.getBool(AppConstants.prefKeySound) ?? true;
  Future<void> setSoundEnabled(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeySound, value));

  bool get musicEnabled => _p.getBool(AppConstants.prefKeyMusic) ?? true;
  Future<void> setMusicEnabled(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyMusic, value));

  bool get hapticsEnabled => _p.getBool(AppConstants.prefKeyHaptics) ?? true;
  Future<void> setHapticsEnabled(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyHaptics, value));

  bool get showGhost => _p.getBool(AppConstants.prefKeyShowGhost) ?? true;
  Future<void> setShowGhost(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyShowGhost, value));

  bool get showGrid => _p.getBool(AppConstants.prefKeyShowGrid) ?? true;
  Future<void> setShowGrid(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyShowGrid, value));

  int get logicRate {
    final hz = _p.getInt(AppConstants.prefKeyLogicRate);
    return AppConstants.logicRates.contains(hz) ? hz! : AppConstants.defaultLogicRate;
  }

  Future<void> setLogicRate(int value) =>
      _write((p) => p.setInt(AppConstants.prefKeyLogicRate, value));

  KeyBindings get keyBindings => KeyBindings.decode(_p.getString(AppConstants.prefKeyKeyBindings));
  Future<void> setKeyBindings(KeyBindings value) =>
      _write((p) => p.setString(AppConstants.prefKeyKeyBindings, value.encode()));

  int bestScore(GameMode mode) => _p.getInt(AppConstants.bestScoreKey(mode.name)) ?? 0;

  int bestLines(GameMode mode) => _p.getInt(AppConstants.bestLinesKey(mode.name)) ?? 0;

  int plays(GameMode mode) => _p.getInt(AppConstants.playsKey(mode.name)) ?? 0;

  /// 40 行竞速的最快用时，尚未完成时为 null。
  int? get bestSprintTimeMs => _p.getInt(AppConstants.prefKeyBestSprintTime);

  int get gamesPlayed => _p.getInt(AppConstants.prefKeyGamesPlayed) ?? 0;
  int get totalLines => _p.getInt(AppConstants.prefKeyTotalLines) ?? 0;
  int get totalScore => _p.getInt(AppConstants.prefKeyTotalScore) ?? 0;
  int get totalTetris => _p.getInt(AppConstants.prefKeyTotalTetris) ?? 0;
  int get totalTSpins => _p.getInt(AppConstants.prefKeyTotalTSpins) ?? 0;
  int get totalPerfectClears => _p.getInt(AppConstants.prefKeyTotalPerfectClears) ?? 0;
  int get bestCombo => _p.getInt(AppConstants.prefKeyBestCombo) ?? 0;
  int get bestScoreOverall => _p.getInt(AppConstants.prefKeyBestScoreOverall) ?? 0;

  /// 已解锁的成就，未知名称直接忽略。
  Set<Achievement> get unlockedAchievements {
    final names = _p.getStringList(AppConstants.prefKeyAchievements) ?? const [];
    return {
      for (final achievement in Achievement.values)
        if (names.contains(achievement.name)) achievement,
    };
  }

  /// 生涯统计：成就进度与纪录页共用同一份快照。
  AchievementStats get achievementStats => AchievementStats(
    games: gamesPlayed,
    totalLines: totalLines,
    totalScore: totalScore,
    bestScore: bestScoreOverall,
    bestCombo: bestCombo,
    tetrises: totalTetris,
    tSpins: totalTSpins,
    perfectClears: totalPerfectClears,
    bestSprintMs: bestSprintTimeMs,
    completedLevels: completedLevels,
    totalStars: totalStars,
    dailyStreak: dailyStreak(DateTime.now()),
  );

  LevelProgress get levelProgress =>
      LevelProgress.decode(_p.getString(AppConstants.prefKeyLevelRecords));

  LevelRecord levelRecord(int id) => levelProgress.record(id);

  DailyProgress get dailyProgress =>
      DailyProgress.decode(_p.getString(AppConstants.prefKeyDailyRecords));

  /// 指定日期（`yyyyMMdd`）的每日挑战成绩。
  DailyRecord dailyRecord(String key) => dailyProgress.record(key);

  /// 连续打卡天数，今天还没玩时从昨天开始计算。
  int dailyStreak(DateTime now) => dailyProgress.streak(now);

  /// 第一关默认开放，其余关卡需通关上一关。
  bool isLevelUnlocked(int id) => levelProgress.isUnlocked(id);

  int get completedLevels => levelProgress.completedCount;

  int get totalStars => levelProgress.totalStars;

  /// 写入一局结果并返回纪录变化；纪录比较在写入前完成。
  Future<RecordOutcome> recordResult(GameResult result) async {
    final levelId = result.levelId;
    final levelMerge = levelId == null ? null : levelProgress.merge(result);
    final dailyMerge = result.challengeKey == null ? null : dailyProgress.merge(result);
    final oldLevel = levelId == null ? const LevelRecord(id: 0) : levelRecord(levelId);
    final oldScore = levelId == null ? bestScore(result.mode) : oldLevel.bestScore;
    final oldLines = bestLines(result.mode);
    final oldTime = levelId == null ? bestSprintTimeMs : oldLevel.bestTimeMs;

    final newModeBestScore = result.score > oldScore;
    final newBestScore = dailyMerge?.newBestScore ?? newModeBestScore;
    final faster = result.won && (oldTime == null || result.elapsed.inMilliseconds < oldTime);
    final newBestTime = levelId == null ? result.mode == GameMode.sprint && faster : faster;
    final newBestStars = levelMerge?.newBestStars ?? false;
    final unlockedNow = <Achievement>[];

    await _write((p) async {
      await _addCareerTotals(p, result);
      await _saveModeRecords(
        p,
        result,
        levelMerge: levelMerge,
        dailyMerge: dailyMerge,
        newModeBestScore: newModeBestScore,
        oldLines: oldLines,
        newBestTime: newBestTime,
      );
      unlockedNow.addAll(await _unlockAchievements(p));
      return true;
    });

    return RecordOutcome(
      newBestScore: newBestScore,
      newBestTime: newBestTime,
      newBestStars: newBestStars,
      unlocked: List.unmodifiable(unlockedNow),
    );
  }

  /// 生涯计数与单局极值，所有玩法都会累计。
  Future<void> _addCareerTotals(SharedPreferences p, GameResult result) async {
    final totals = <String, int>{
      AppConstants.prefKeyGamesPlayed: gamesPlayed + 1,
      AppConstants.prefKeyTotalLines: totalLines + result.lines,
      AppConstants.prefKeyTotalScore: totalScore + result.score,
      AppConstants.prefKeyTotalTetris: totalTetris + result.tetrises,
      AppConstants.prefKeyTotalTSpins: totalTSpins + result.tSpins,
      AppConstants.prefKeyTotalPerfectClears: totalPerfectClears + result.perfectClears,
      AppConstants.playsKey(result.mode.name): plays(result.mode) + 1,
      if (result.maxCombo > bestCombo) AppConstants.prefKeyBestCombo: result.maxCombo,
      if (result.score > bestScoreOverall) AppConstants.prefKeyBestScoreOverall: result.score,
    };
    for (final entry in totals.entries) {
      await p.setInt(entry.key, entry.value);
    }
  }

  /// 关卡与每日挑战写入各自进度；经典玩法写入分模式纪录。
  Future<void> _saveModeRecords(
    SharedPreferences p,
    GameResult result, {
    required LevelProgressMerge? levelMerge,
    required DailyProgressMerge? dailyMerge,
    required bool newModeBestScore,
    required int oldLines,
    required bool newBestTime,
  }) async {
    if (dailyMerge != null) {
      await p.setString(AppConstants.prefKeyDailyRecords, dailyMerge.progress.encode());
    }
    if (levelMerge != null) {
      await p.setString(AppConstants.prefKeyLevelRecords, levelMerge.progress.encode());
      return;
    }
    if (newModeBestScore) {
      await p.setInt(AppConstants.bestScoreKey(result.mode.name), result.score);
    }
    if (result.lines > oldLines) {
      await p.setInt(AppConstants.bestLinesKey(result.mode.name), result.lines);
    }
    if (newBestTime) {
      await p.setInt(AppConstants.prefKeyBestSprintTime, result.elapsed.inMilliseconds);
    }
  }

  /// 依据最新生涯统计解锁成就，返回本局新增的徽章。
  Future<List<Achievement>> _unlockAchievements(SharedPreferences p) async {
    final unlocked = unlockedAchievements;
    final newlyUnlocked = Achievement.unlockedIn(achievementStats).difference(unlocked);
    if (newlyUnlocked.isEmpty) return const [];
    await p.setStringList(AppConstants.prefKeyAchievements, [
      for (final achievement in {...unlocked, ...newlyUnlocked}) achievement.name,
    ]);
    return newlyUnlocked.toList();
  }

  /// 清空纪录、生涯统计与成就，保留界面偏好。
  Future<void> clearRecords() => _write((p) async {
    for (final mode in GameMode.values) {
      await p.remove(AppConstants.bestScoreKey(mode.name));
      await p.remove(AppConstants.bestLinesKey(mode.name));
      await p.remove(AppConstants.playsKey(mode.name));
    }
    await p.remove(AppConstants.prefKeyBestSprintTime);
    await p.remove(AppConstants.prefKeyLevelRecords);
    await p.remove(AppConstants.prefKeyDailyRecords);
    await p.remove(AppConstants.prefKeyGamesPlayed);
    await p.remove(AppConstants.prefKeyTotalLines);
    await p.remove(AppConstants.prefKeyTotalScore);
    await p.remove(AppConstants.prefKeyTotalTetris);
    await p.remove(AppConstants.prefKeyTotalTSpins);
    await p.remove(AppConstants.prefKeyTotalPerfectClears);
    await p.remove(AppConstants.prefKeyBestCombo);
    await p.remove(AppConstants.prefKeyBestScoreOverall);
    await p.remove(AppConstants.prefKeyAchievements);
    return true;
  });
}
