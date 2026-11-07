/// 方块形状定义：坐标以 4x4 / 3x3 包围盒左上角为原点，y 轴向下。
library;

/// 方块内的单个格子坐标。
class Block {
  const Block(this.x, this.y);

  final int x;
  final int y;

  Block operator +(Block other) => Block(x + other.x, y + other.y);

  @override
  bool operator ==(Object other) =>
      other is Block && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';
}

/// 七种标准方块。
enum TetrominoType { i, o, t, s, z, j, l }

extension TetrominoTypeInfo on TetrominoType {
  /// 英文代号，用于预览与调试。
  String get code => switch (this) {
    TetrominoType.i => 'I',
    TetrominoType.o => 'O',
    TetrominoType.t => 'T',
    TetrominoType.s => 'S',
    TetrominoType.z => 'Z',
    TetrominoType.j => 'J',
    TetrominoType.l => 'L',
  };
}

/// 每种方块的四个旋转态，索引 0 为出生态，顺时针依次递增。
///
/// JLSTZ 使用 SRS 的 3x3 包围盒，I 使用 4x4 包围盒，O 不变。
const Map<TetrominoType, List<List<Block>>> kTetrominoShapes = {
  TetrominoType.i: [
    [Block(0, 1), Block(1, 1), Block(2, 1), Block(3, 1)],
    [Block(2, 0), Block(2, 1), Block(2, 2), Block(2, 3)],
    [Block(0, 2), Block(1, 2), Block(2, 2), Block(3, 2)],
    [Block(1, 0), Block(1, 1), Block(1, 2), Block(1, 3)],
  ],
  TetrominoType.o: [
    [Block(1, 0), Block(2, 0), Block(1, 1), Block(2, 1)],
    [Block(1, 0), Block(2, 0), Block(1, 1), Block(2, 1)],
    [Block(1, 0), Block(2, 0), Block(1, 1), Block(2, 1)],
    [Block(1, 0), Block(2, 0), Block(1, 1), Block(2, 1)],
  ],
  TetrominoType.t: [
    [Block(1, 0), Block(0, 1), Block(1, 1), Block(2, 1)],
    [Block(1, 0), Block(1, 1), Block(2, 1), Block(1, 2)],
    [Block(0, 1), Block(1, 1), Block(2, 1), Block(1, 2)],
    [Block(1, 0), Block(0, 1), Block(1, 1), Block(1, 2)],
  ],
  TetrominoType.s: [
    [Block(1, 0), Block(2, 0), Block(0, 1), Block(1, 1)],
    [Block(1, 0), Block(1, 1), Block(2, 1), Block(2, 2)],
    [Block(1, 1), Block(2, 1), Block(0, 2), Block(1, 2)],
    [Block(0, 0), Block(0, 1), Block(1, 1), Block(1, 2)],
  ],
  TetrominoType.z: [
    [Block(0, 0), Block(1, 0), Block(1, 1), Block(2, 1)],
    [Block(2, 0), Block(1, 1), Block(2, 1), Block(1, 2)],
    [Block(0, 1), Block(1, 1), Block(1, 2), Block(2, 2)],
    [Block(1, 0), Block(0, 1), Block(1, 1), Block(0, 2)],
  ],
  TetrominoType.j: [
    [Block(0, 0), Block(0, 1), Block(1, 1), Block(2, 1)],
    [Block(1, 0), Block(2, 0), Block(1, 1), Block(1, 2)],
    [Block(0, 1), Block(1, 1), Block(2, 1), Block(2, 2)],
    [Block(1, 0), Block(1, 1), Block(0, 2), Block(1, 2)],
  ],
  TetrominoType.l: [
    [Block(2, 0), Block(0, 1), Block(1, 1), Block(2, 1)],
    [Block(1, 0), Block(1, 1), Block(1, 2), Block(2, 2)],
    [Block(0, 1), Block(1, 1), Block(2, 1), Block(0, 2)],
    [Block(0, 0), Block(1, 0), Block(1, 1), Block(1, 2)],
  ],
};

/// 出生位置：所有方块从第 3 列开始，SRS 的出生列一致。
const int kSpawnColumn = 3;

/// 正在下落的方块。
class ActivePiece {
  const ActivePiece({
    required this.type,
    required this.x,
    required this.y,
    this.rotation = 0,
  });

  final TetrominoType type;
  final int x;
  final int y;

  /// 0 为出生态，1/2/3 为顺时针旋转后的状态。
  final int rotation;

  List<Block> get localBlocks => kTetrominoShapes[type]![rotation];

  List<Block> get blocks => [
    for (final block in localBlocks) Block(x + block.x, y + block.y),
  ];

  ActivePiece copyWith({int? x, int? y, int? rotation}) => ActivePiece(
    type: type,
    x: x ?? this.x,
    y: y ?? this.y,
    rotation: rotation ?? this.rotation,
  );

  /// 消行动画与音效按方块类型取色。
  @override
  String toString() => '${type.code}@($x,$y,r$rotation)';
}
