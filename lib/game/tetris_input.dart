import 'dart:ui';

/// 棋盘滑动手势方向。
enum SwipeDirection { up, down, left, right }

/// 手势换算的纯逻辑，便于单测。
class TetrisInput {
  /// 触发一次滑动所需的最小位移（世界坐标）。
  static const double swipeThreshold = 12;

  static SwipeDirection directionFromDelta(Offset delta) {
    if (delta.dx.abs() > delta.dy.abs()) {
      return delta.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
    }
    return delta.dy > 0 ? SwipeDirection.down : SwipeDirection.up;
  }
}
