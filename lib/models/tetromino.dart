import 'dart:math';

enum TetrominoType { I, O, T, S, Z, J, L }

class Tetromino {
  final TetrominoType type;
  final List<List<int>> shape;
  final int color;

  Tetromino(this.type, this.shape, this.color);

  static const Map<TetrominoType, List<List<int>>> _shapes = {
    TetrominoType.I: [
      [0, 0, 0, 0],
      [1, 1, 1, 1],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ],
    TetrominoType.O: [
      [1, 1],
      [1, 1],
    ],
    TetrominoType.T: [
      [0, 1, 0],
      [1, 1, 1],
      [0, 0, 0],
    ],
    TetrominoType.S: [
      [0, 1, 1],
      [1, 1, 0],
      [0, 0, 0],
    ],
    TetrominoType.Z: [
      [1, 1, 0],
      [0, 1, 1],
      [0, 0, 0],
    ],
    TetrominoType.J: [
      [1, 0, 0],
      [1, 1, 1],
      [0, 0, 0],
    ],
    TetrominoType.L: [
      [0, 0, 1],
      [1, 1, 1],
      [0, 0, 0],
    ],
  };

  static const Map<TetrominoType, int> _colors = {
    TetrominoType.I: 0xFF00BCD4,
    TetrominoType.O: 0xFFFFEB3B,
    TetrominoType.T: 0xFF9C27B0,
    TetrominoType.S: 0xFF4CAF50,
    TetrominoType.Z: 0xFFF44336,
    TetrominoType.J: 0xFF2196F3,
    TetrominoType.L: 0xFFFF9800,
  };

  factory Tetromino.create(TetrominoType type) {
    return Tetromino(type, _shapes[type]!, _colors[type]!);
  }

  static Tetromino random() {
    const types = TetrominoType.values;
    return Tetromino.create(types[Random().nextInt(types.length)]);
  }

  List<List<int>> rotateCW() {
    final n = shape.length;
    final rotated = List.generate(n, (_) => List.filled(n, 0));
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        rotated[c][n - 1 - r] = shape[r][c];
      }
    }
    return rotated;
  }

  List<List<int>> rotateCCW() {
    final n = shape.length;
    final rotated = List.generate(n, (_) => List.filled(n, 0));
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        rotated[n - 1 - c][r] = shape[r][c];
      }
    }
    return rotated;
  }
}
