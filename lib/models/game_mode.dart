enum GameMode {
  classic,
  timed,
  challenge;

  String get label {
    switch (this) {
      case GameMode.classic:
        return '经典模式';
      case GameMode.timed:
        return '限时模式';
      case GameMode.challenge:
        return '挑战模式';
    }
  }

  String get description {
    switch (this) {
      case GameMode.classic:
        return '标准俄罗斯方块，无限挑战最高分';
      case GameMode.timed:
        return '120 秒内尽可能获得高分';
      case GameMode.challenge:
        return '以最快速度消除 40 行';
    }
  }
}

class ModeConfig {
  final GameMode mode;

  const ModeConfig(this.mode);

  int get durationSeconds => mode == GameMode.timed ? 120 : 0;

  int get targetLines => mode == GameMode.challenge ? 40 : 0;
}
