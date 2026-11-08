import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'platform_info.dart';

/// 进入对局时收起状态栏与导航栏，换取完整画面。
/// 不改变屏幕方向：10×20 的场地在竖屏下更高，强制横屏反而压缩棋盘，
/// 手机横屏留给用户自行旋转，桌面与 Web 不做处理。
Future<void> enterGameDisplay() async {
  if (kIsWeb || isDesktopPlatform) return;
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

/// 离开对局页时恢复带系统栏的常规显示，屏幕方向始终交给系统。
Future<void> exitGameDisplay() async {
  if (kIsWeb || isDesktopPlatform) return;
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}
