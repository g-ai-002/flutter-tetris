import 'package:flutter/widgets.dart';

import 'platform_info.dart';

/// 对局页的三种版式。
enum GameLayoutKind {
  /// 桌面三栏：左右信息栏夹住棋盘，桌面端附键盘提示。
  rails,

  /// 手机横屏：棋盘居中，两侧为触屏操作区，顶部一条轻量状态栏。
  sidePads,

  /// 手机与折叠屏竖屏：顶部数值、棋盘中列、底部操作区。
  stack,
}

/// 根据可用尺寸与平台选择版式：优先把高度让给棋盘，宽度只用于信息栏。
class GameLayout {
  const GameLayout(this.kind);

  factory GameLayout.of(Size size) {
    final landscape = size.width > size.height * 1.05;
    if (size.width >= 900 && size.height >= 500) {
      return const GameLayout(GameLayoutKind.rails);
    }
    if (isDesktopPlatform && landscape && size.width >= 760) {
      return const GameLayout(GameLayoutKind.rails);
    }
    if (landscape && !isDesktopPlatform) {
      return const GameLayout(GameLayoutKind.sidePads);
    }
    return const GameLayout(GameLayoutKind.stack);
  }

  final GameLayoutKind kind;

  bool get usesSidePads => kind == GameLayoutKind.sidePads;

  /// 横屏与矮窗口收起顶部栏的第二行标题，避免挤压棋盘。
  bool isShort(Size size) => size.height < 620;
}
