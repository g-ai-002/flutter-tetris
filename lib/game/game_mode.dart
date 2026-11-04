/// 三种玩法：经典无尽、40 行竞速、2 分钟计时。
enum GameMode { endless, sprint, ultra }

extension GameModeInfo on GameMode {
  String get label => switch (this) {
    GameMode.endless => '经典模式',
    GameMode.sprint => '40 行竞速',
    GameMode.ultra => '2 分钟计时',
  };

  String get tagline => switch (this) {
    GameMode.endless => '无尽堆叠，每 10 行提速',
    GameMode.sprint => '以最快速度消除 40 行',
    GameMode.ultra => '120 秒内尽可能多得分',
  };

  /// 需要消除的目标行数，经典模式没有上限。
  int? get targetLines => switch (this) {
    GameMode.endless => null,
    GameMode.sprint => 40,
    GameMode.ultra => null,
  };

  /// 限时秒数，只有计时模式有。
  Duration? get timeLimit => switch (this) {
    GameMode.endless => null,
    GameMode.sprint => null,
    GameMode.ultra => const Duration(seconds: 120),
  };
}

/// 一局结束后的结果。
class GameResult {
  const GameResult({
    required this.mode,
    required this.score,
    required this.lines,
    required this.level,
    required this.pieces,
    required this.maxCombo,
    required this.elapsed,
    required this.won,
    required this.reason,
  });

  final GameMode mode;
  final int score;
  final int lines;
  final int level;
  final int pieces;
  final int maxCombo;
  final Duration elapsed;

  /// 是否完成目标（目前只有 40 行竞速会赢）。
  final bool won;
  final String reason;
}
