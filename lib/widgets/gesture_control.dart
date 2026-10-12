import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 手势方向。
enum GestureDirection { up, down, left, right }

/// 把一整块区域变成手势控制层的组件。
///
/// - 点击：回调 [onTap]；
/// - 滑动：按滑动方向回调 [onSwipe]。
///
/// 参考 flutter-snake 的操控方式，使棋盘本身即可操作，
/// 键盘快捷键与虚拟按键作为互补手段。
///
/// 横纵向分别使用独立的拖拽识别器，避免与外层可滚动区域争抢手势。
class GestureControl extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final void Function(GestureDirection direction) onSwipe;

  const GestureControl({
    super.key,
    required this.onTap,
    required this.onSwipe,
    required this.child,
  });

  /// 触发一次滑动所需的最小位移（逻辑像素）。
  static const double swipeThreshold = 16;

  /// 由位移向量推断方向：取横纵分量中占优的一轴。
  static GestureDirection directionFromDelta(Offset delta) {
    if (delta.dx.abs() > delta.dy.abs()) {
      return delta.dx > 0 ? GestureDirection.right : GestureDirection.left;
    }
    return delta.dy > 0 ? GestureDirection.down : GestureDirection.up;
  }

  @override
  State<GestureControl> createState() => _GestureControlState();
}

class _GestureControlState extends State<GestureControl> {
  Offset _dragDelta = Offset.zero;

  void _resetDrag() {
    _dragDelta = Offset.zero;
  }

  void _accumulate(DragUpdateDetails details) {
    _dragDelta += details.delta;
  }

  void _finishDrag() {
    final delta = _dragDelta;
    _resetDrag();
    if (delta.distance < GestureControl.swipeThreshold) return;
    widget.onSwipe(GestureControl.directionFromDelta(delta));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.down,
      onTapUp: (_) => widget.onTap(),
      onVerticalDragStart: (_) => _resetDrag(),
      onVerticalDragUpdate: _accumulate,
      onVerticalDragEnd: (_) => _finishDrag(),
      onVerticalDragCancel: _resetDrag,
      onHorizontalDragStart: (_) => _resetDrag(),
      onHorizontalDragUpdate: _accumulate,
      onHorizontalDragEnd: (_) => _finishDrag(),
      onHorizontalDragCancel: _resetDrag,
      child: widget.child,
    );
  }
}
