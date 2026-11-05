import 'seeded_random.dart';
import 'tetromino.dart';

/// 七包随机：每七个方块为一轮，保证不会长时间不出某一种方块。
///
/// 使用 [SeededRandom] 而不是 `dart:math` 的随机数，保证每日挑战
/// 在 Android / Windows / Web 上拿到完全相同的方块序列。
class SevenBag {
  SevenBag({int? seed}) : _random = SeededRandom(seed ?? _entropy());

  SeededRandom _random;
  final List<TetrominoType> _queue = [];

  static int _sequence = 0;

  /// 取模而不是位运算，避免 Web 端 32 位整数语义带来的差异。
  static int _entropy() =>
      (DateTime.now().microsecondsSinceEpoch + _sequence++ * 7919) % 2147483647;

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
    if (seed != null) _random = SeededRandom(seed);
  }

  void _ensure(int count) {
    while (_queue.length < count) {
      final bag = TetrominoType.values.toList()..shuffle(_random);
      _queue.addAll(bag);
    }
  }
}
