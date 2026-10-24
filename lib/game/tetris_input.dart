import 'dart:ui';

/// 棋盘滑动手势方向。
enum SwipeDirection { up, down, left, right }

/// 一次滑动对应的游戏动作。
enum SwipeAction { rotate, hardDrop, moveLeft, moveRight }

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

  /// 滑动位移对应的动作；不足 [swipeThreshold] 时返回 null，不算滑动。
  static SwipeAction? actionFromDelta(Offset delta) {
    if (delta.distance < swipeThreshold) {
      return null;
    }
    return switch (directionFromDelta(delta)) {
      SwipeDirection.up => SwipeAction.rotate,
      SwipeDirection.down => SwipeAction.hardDrop,
      SwipeDirection.left => SwipeAction.moveLeft,
      SwipeDirection.right => SwipeAction.moveRight,
    };
  }
}
