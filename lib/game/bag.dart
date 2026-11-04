import 'dart:math';

import 'tetromino.dart';

/// 七包随机：每七个方块为一轮，保证不会长时间不出某一种方块。
class SevenBag {
  SevenBag({int? seed}) : _random = Random(seed);

  Random _random;
  final List<TetrominoType> _queue = [];

  TetrominoType next() {
    _ensure(1);
    return _queue.removeAt(0);
  }

  /// 预览接下来的 [count] 个方块，不消耗队列。
  List<TetrominoType> peek(int count) {
    _ensure(count);
    return List.unmodifiable(_queue.take(count));
  }

  void reset({int? seed}) {
    _queue.clear();
    if (seed != null) _random = Random(seed);
  }

  void _ensure(int count) {
    while (_queue.length < count) {
      final bag = TetrominoType.values.toList()..shuffle(_random);
      _queue.addAll(bag);
    }
  }
}
