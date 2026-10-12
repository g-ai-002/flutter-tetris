import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tetris/providers/game_provider.dart';
import 'package:flutter_tetris/providers/settings_provider.dart';
import 'package:flutter_tetris/services/history_service.dart';
import 'package:flutter_tetris/services/sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 页面级测试所需的一整套 provider。
class TestProviders {
  final GameProvider game;
  final SettingsProvider settings;

  const TestProviders(this.game, this.settings);

  /// 同时注入 SettingsProvider 与 GameProvider。
  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<GameProvider>.value(value: game),
      ],
      child: child,
    );
  }
}

/// 初始化测试环境并返回一整套 provider，[values] 用于预置持久化设置。
Future<TestProviders> createTestProviders({Map<String, Object> values = const {}}) async {
  SharedPreferences.setMockInitialValues(values);
  SoundService().resetForTest();
  HistoryService.resetForTest();
  final prefs = await SharedPreferences.getInstance();
  await SoundService().init(prefs);
  await HistoryService.init();
  return TestProviders(GameProvider(prefs), SettingsProvider(prefs));
}

/// 只需要 GameProvider 时的便捷入口。
Future<GameProvider> createTestProvider() async {
  return (await createTestProviders()).game;
}
