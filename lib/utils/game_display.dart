import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'platform_info.dart';

/// 进入对局时的显示模式。
///
/// 移动端收起状态栏与导航栏换取完整画面；竖屏且窄于 [narrowWidth] 的手机
/// 自动转为横屏，棋盘在横屏下能获得接近两倍的高度。桌面与 Web 不做处理。
Future<void> enterGameDisplay({
  required Size size,
  double narrowWidth = 600,
}) async {
  if (kIsWeb || isDesktopPlatform) return;
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  if (size.width < narrowWidth && size.height > size.width * 1.4) {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
}

/// 离开对局页时恢复常规显示模式与自动旋转。
Future<void> exitGameDisplay() async {
  if (kIsWeb || isDesktopPlatform) return;
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}
