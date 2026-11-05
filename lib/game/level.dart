/// 关卡模式：预设地形、限时目标与垃圾行上涌。
library;

import 'garbage.dart';

/// 单个关卡的完整规则。
///
/// [terrain] 从下往上贴底摆放，每行 10 个字符：`.` 为空，`#` 为垃圾块，
/// `I O T S Z J L` 为对应颜色的方块。地形行数不超过可视高度。
class LevelDefinition {
  const LevelDefinition({
    required this.id,
    required this.name,
    required this.brief,
    required this.targetLines,
    required this.timeLimit,
    required this.terrain,
    required this.seed,
    this.startLevel = 1,
    this.garbage,
  }) : assert(id > 0),
       assert(targetLines > 0),
       assert(startLevel > 0),
       assert(seed > 0);

  final int id;
  final String name;
  final String brief;
  final int targetLines;
  final Duration timeLimit;
  final List<String> terrain;
  final int startLevel;

  /// 垃圾行上涌规则，null 表示本关不涨垃圾行。
  final GarbageRule? garbage;

  /// 固定随机种子，保证每关的方块序列与垃圾行缺口可复现。
  final int seed;

  bool get hasGarbageRise => garbage != null;

  /// 按剩余时间比例评星：剩余不少于 35% 得三星，不少于 12% 得两星。
  int starsFor(Duration elapsed) {
    final total = timeLimit.inMilliseconds;
    if (total <= 0) return 1;
    final ratio = (total - elapsed.inMilliseconds) / total;
    if (ratio >= 0.35) return 3;
    if (ratio >= 0.12) return 2;
    return 1;
  }
}

/// 12 个关卡，难度阶梯式上升。
const List<LevelDefinition> kLevels = [
  LevelDefinition(
    id: 1,
    name: '初入长安',
    brief: '空场三行，先熟悉手感',
    targetLines: 3,
    timeLimit: Duration(seconds: 90),
    terrain: [],
    seed: 101,
  ),
  LevelDefinition(
    id: 2,
    name: '残垣',
    brief: '底部一道缺口，稳扎稳打',
    targetLines: 5,
    timeLimit: Duration(seconds: 90),
    terrain: ['####.#####'],
    seed: 102,
  ),
  LevelDefinition(
    id: 3,
    name: '双峰',
    brief: '两处空穴，注意左右平衡',
    targetLines: 7,
    timeLimit: Duration(seconds: 100),
    terrain: ['##.####.##', '###.######'],
    seed: 103,
  ),
  LevelDefinition(
    id: 4,
    name: '古井',
    brief: '交错井口，耐心填平',
    targetLines: 9,
    timeLimit: Duration(seconds: 110),
    terrain: ['###.######', '####.#####', '###.######'],
    seed: 104,
  ),
  LevelDefinition(
    id: 5,
    name: '落子无悔',
    brief: '垃圾行每 30 秒上涌一行',
    targetLines: 10,
    timeLimit: Duration(seconds: 110),
    terrain: ['#.####.###', '##.######.'],
    garbage: GarbageRule(interval: Duration(seconds: 30)),
    seed: 105,
  ),
  LevelDefinition(
    id: 6,
    name: '乱石岗',
    brief: '高低不平的残局',
    targetLines: 12,
    timeLimit: Duration(seconds: 120),
    terrain: ['####.#####', '.####.####', '###.##.###', '#####.####'],
    seed: 106,
  ),
  LevelDefinition(
    id: 7,
    name: '悬河',
    brief: '垃圾行每 24 秒上涌一行',
    targetLines: 15,
    timeLimit: Duration(seconds: 120),
    terrain: ['##.###.##.', '###.####.#', '#.####.###'],
    garbage: GarbageRule(interval: Duration(seconds: 24)),
    seed: 107,
  ),
  LevelDefinition(
    id: 8,
    name: '天井',
    brief: '两侧高墙，中间留井',
    targetLines: 15,
    timeLimit: Duration(seconds: 130),
    terrain: ['#.########', '########.#', '#.########', '########.#'],
    seed: 108,
  ),
  LevelDefinition(
    id: 9,
    name: '长坂坡',
    brief: '垃圾行每 20 秒上涌一行',
    targetLines: 18,
    timeLimit: Duration(seconds: 140),
    terrain: ['###.##.###', '####.#####', '##.######.', '###.####.#'],
    garbage: GarbageRule(interval: Duration(seconds: 20)),
    seed: 109,
  ),
  LevelDefinition(
    id: 10,
    name: '绝壁',
    brief: '五层残局，考验规划',
    targetLines: 20,
    timeLimit: Duration(seconds: 150),
    terrain: [
      '#.#.#.#.#.',
      '#.#.#.#.#.',
      '###...####',
      '##...#####',
      '####.#####',
    ],
    seed: 110,
  ),
  LevelDefinition(
    id: 11,
    name: '惊涛',
    brief: '每 18 秒上涌一行，步步紧逼',
    targetLines: 22,
    timeLimit: Duration(seconds: 150),
    terrain: ['####..####', '##.####.##', '###.######', '#.####.###'],
    garbage: GarbageRule(interval: Duration(seconds: 18)),
    seed: 111,
  ),
  LevelDefinition(
    id: 12,
    name: '长安归',
    brief: '最终试炼：残局、提速与上涌',
    targetLines: 25,
    timeLimit: Duration(seconds: 180),
    terrain: [
      '#.########',
      '##.######.',
      '###.######',
      '####.#####',
      '###.##.###',
    ],
    startLevel: 3,
    garbage: GarbageRule(interval: Duration(seconds: 20)),
    seed: 112,
  ),
];

LevelDefinition? levelById(int id) {
  for (final level in kLevels) {
    if (level.id == id) return level;
  }
  return null;
}

/// 下一关；已是最后一关时返回 null。
LevelDefinition? nextLevelOf(LevelDefinition level) => levelById(level.id + 1);
