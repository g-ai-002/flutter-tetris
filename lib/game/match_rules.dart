import 'garbage.dart';
import 'game_mode.dart';
import 'level.dart';

/// 一局对局的规则快照。
///
/// 玩法差异（目标行数、限时）与关卡差异（地形、起始等级、垃圾行）
/// 都从这里读取，控制器不再散落 `levelDef?.x ?? mode.y` 的判断。
class MatchRules {
  const MatchRules({required this.mode, this.level});

  final GameMode mode;

  /// 关卡模式下要挑战的关卡，其他模式为 null。
  final LevelDefinition? level;

  bool get isLevel => level != null;

  int? get levelId => level?.id;

  /// 顶栏标题：关卡带编号与名称，其他模式使用玩法名。
  String get title =>
      level == null ? mode.label : '第 ${level!.id} 关 · ${level!.name}';

  /// 目标行数：关卡优先，其次玩法（40 行竞速）。
  int? get targetLines => level?.targetLines ?? mode.targetLines;

  /// 限时：关卡优先，其次玩法（2 分钟计时）。
  Duration? get timeLimit => level?.timeLimit ?? mode.timeLimit;

  /// 起始等级，关卡可以要求从更高等级开局。
  int get startLevel => level?.startLevel ?? 1;

  /// 关卡地形，其他模式为空。
  List<String> get terrain => level?.terrain ?? const [];

  /// 垃圾行规则，未启用时为 null。
  GarbageRule? get garbage => level?.garbage;

  /// 通关星级，非关卡模式固定为 0。
  int starsFor(Duration elapsed) => level?.starsFor(elapsed) ?? 0;
}
