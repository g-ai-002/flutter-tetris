import 'package:flutter/foundation.dart';

import 'tetromino.dart';

/// 游戏场地：10 列，顶部 1 行留在可视区域之外，用于方块出生与旋转。
class Board {
  Board({this.columns = 10, this.rows = 21, this.hiddenRows = 1})
    : assert(rows > hiddenRows && hiddenRows >= 0),
      _cells = List.generate(
        rows,
        (_) => List<TetrominoType?>.filled(columns, null),
      );

  final int columns;
  final int rows;

  /// 顶部隐藏行数，渲染时从 [hiddenRows] 行开始绘制。
  final int hiddenRows;

  List<List<TetrominoType?>> _cells;

  /// 只读访问某一格，越界返回 null。
  TetrominoType? at(int x, int y) {
    if (x < 0 || x >= columns || y < 0 || y >= rows) return null;
    return _cells[y][x];
  }

  bool isFilled(int x, int y) => at(x, y) != null;

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
    while (kept.length < rows) {
      kept.insert(0, List<TetrominoType?>.filled(columns, null));
    }
    _cells = kept;
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

  bool get isEmpty => filledCount == 0;

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
  void setCell(int x, int y, TetrominoType? type) {
    if (x < 0 || x >= columns || y < 0 || y >= rows) return;
    _cells[y][x] = type;
  }

  void reset() {
    _cells = List.generate(
      rows,
      (_) => List<TetrominoType?>.filled(columns, null),
    );
  }

  /// 测试与调试用：把棋盘渲染成字符画，`.` 为空，字母为方块类型。
  String debugString() {
    final buffer = StringBuffer();
    for (var y = hiddenRows; y < rows; y++) {
      for (var x = 0; x < columns; x++) {
        final type = _cells[y][x];
        buffer.write(type?.code ?? '.');
      }
      if (y != rows - 1) buffer.writeln();
    }
    return buffer.toString();
  }
}
