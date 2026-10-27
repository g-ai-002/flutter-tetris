/// 单局游戏记录：排行榜与历史页共用的纯数据模型。
class GameRecord {
  final int score;
  final int level;
  final int linesCleared;
  final DateTime date;

  const GameRecord({
    required this.score,
    required this.level,
    required this.linesCleared,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'score': score,
        'level': level,
        'linesCleared': linesCleared,
        'date': date.toIso8601String(),
      };

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
        score: json['score'] as int,
        level: json['level'] as int,
        linesCleared: json['linesCleared'] as int,
        date: DateTime.parse(json['date'] as String),
      );
}
