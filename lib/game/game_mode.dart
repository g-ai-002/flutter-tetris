/// 四种玩法：经典无尽、40 行竞速、2 分钟计时与关卡挑战。
enum GameMode { endless, sprint, ultra, level }

extension GameModeInfo on GameMode {
  String get label => switch (this) {
    GameMode.endless => '经典模式',
    GameMode.sprint => '40 行竞速',
    GameMode.ultra => '2 分钟计时',
    GameMode.level => '关卡模式',
  };

  String get tagline => switch (this) {
    GameMode.endless => '无尽堆叠，每 10 行提速',
    GameMode.sprint => '以最快速度消除 40 行',
    GameMode.ultra => '120 秒内尽可能多得分',
    GameMode.level => '逐关挑战预设地形与限时目标',
  };

  /// 需要消除的目标行数，经典模式与关卡模式由具体规则决定。
  int? get targetLines => switch (this) {
    GameMode.endless => null,
    GameMode.sprint => 40,
    GameMode.ultra => null,
    GameMode.level => null,
  };

  /// 限时秒数，只有计时模式有。
  Duration? get timeLimit => switch (this) {
    GameMode.endless => null,
    GameMode.sprint => null,
    GameMode.ultra => const Duration(seconds: 120),
    GameMode.level => null,
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
    this.levelId,
    this.stars = 0,
  });

  final GameMode mode;
  final int score;
  final int lines;
  final int level;
  final int pieces;
  final int maxCombo;
  final Duration elapsed;

  /// 是否完成目标（40 行竞速或关卡目标）。
  final bool won;

  /// 关卡编号，非关卡模式为 null。
  final int? levelId;

  /// 通关星级（1~3），未通关为 0。
  final int stars;

  final String reason;
}
