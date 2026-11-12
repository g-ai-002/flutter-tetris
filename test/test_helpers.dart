import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris/game/tetris_controller.dart';
import 'package:flutter_tetris/providers/settings_provider.dart';
import 'package:flutter_tetris/services/storage_service.dart';
import 'package:flutter_tetris/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 初始化一份使用 mock 偏好的存储服务。
Future<StorageService> prepareStorage([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  StorageService.resetForTests();
  return StorageService.instance;
}

/// 用设置 Provider 与中文主题包裹被测页面。
Widget wrapPage({required Widget child, required StorageService storage, ThemeData? theme}) {
  return ChangeNotifierProvider(
    create: (_) => SettingsProvider(storage),
    child: MaterialApp(theme: theme ?? buildLightTheme(), home: child),
  );
}

/// 以 50ms 为步长推进控制器，避开单帧 100ms 的钳制。
void advance(TetrisController controller, int milliseconds) {
  var remaining = milliseconds;
  while (remaining > 0) {
    final step = remaining >= 50 ? 50 : remaining;
    controller.tick(Duration(milliseconds: step));
    remaining -= step;
  }
}
