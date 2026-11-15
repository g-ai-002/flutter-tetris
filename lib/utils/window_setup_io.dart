import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:window_manager/window_manager.dart';

import '../services/log_service.dart';
import 'constants.dart';

bool _retriedWindowSetup = false;

/// 桌面窗口初始化：仅 Windows 生效，设定初始尺寸并居中显示。
Future<void> setupDesktopWindow() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return;
  try {
    final window = WindowManager.instance.getCurrent();
    if (window == null) {
      // 原生窗口可能在首帧之前尚未注册，等首帧后再试一次。
      if (!_retriedWindowSetup) {
        _retriedWindowSetup = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => setupDesktopWindow());
      } else {
        LogService.warning('窗口管理器初始化失败: 未取到当前窗口');
      }
      return;
    }
    window.title = AppConstants.appName;
    window.titleBarStyle = TitleBarStyle.normal;
    window.isVisibleInTaskbar = true;
    window.minimumSize = const Size(420, 640).toNative();
    window.setSize(const Size(1080, 860).toNative(), false);
    window.center();
    window.show();
    window.focus();
  } catch (e) {
    LogService.warning('窗口管理器初始化失败: $e');
  }
}
