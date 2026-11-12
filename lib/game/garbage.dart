import 'dart:math';

/// 垃圾行上涌规则。
class GarbageRule {
  const GarbageRule({required this.interval, this.rowsPerRise = 1}) : assert(rowsPerRise > 0);

  /// 两次上涌之间的间隔。
  final Duration interval;

  /// 每次上涌的行数。
  final int rowsPerRise;
}

/// 按固定间隔产出垃圾行缺口，随机序列由种子决定；只负责计时与缺口生成，
/// 不直接操作场地，因此上涌节奏可以独立测试。
class GarbageSpawner {
  GarbageSpawner({this.rule, int seed = 0}) : _seed = seed, _random = Random(seed);

  final GarbageRule? rule;
  final int _seed;
  Random _random;

  Duration _elapsed = Duration.zero;
  int _rises = 0;

  bool get enabled => rule != null;

  /// 已上涌的行批次数。
  int get rises => _rises;

  /// 距下一次上涌的整秒数，未启用时为 null。
  int? get secondsLeft {
    final current = rule;
    if (current == null) return null;
    final left = current.interval - _elapsed;
    return left.isNegative ? 0 : left.inSeconds;
  }

  /// 推进计时，返回本次到期的缺口列号；每行一个缺口。
  List<List<int>> advance(Duration step, int columns) {
    final current = rule;
    if (current == null || current.interval <= Duration.zero || columns <= 0) {
      return const [];
    }
    _elapsed += step;
    final due = <List<int>>[];
    while (_elapsed >= current.interval) {
      _elapsed -= current.interval;
      _rises++;
      due.add([for (var i = 0; i < current.rowsPerRise; i++) _random.nextInt(columns)]);
    }
    return due;
  }

  /// 重新开始：清空计时与计数，并回到初始随机序列。
  void reset() {
    _elapsed = Duration.zero;
    _rises = 0;
    _random = Random(_seed);
  }
}
