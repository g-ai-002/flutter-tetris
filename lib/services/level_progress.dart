import 'dart:convert';
import 'dart:math' as math;

import '../game/game_mode.dart';
import '../game/level.dart';

/// 单个关卡的本地进度。
class LevelRecord {
  const LevelRecord({
    required this.id,
    this.completed = false,
    this.stars = 0,
    this.bestScore = 0,
    this.bestTimeMs,
  });

  final int id;
  final bool completed;
  final int stars;
  final int bestScore;
  final int? bestTimeMs;

  LevelRecord copyWith({
    bool? completed,
    int? stars,
    int? bestScore,
    int? bestTimeMs,
  }) => LevelRecord(
    id: id,
    completed: completed ?? this.completed,
    stars: stars ?? this.stars,
    bestScore: bestScore ?? this.bestScore,
    bestTimeMs: bestTimeMs ?? this.bestTimeMs,
  );

  Map<String, Object?> toJson() => {
    'completed': completed,
    'stars': stars,
    'score': bestScore,
    'time': bestTimeMs,
  };

  static LevelRecord fromJson(int id, Object? raw) {
    if (raw is! Map) return LevelRecord(id: id);
    return LevelRecord(
      id: id,
      completed: raw['completed'] == true,
      stars: (raw['stars'] as num?)?.toInt() ?? 0,
      bestScore: (raw['score'] as num?)?.toInt() ?? 0,
      bestTimeMs: (raw['time'] as num?)?.toInt(),
    );
  }
}

/// 合并一局关卡结果后的进度与纪录变化。
class LevelProgressMerge {
  const LevelProgressMerge({
    required this.progress,
    required this.newBestScore,
    required this.newBestTime,
    required this.newBestStars,
  });

  final LevelProgress progress;
  final bool newBestScore;
  final bool newBestTime;
  final bool newBestStars;

  bool get isRecord => newBestScore || newBestTime || newBestStars;
}

/// 关卡进度：通关状态、星级、最高分与最快用时。
/// 纯数据对象，负责序列化与合并规则，不依赖具体存储实现。
class LevelProgress {
  const LevelProgress(this._records);

  LevelProgress.empty() : this(const {});

  final Map<int, LevelRecord> _records;

  Map<int, LevelRecord> get records => Map.unmodifiable(_records);

  /// 兼容旧版本写入的 JSON；无法解析时视为空进度。
  factory LevelProgress.decode(String? raw) {
    if (raw == null || raw.isEmpty) return LevelProgress.empty();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return LevelProgress.empty();
      final records = <int, LevelRecord>{};
      for (final entry in decoded.entries) {
        final id = int.tryParse('${entry.key}');
        if (id == null) continue;
        records[id] = LevelRecord.fromJson(id, entry.value);
      }
      return LevelProgress(records);
    } catch (_) {
      return LevelProgress.empty();
    }
  }

  String encode() => jsonEncode({
    for (final entry in _records.entries) '${entry.key}': entry.value.toJson(),
  });

  LevelRecord record(int id) => _records[id] ?? LevelRecord(id: id);

  /// 第一关默认开放，其余关卡需通关上一关。
  bool isUnlocked(int id) => id <= 1 || record(id - 1).completed;

  int get completedCount =>
      kLevels.where((level) => record(level.id).completed).length;

  int get totalStars =>
      kLevels.fold(0, (sum, level) => sum + record(level.id).stars);

  /// 合并一局关卡结果；只升不降，未通关不会写入完成状态与星级。
  LevelProgressMerge merge(GameResult result) {
    final levelId = result.levelId;
    if (levelId == null) {
      return LevelProgressMerge(
        progress: this,
        newBestScore: false,
        newBestTime: false,
        newBestStars: false,
      );
    }
    final previous = record(levelId);
    final faster =
        result.won &&
        (previous.bestTimeMs == null ||
            result.elapsed.inMilliseconds < previous.bestTimeMs!);
    final updated = LevelRecord(
      id: levelId,
      completed: previous.completed || result.won,
      stars: math.max(previous.stars, result.won ? result.stars : 0),
      bestScore: math.max(previous.bestScore, result.score),
      bestTimeMs: faster ? result.elapsed.inMilliseconds : previous.bestTimeMs,
    );
    return LevelProgressMerge(
      progress: LevelProgress({..._records, levelId: updated}),
      newBestScore: result.score > previous.bestScore,
      newBestTime: faster,
      newBestStars: result.won && result.stars > previous.stars,
    );
  }
}
