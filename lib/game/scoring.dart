/// 计分规则：以官方 Guideline 为基准，按等级放大。
library;

/// 普通消行基础分（1/2/3/4 行）。
const List<int> kLineClearBase = [0, 100, 300, 500, 800];

/// T-Spin 基础分：0 行、单消、双消、三消。
const List<int> kTSpinBase = [400, 800, 1200, 1600];

/// T-Spin Mini 基础分：0 行、单消。
const List<int> kTSpinMiniBase = [100, 200];

/// 全消奖励（1/2/3/4 行）。
const List<int> kPerfectClearBonus = [0, 800, 1200, 1800, 2000];

/// 计算一次落定带来的分数。
///
/// [combo] 为本次消行之前的连续消行次数，首消不加连击分，
/// 第二次起按 `50 x 连击数 x 等级` 累加。
int clearScore({
  required int lines,
  required int level,
  bool tSpin = false,
  bool mini = false,
  bool backToBack = false,
  bool perfectClear = false,
  int combo = 0,
}) {
  if (lines < 0 || lines > 4) return 0;
  var base = kLineClearBase[lines];
  if (tSpin) {
    if (mini && lines <= 1) {
      base = kTSpinMiniBase[lines];
    } else {
      base = kTSpinBase[lines];
    }
  }
  var total = base * level;
  if (lines > 0 && backToBack) {
    total = (total * 1.5).round();
  }
  if (perfectClear) {
    total += kPerfectClearBonus[lines] * level;
  }
  if (combo > 0) {
    total += 50 * combo * level;
  }
  return total;
}

/// 等级：每消 10 行提升一级，最高 15 级，避免速度失控。
///
/// [startLevel] 用于关卡模式从更高的起始等级开始。
int levelForLines(int lines, {int startLevel = 1}) {
  final base = startLevel < 1 ? 1 : startLevel;
  final level = base + lines ~/ 10;
  return level > 15 ? 15 : level;
}

/// 每级的下落间隔，数值取自 Guideline 速度表并做上限收敛。
Duration gravityForLevel(int level) {
  const table = <int>[
    1000,
    793,
    618,
    473,
    355,
    262,
    190,
    135,
    94,
    64,
    43,
    28,
    18,
    11,
    7,
  ];
  final index = (level - 1).clamp(0, table.length - 1);
  return Duration(milliseconds: table[index]);
}
