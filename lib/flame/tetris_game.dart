import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/tetris_controller.dart';
import 'playfield_component.dart';

/// Flame 游戏入口：负责把场地组件铺满可用区域，并在窗口尺寸变化时重新适配。
class TetrisGame extends FlameGame with KeyboardEvents {
  TetrisGame({required this.controller, required PlayfieldStyle style})
    : _style = ValueNotifier(style);

  final TetrisController controller;
  final ValueNotifier<PlayfieldStyle> _style;
  PlayfieldComponent? _field;

  PlayfieldStyle get style => _style.value;
  set style(PlayfieldStyle value) => _style.value = value;

  @override
  Color backgroundColor() => Colors.transparent;

  /// 按键统一交给对局页处理。返回 ignored 让事件继续冒泡，
  /// 否则 Flame 的焦点节点会吞掉方向键与空格。
  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) => KeyEventResult.ignored;

  @override
  Future<void> onLoad() async {
    final field = PlayfieldComponent(controller: controller, style: _style);
    _field = field;
    _fit(field);
    await add(field);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final field = _field;
    if (field != null) _fit(field);
  }

  void _fit(PlayfieldComponent field) {
    field
      ..size = size.clone()
      ..position = Vector2.zero();
  }
}
