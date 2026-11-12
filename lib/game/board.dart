import 'package:flutter/foundation.dart';

import 'tetromino.dart';

/// 游戏场地：10 列，顶部 1 行留在可视区域之外，用于方块出生与旋转。
class Board {
  Board({this.columns = 10, this.rows = 21, this.hiddenRows = 1})
    : assert(rows > hiddenRows && hiddenRows >= 0),
      _cells = List.generate(rows, (_) => List<TetrominoType?>.filled(columns, null)),
      _garbage = List.generate(rows, (_) => List<bool>.filled(columns, false));

  final int columns;
  final int rows;

  /// 顶部隐藏行数，渲染时从 [hiddenRows] 行开始绘制。
  final int hiddenRows;

  List<List<TetrominoType?>> _cells;

  /// 与 [_cells] 同形的垃圾格标记，仅用于配色区分。
  List<List<bool>> _garbage;

  /// 只读访问某一格，越界返回 null。
  TetrominoType? at(int x, int y) {
    if (x < 0 || x >= columns || y < 0 || y >= rows) return null;
    return _cells[y][x];
  }

  /// 该格是否为预设地形或上涌产生的垃圾块。
  bool isGarbage(int x, int y) {
    if (x < 0 || x >= columns || y < 0 || y >= rows) return false;
    return _garbage[y][x];
  }

  /// 方块是否可以放置：左右不越界、不穿过底部、不与已落定的格子重叠。
  bool fits(Iterable<Block> blocks) {
    for (final block in blocks) {
      if (block.x < 0 || block.x >= columns || block.y >= rows) return false;
      if (block.y >= 0 && _cells[block.y][block.x] != null) return false;
    }
    return true;
  }

  /// 落定方块，调用前应先用 [fits] 校验。
  void lock(Iterable<Block> blocks, TetrominoType type) {
    for (final block in blocks) {
      if (block.x < 0 || block.x >= columns || block.y < 0 || block.y >= rows) {
        continue;
      }
      _cells[block.y][block.x] = type;
      _garbage[block.y][block.x] = false;
    }
  }

  /// 已填满的整行行号，从下往上排列。
  List<int> fullRows() {
    final result = <int>[];
    for (var y = rows - 1; y >= 0; y--) {
      var full = true;
      for (var x = 0; x < columns; x++) {
        if (_cells[y][x] == null) {
          full = false;
          break;
        }
      }
      if (full) result.add(y);
    }
    return result;
  }

  /// 删除指定行，并在顶部补空行。
  void removeRows(Iterable<int> rowsToRemove) {
    final removed = rowsToRemove.toSet();
    if (removed.isEmpty) return;
    final kept = <List<TetrominoType?>>[
      for (var y = 0; y < rows; y++)
        if (!removed.contains(y)) _cells[y],
    ];
    final keptGarbage = <List<bool>>[
      for (var y = 0; y < rows; y++)
        if (!removed.contains(y)) _garbage[y],
    ];
    while (kept.length < rows) {
      kept.insert(0, List<TetrominoType?>.filled(columns, null));
      keptGarbage.insert(0, List<bool>.filled(columns, false));
    }
    _cells = kept;
    _garbage = keptGarbage;
  }

  /// 载入关卡地形，从底部向上贴齐；字符含义见 [LevelDefinition.terrain]。
  void loadTerrain(List<String> terrain) {
    reset();
    final top = rows - terrain.length;
    for (var row = 0; row < terrain.length; row++) {
      final y = top + row;
      final cells = terrain[row];
      for (var x = 0; x < columns && x < cells.length; x++) {
        final code = cells[x];
        if (code == '.') continue;
        final garbage = code == '#';
        final type = garbage ? TetrominoType.o : tetrominoFromCode(code);
        if (type == null) continue;
        _cells[y][x] = type;
        _garbage[y][x] = garbage;
      }
    }
  }

  /// 垃圾行整体上涌：每行留一个缺口，顶部被挤出时返回 true。
  bool raiseGarbage(List<int> holes) {
    final count = holes.length;
    if (count <= 0 || count >= rows) return true;
    var overflow = false;
    for (var y = 0; y < count; y++) {
      for (var x = 0; x < columns; x++) {
        if (_cells[y][x] != null) overflow = true;
      }
    }
    for (var y = 0; y < rows - count; y++) {
      _cells[y] = _cells[y + count];
      _garbage[y] = _garbage[y + count];
    }
    for (var i = 0; i < count; i++) {
      final y = rows - count + i;
      _cells[y] = List<TetrominoType?>.filled(columns, TetrominoType.o);
      _garbage[y] = List<bool>.filled(columns, true);
      final hole = holes[i].clamp(0, columns - 1);
      _cells[y][hole] = null;
      _garbage[y][hole] = false;
    }
    return overflow;
  }

  int get filledCount {
    var count = 0;
    for (final row in _cells) {
      for (final cell in row) {
        if (cell != null) count++;
      }
    }
    return count;
  }

  /// 最高一堆方块距底部的行数，用于危险线提示。
  int get stackHeight {
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < columns; x++) {
        if (_cells[y][x] != null) return rows - y;
      }
    }
    return 0;
  }

  /// 测试与调试用：直接放置一格。
  @visibleForTesting
  void setCell(int x, int y, TetrominoType? type, {bool garbage = false}) {
    if (x < 0 || x >= columns || y < 0 || y >= rows) return;
    _cells[y][x] = type;
    _garbage[y][x] = type != null && garbage;
  }

  void reset() {
    _cells = List.generate(rows, (_) => List<TetrominoType?>.filled(columns, null));
    _garbage = List.generate(rows, (_) => List<bool>.filled(columns, false));
  }
}
