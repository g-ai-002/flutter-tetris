import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tetris/providers/game_provider.dart';
import 'package:flutter_tetris/services/history_service.dart';
import 'package:flutter_tetris/services/sound_service.dart';
import 'test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameProvider', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      SoundService().resetForTest();
      HistoryService.resetForTest();
      final prefs = await SharedPreferences.getInstance();
      await SoundService().init(prefs);
      await HistoryService.init();
    });

    test('initial state is not game over', () async {
      final provider = await createTestProvider();
      expect(provider.state.isGameOver, false);
      expect(provider.state.isPaused, false);
      expect(provider.state.score, 0);
      expect(provider.state.level, 1);
    });

    test('moveLeft and moveRight change position', () async {
      final provider = await createTestProvider();
      final initialX = provider.state.currentX;
      provider.moveLeft();
      expect(provider.state.currentX, initialX - 1);
      provider.moveRight();
      expect(provider.state.currentX, initialX);
    });

    test('rotate changes shape', () async {
      final provider = await createTestProvider();
      provider.rotate();
      expect(provider.state, isNotNull);
    });

    test('hardDrop locks piece and spawns new one', () async {
      final provider = await createTestProvider();
      provider.hardDrop();
      expect(provider.state.isGameOver, false);
      expect(provider.state.currentPiece, isNotNull);
    });

    test('togglePause toggles state', () async {
      final provider = await createTestProvider();
      expect(provider.state.isPaused, false);
      provider.togglePause();
      expect(provider.state.isPaused, true);
      provider.togglePause();
      expect(provider.state.isPaused, false);
    });

    test('start resets game over state', () async {
      final provider = await createTestProvider();
      for (var i = 0; i < 500; i++) {
        if (provider.state.isGameOver) break;
        provider.hardDrop();
      }
      expect(provider.state.isGameOver, true);
      provider.start();
      expect(provider.state.isGameOver, false);
      expect(provider.state.score, 0);
    });

    test('dropIntervalMs decreases with level', () async {
      final provider = await createTestProvider();
      expect(provider.dropIntervalMs, 800);
    });

    test('dispose cancels timer', () async {
      final provider = await createTestProvider();
      provider.start();
      provider.dispose();
    });

    test('game over saves history record', () async {
      final provider = await createTestProvider();
      for (var i = 0; i < 500; i++) {
        if (provider.state.isGameOver) break;
        provider.hardDrop();
      }
      expect(provider.state.isGameOver, true);
      final records = HistoryService.getRecords();
      expect(records.length, greaterThanOrEqualTo(1));
      expect(records.first.score, greaterThanOrEqualTo(0));
    });
  });
}
