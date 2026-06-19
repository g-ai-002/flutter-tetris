import 'package:flutter_tetris/providers/game_provider.dart';
import 'package:flutter_tetris/services/history_service.dart';
import 'package:flutter_tetris/services/sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GameProvider> createTestProvider() async {
  SharedPreferences.setMockInitialValues({});
  SoundService().resetForTest();
  HistoryService.resetForTest();
  final prefs = await SharedPreferences.getInstance();
  await SoundService().init(prefs);
  await HistoryService.init();
  return GameProvider(prefs);
}
