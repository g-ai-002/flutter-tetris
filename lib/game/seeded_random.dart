import 'dart:math';

/// 跨平台一致的伪随机数：同一 seed 在 VM、Android 与 Web 上产出同一序列。
///
/// `dart:math` 的 [Random] 在不同编译目标下实现不同，每日挑战依赖固定序列，
/// 因此这里用只含整数乘法与取模的 Lehmer 发生器自行实现。
/// 中间结果不超过 2^47，在 Web 的 double 整数精度内也是精确的。
class SeededRandom implements Random {
  SeededRandom(int seed) : _state = _normalize(seed);

  static const int _modulus = 2147483647;
  static const int _multiplier = 48271;

  int _state;

  static int _normalize(int seed) {
    final value = seed.abs() % _modulus;
    return value == 0 ? 1 : value;
  }

  int _next() {
    _state = (_state * _multiplier) % _modulus;
    return _state;
  }

  @override
  int nextInt(int max) {
    if (max <= 0) throw ArgumentError.value(max, 'max', '必须为正数');
    return _next() % max;
  }

  @override
  double nextDouble() => _next() / _modulus;

  @override
  bool nextBool() => _next().isOdd;
}
