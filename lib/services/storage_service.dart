import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_mode.dart';
import '../utils/constants.dart';
import 'level_progress.dart';

/// 一局结束后的纪录变化。
class RecordOutcome {
  const RecordOutcome({
    required this.newBestScore,
    required this.newBestTime,
    this.newBestStars = false,
  });

  final bool newBestScore;

  /// 40 行竞速或关卡刷新最快用时。
  final bool newBestTime;

  /// 关卡刷新星级。
  final bool newBestStars;

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

  Future<void> _write(
    Future<bool> Function(SharedPreferences prefs) action,
  ) async {
    try {
      await action(_p);
    } catch (_) {
      // 偏好写入失败不影响当前对局。
    }
  }

  bool get darkMode => _p.getBool(AppConstants.prefKeyDarkMode) ?? false;
  Future<void> setDarkMode(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyDarkMode, value));

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

  int bestScore(GameMode mode) =>
      _p.getInt(AppConstants.bestScoreKey(mode.name)) ?? 0;

  int bestLines(GameMode mode) =>
      _p.getInt(AppConstants.bestLinesKey(mode.name)) ?? 0;

  int plays(GameMode mode) => _p.getInt(AppConstants.playsKey(mode.name)) ?? 0;

  /// 40 行竞速的最快用时，尚未完成时为 null。
  int? get bestSprintTimeMs => _p.getInt(AppConstants.prefKeyBestSprintTime);

  int get gamesPlayed => _p.getInt(AppConstants.prefKeyGamesPlayed) ?? 0;
  int get totalLines => _p.getInt(AppConstants.prefKeyTotalLines) ?? 0;
  int get totalScore => _p.getInt(AppConstants.prefKeyTotalScore) ?? 0;

  LevelProgress get levelProgress =>
      LevelProgress.decode(_p.getString(AppConstants.prefKeyLevelRecords));

  LevelRecord levelRecord(int id) => levelProgress.record(id);

  /// 第一关默认开放，其余关卡需通关上一关。
  bool isLevelUnlocked(int id) => levelProgress.isUnlocked(id);

  int get completedLevels => levelProgress.completedCount;

  int get totalStars => levelProgress.totalStars;

  /// 写入一局结果并返回纪录变化；纪录比较在写入前完成。
  Future<RecordOutcome> recordResult(GameResult result) async {
    final levelId = result.levelId;
    final levelMerge = levelId == null ? null : levelProgress.merge(result);
    final oldLevel = levelId == null
        ? const LevelRecord(id: 0)
        : levelRecord(levelId);
    final oldScore = levelId == null
        ? bestScore(result.mode)
        : oldLevel.bestScore;
    final oldLines = bestLines(result.mode);
    final oldTime = levelId == null ? bestSprintTimeMs : oldLevel.bestTimeMs;

    final newBestScore = result.score > oldScore;
    final faster =
        result.won &&
        (oldTime == null || result.elapsed.inMilliseconds < oldTime);
    final newBestTime = levelId == null
        ? result.mode == GameMode.sprint && faster
        : faster;
    final newBestStars = levelMerge?.newBestStars ?? false;

    await _write((p) async {
      await p.setInt(AppConstants.prefKeyGamesPlayed, gamesPlayed + 1);
      await p.setInt(AppConstants.prefKeyTotalLines, totalLines + result.lines);
      await p.setInt(AppConstants.prefKeyTotalScore, totalScore + result.score);
      await p.setInt(
        AppConstants.playsKey(result.mode.name),
        plays(result.mode) + 1,
      );

      if (levelMerge != null) {
        await p.setString(
          AppConstants.prefKeyLevelRecords,
          levelMerge.progress.encode(),
        );
        return true;
      }

      if (newBestScore) {
        await p.setInt(
          AppConstants.bestScoreKey(result.mode.name),
          result.score,
        );
      }
      if (result.lines > oldLines) {
        await p.setInt(
          AppConstants.bestLinesKey(result.mode.name),
          result.lines,
        );
      }
      if (newBestTime) {
        await p.setInt(
          AppConstants.prefKeyBestSprintTime,
          result.elapsed.inMilliseconds,
        );
      }
      return true;
    });

    return RecordOutcome(
      newBestScore: newBestScore,
      newBestTime: newBestTime,
      newBestStars: newBestStars,
    );
  }

  /// 清空纪录与累计统计，保留界面偏好。
  Future<void> clearRecords() => _write((p) async {
    for (final mode in GameMode.values) {
      await p.remove(AppConstants.bestScoreKey(mode.name));
      await p.remove(AppConstants.bestLinesKey(mode.name));
      await p.remove(AppConstants.playsKey(mode.name));
    }
    await p.remove(AppConstants.prefKeyBestSprintTime);
    await p.remove(AppConstants.prefKeyLevelRecords);
    await p.remove(AppConstants.prefKeyGamesPlayed);
    await p.remove(AppConstants.prefKeyTotalLines);
    await p.remove(AppConstants.prefKeyTotalScore);
    return true;
  });
}
