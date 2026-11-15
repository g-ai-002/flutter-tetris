import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'platform_info.dart';

/// 手机端统一沉浸显示：启动首页与对局页都收起状态栏与导航栏。
/// 不改变屏幕方向：10×20 的场地在竖屏下更高，旋转始终交给系统与用户；
/// 桌面与 Web 不做处理。
Future<void> enterImmersiveDisplay() async {
  if (kIsWeb || isDesktopPlatform) return;
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}
