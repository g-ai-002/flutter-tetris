class AppConstants {
  AppConstants._();

  static const String appName = '俄罗斯方块';
  static const String version = '0.9.0';

  static const String prefKeyDarkMode = 'dark_mode';
  static const String prefKeyHighScore = 'high_score';
  static const String prefKeySoundEnabled = 'sound_enabled';
  static const String prefKeyMusicEnabled = 'music_enabled';
  static const String prefKeyControlMode = 'control_mode';

  static const int boardWidth = 10;
  static const int boardHeight = 20;
}

/// 操控方式：屏幕手势与底部虚拟按键的组合方式。
enum ControlMode {
  both,
  buttons,
  gesture;

  String get label {
    switch (this) {
      case ControlMode.both:
        return '手势 + 按键';
      case ControlMode.buttons:
        return '仅虚拟按键';
      case ControlMode.gesture:
        return '仅手势';
    }
  }

  String get description {
    switch (this) {
      case ControlMode.both:
        return '点击/滑动屏幕控制，同时显示底部按键';
      case ControlMode.buttons:
        return '只使用底部方向按键，禁用屏幕手势';
      case ControlMode.gesture:
        return '只通过屏幕点击/滑动控制，隐藏底部按键';
    }
  }

  /// 从持久化的名称还原，未知值回退到默认的「手势 + 按键」。
  static ControlMode fromName(String? name) {
    return ControlMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => ControlMode.both,
    );
  }
}
