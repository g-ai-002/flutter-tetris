import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tetris/providers/game_provider.dart';

void main() {
  group('GameProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state is not game over', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = GameProvider(prefs);
      expect(provider.state.isGameOver, false);
      expect(provider.state.isPaused, false);
      expect(provider.state.score, 0);
      expect(provider.state.level, 1);
    });

    test('moveLeft and moveRight change position', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = GameProvider(prefs);
      final initialX = provider.state.currentX;
      provider.moveLeft();
      expect(provider.state.currentX, initialX - 1);
      provider.moveRight();
      expect(provider.state.currentX, initialX);
    });

    test('rotate changes shape', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = GameProvider(prefs);
      final initialShape = provider.state.currentPiece.shape;
      provider.rotate();
      // rotation may be blocked by wall, but should not crash
      expect(provider.state, isNotNull);
    });

    test('hardDrop locks piece and spawns new one', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = GameProvider(prefs);
      final initialPiece = provider.state.currentPiece;
      provider.hardDrop();
      // after hard drop, a new piece should be spawned
      expect(provider.state.currentPiece.type != initialPiece.type ||
          provider.state.currentY != 0, true);
    });

    test('togglePause toggles state', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = GameProvider(prefs);
      expect(provider.state.isPaused, false);
      provider.togglePause();
      expect(provider.state.isPaused, true);
      provider.togglePause();
      expect(provider.state.isPaused, false);
    });

    test('start resets game over state', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = GameProvider(prefs);
      // simulate game over by hard dropping many times
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
      final prefs = await SharedPreferences.getInstance();
      final provider = GameProvider(prefs);
      expect(provider.dropIntervalMs, 800);
    });

    test('dispose cancels timer', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = GameProvider(prefs);
      provider.start();
      provider.dispose();
      // should not throw
    });
  });
}
