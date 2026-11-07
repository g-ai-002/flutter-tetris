/// 六种玩法：经典无尽、40 行竞速、2 分钟计时、街机、关卡挑战与每日挑战。
enum GameMode { endless, sprint, ultra, arcade, level, daily }

extension GameModeInfo on GameMode {
  String get label => switch (this) {
    GameMode.endless => '经典模式',
    GameMode.sprint => '40 行竞速',
    GameMode.ultra => '2 分钟计时',
    GameMode.arcade => '街机模式',
    GameMode.level => '关卡模式',
    GameMode.daily => '每日挑战',
  };

  String get tagline => switch (this) {
    GameMode.endless => '无尽堆叠，每 10 行提速',
    GameMode.sprint => '以最快速度消除 40 行',
    GameMode.ultra => '120 秒内尽可能多得分',
    GameMode.arcade => '红白机规则：帧表重力与经典计分',
    GameMode.level => '逐关挑战预设地形与限时目标',
    GameMode.daily => '同一天同一副牌，刷出今日最高分',
  };

  /// 需要消除的目标行数，经典模式与关卡模式由具体规则决定。
  int? get targetLines => switch (this) {
    GameMode.endless => null,
    GameMode.sprint => 40,
    GameMode.ultra => null,
    GameMode.arcade => null,
    GameMode.level => null,
    GameMode.daily => null,
  };

  /// 限时秒数，计时模式与每日挑战有。
  Duration? get timeLimit => switch (this) {
    GameMode.endless => null,
    GameMode.sprint => null,
    GameMode.ultra => const Duration(seconds: 120),
    GameMode.arcade => null,
    GameMode.level => null,
    GameMode.daily => const Duration(seconds: 120),
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
    this.challengeKey,
    this.tetrises = 0,
    this.tSpins = 0,
    this.perfectClears = 0,
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

  /// 每日挑战的日期键（`yyyyMMdd`），其他模式为 null。
  final String? challengeKey;

  /// 本局四行消除、T-Spin 消除与全消次数，用于累计成就进度。
  final int tetrises;
  final int tSpins;
  final int perfectClears;

  final String reason;
}
