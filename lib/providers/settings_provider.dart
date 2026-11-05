import 'dart:async';

import 'package:flutter/foundation.dart';

import '../game/game_mode.dart';
import '../services/daily_progress.dart';
import '../services/level_progress.dart';
import '../services/music_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';

/// 用户偏好：主题、幽灵块、网格、音效与背景音乐。
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._storage) {
    _syncFeedback();
  }

  final StorageService _storage;

  bool get darkMode => _storage.darkMode;
  Future<void> setDarkMode(bool value) =>
      _update(() => _storage.setDarkMode(value));

  bool get showGhost => _storage.showGhost;
  Future<void> setShowGhost(bool value) =>
      _update(() => _storage.setShowGhost(value));

  bool get showGrid => _storage.showGrid;
  Future<void> setShowGrid(bool value) =>
      _update(() => _storage.setShowGrid(value));

  bool get soundEnabled => _storage.soundEnabled;
  Future<void> setSoundEnabled(bool value) => _update(() async {
    await _storage.setSoundEnabled(value);
    _syncFeedback();
  });

  bool get musicEnabled => _storage.musicEnabled;
  Future<void> setMusicEnabled(bool value) => _update(() async {
    await _storage.setMusicEnabled(value);
    // 音频启停不阻塞开关反馈，加载失败时 MusicService 自行记录日志。
    unawaited(MusicService.setEnabled(value));
  });

  bool get hapticsEnabled => _storage.hapticsEnabled;
  Future<void> setHapticsEnabled(bool value) => _update(() async {
    await _storage.setHapticsEnabled(value);
    _syncFeedback();
  });

  int bestScore(GameMode mode) => _storage.bestScore(mode);
  int bestLines(GameMode mode) => _storage.bestLines(mode);
  int plays(GameMode mode) => _storage.plays(mode);
  int? get bestSprintTimeMs => _storage.bestSprintTimeMs;
  int get gamesPlayed => _storage.gamesPlayed;
  int get totalLines => _storage.totalLines;
  int get totalScore => _storage.totalScore;

  LevelRecord levelRecord(int id) => _storage.levelRecord(id);
  bool isLevelUnlocked(int id) => _storage.isLevelUnlocked(id);
  int get completedLevels => _storage.completedLevels;
  int get totalStars => _storage.totalStars;

  DailyRecord dailyRecord(String key) => _storage.dailyRecord(key);
  int dailyStreak([DateTime? now]) =>
      _storage.dailyStreak(now ?? DateTime.now());

  Future<void> clearRecords() => _update(_storage.clearRecords);

  /// 对局写入纪录后刷新依赖本地数据的界面。
  void refresh() => notifyListeners();

  void _syncFeedback() =>
      SoundService.configure(sound: soundEnabled, haptics: hapticsEnabled);

  /// 写入偏好后统一通知界面，避免每个 setter 重复一遍。
  Future<void> _update(Future<void> Function() write) async {
    await write();
    notifyListeners();
  }
}
