import 'package:flutter_tetris/game/game_mode.dart';
import 'package:flutter_tetris/game/tetris_controller.dart';
import 'package:flutter_tetris/providers/settings_provider.dart';
import 'package:flutter_tetris/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  test('逻辑更新速率提供 30 / 60 / 120Hz，默认 60Hz', () {
    expect(AppConstants.logicRates, [30, 60, 120]);
    expect(AppConstants.defaultLogicRate, 60);
    expect(AppConstants.logicInterval(30), const Duration(microseconds: 33333));
    expect(AppConstants.logicInterval(60), const Duration(microseconds: 16666));
    expect(AppConstants.logicInterval(120), const Duration(microseconds: 8333));
  });

  test('偏好默认 60Hz，可切换并保存', () async {
    final storage = await prepareStorage();
    final settings = SettingsProvider(storage);
    expect(settings.logicRate, 60);

    await settings.setLogicRate(120);
    expect(storage.logicRate, 120);
    await settings.setLogicRate(30);
    expect(storage.logicRate, 30);
  });

  test('非法偏好值回退到 60Hz', () async {
    final storage = await prepareStorage({AppConstants.prefKeyLogicRate: 999});
    expect(storage.logicRate, 60);
  });

  test('控制器按给定速率驱动逻辑更新', () {
    final fast = TetrisController(
      mode: GameMode.endless,
      autoTick: false,
      tickInterval: AppConstants.logicInterval(120),
    );
    expect(fast.tickInterval, const Duration(microseconds: 8333));
    fast.dispose();

    final standard = TetrisController(mode: GameMode.endless, autoTick: false);
    expect(standard.tickInterval, const Duration(microseconds: 16666));
    standard.dispose();
  });
}
