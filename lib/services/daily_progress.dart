import 'dart:convert';
import 'dart:math' as math;

import '../game/game_mode.dart';
import '../utils/formatters.dart';

/// 某一天的每日挑战成绩。
class DailyRecord {
  const DailyRecord({
    required this.key,
    this.bestScore = 0,
    this.bestLines = 0,
    this.bestLevel = 1,
    this.plays = 0,
  });

  /// `yyyyMMdd`
  final String key;
  final int bestScore;
  final int bestLines;
  final int bestLevel;
  final int plays;

  bool get played => plays > 0;

  DailyRecord copyWith({
    int? bestScore,
    int? bestLines,
    int? bestLevel,
    int? plays,
  }) => DailyRecord(
    key: key,
    bestScore: bestScore ?? this.bestScore,
    bestLines: bestLines ?? this.bestLines,
    bestLevel: bestLevel ?? this.bestLevel,
    plays: plays ?? this.plays,
  );

  Map<String, Object?> toJson() => {
    'score': bestScore,
    'lines': bestLines,
    'level': bestLevel,
    'plays': plays,
  };

  static DailyRecord fromJson(String key, Object? raw) {
    if (raw is! Map) return DailyRecord(key: key);
    return DailyRecord(
      key: key,
      bestScore: (raw['score'] as num?)?.toInt() ?? 0,
      bestLines: (raw['lines'] as num?)?.toInt() ?? 0,
      bestLevel: (raw['level'] as num?)?.toInt() ?? 1,
      plays: (raw['plays'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 合并一局每日挑战结果后的纪录变化。
class DailyProgressMerge {
  const DailyProgressMerge({
    required this.progress,
    required this.newBestScore,
    required this.newBestLines,
  });

  final DailyProgress progress;
  final bool newBestScore;
  final bool newBestLines;

  bool get isRecord => newBestScore || newBestLines;
}

/// 每日挑战的本地进度：按天保存最高分、消行、等级与对局次数。
/// 纯数据对象，负责序列化、合并与连续打卡计算，不依赖具体存储实现。
class DailyProgress {
  const DailyProgress(this._records);

  DailyProgress.empty() : this(const {});

  final Map<String, DailyRecord> _records;

  Map<String, DailyRecord> get records => Map.unmodifiable(_records);

  factory DailyProgress.decode(String? raw) {
    if (raw == null || raw.isEmpty) return DailyProgress.empty();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return DailyProgress.empty();
      final records = <String, DailyRecord>{};
      for (final entry in decoded.entries) {
        records['${entry.key}'] = DailyRecord.fromJson(
          '${entry.key}',
          entry.value,
        );
      }
      return DailyProgress(records);
    } catch (_) {
      return DailyProgress.empty();
    }
  }

  String encode() => jsonEncode({
    for (final entry in _records.entries) entry.key: entry.value.toJson(),
  });

  DailyRecord record(String key) => _records[key] ?? DailyRecord(key: key);

  /// 有对局记录的日期数量。
  int get playedDays => _records.values.where((record) => record.played).length;

  /// 连续打卡天数：从今天（今天还没玩则从昨天）向前数连续有对局的天数。
  int streak(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    var cursor = today;
    if (!record(formatDateKey(cursor)).played) {
      cursor = DateTime(today.year, today.month, today.day - 1);
    }
    var count = 0;
    while (record(formatDateKey(cursor)).played) {
      count++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return count;
  }

  /// 合并一局结果；只升不降。
  DailyProgressMerge merge(GameResult result) {
    final key = result.challengeKey;
    if (key == null) {
      return DailyProgressMerge(
        progress: this,
        newBestScore: false,
        newBestLines: false,
      );
    }
    final previous = record(key);
    final updated = previous.copyWith(
      bestScore: math.max(previous.bestScore, result.score),
      bestLines: math.max(previous.bestLines, result.lines),
      bestLevel: math.max(previous.bestLevel, result.level),
      plays: previous.plays + 1,
    );
    return DailyProgressMerge(
      progress: DailyProgress({..._records, key: updated}),
      newBestScore: result.score > previous.bestScore,
      newBestLines: result.lines > previous.bestLines,
    );
  }
}
