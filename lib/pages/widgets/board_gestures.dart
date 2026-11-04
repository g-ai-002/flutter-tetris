import 'package:flutter/material.dart';

import '../../game/tetris_controller.dart';

/// 棋盘上的手势操作：单击旋转、左右拖动移动、下滑软降、上滑暂存。
class BoardGestureLayer extends StatefulWidget {
  const BoardGestureLayer({
    super.key,
    required this.controller,
    required this.child,
  });

  final TetrisController controller;
  final Widget child;

  @override
  State<BoardGestureLayer> createState() => _BoardGestureLayerState();
}

class _BoardGestureLayerState extends State<BoardGestureLayer> {
  static const double _step = 22;

  double _dx = 0;
  double _dy = 0;

  void _reset() => _dx = _dy = 0;

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.controller.canControl) return;
    _dx += details.delta.dx;
    _dy += details.delta.dy;
    while (_dx >= _step) {
      widget.controller.moveRight();
      _dx -= _step;
    }
    while (_dx <= -_step) {
      widget.controller.moveLeft();
      _dx += _step;
    }
    while (_dy >= _step * 1.4) {
      widget.controller.softDrop();
      _dy -= _step * 1.4;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dy <= -40) widget.controller.hold();
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.controller.rotateClockwise,
      onPanStart: (_) => _reset(),
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: _reset,
      child: widget.child,
    );
  }
}
