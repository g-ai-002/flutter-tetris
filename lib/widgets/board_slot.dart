import 'package:flutter/material.dart';

/// 只用于占位的棋盘槽位：把自身在游戏页中的矩形回报给 Flame 相机。
///
/// 放在原来的棋盘布局位置（`AspectRatio` 等）里，布局尺寸与以前一致，真正的
/// 棋盘由铺满整页的 Flame 画布绘制。
class BoardSlot extends StatefulWidget {
  const BoardSlot({
    super.key,
    required this.pageKey,
    required this.onRect,
  });

  /// 游戏页根节点的 key，用于把槽位坐标换算成页面内坐标。
  final GlobalKey pageKey;

  /// 槽位矩形变化时回调（页面内坐标）。
  final ValueChanged<Rect> onRect;

  @override
  State<BoardSlot> createState() => _BoardSlotState();
}

class _BoardSlotState extends State<BoardSlot> {
  final GlobalKey _slotKey = GlobalKey();
  Rect? _lastRect;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportRect());
    return SizedBox.expand(key: _slotKey);
  }

  void _reportRect() {
    if (!mounted) return;
    final pageBox = widget.pageKey.currentContext?.findRenderObject();
    final slotBox = _slotKey.currentContext?.findRenderObject();
    if (pageBox is! RenderBox || slotBox is! RenderBox) return;
    if (!pageBox.hasSize || !slotBox.hasSize || slotBox.size.isEmpty) return;

    final rect =
        slotBox.localToGlobal(Offset.zero, ancestor: pageBox) & slotBox.size;
    if (rect == _lastRect) return;
    _lastRect = rect;
    widget.onRect(rect);
  }
}
