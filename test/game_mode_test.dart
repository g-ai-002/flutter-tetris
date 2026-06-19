import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris/models/game_mode.dart';
import 'package:flutter_tetris/models/game_state.dart';
import 'package:flutter_tetris/models/tetromino.dart';

void main() {
  group('GameMode', () {
    test('classic mode has correct label', () {
      expect(GameMode.classic.label, '经典模式');
    });

    test('timed mode has correct label', () {
      expect(GameMode.timed.label, '限时模式');
    });

    test('challenge mode has correct label', () {
      expect(GameMode.challenge.label, '挑战模式');
    });

    test('all modes have descriptions', () {
      for (final mode in GameMode.values) {
        expect(mode.description, isNotEmpty);
      }
    });
  });

  group('ModeConfig', () {
    test('classic mode has no duration or target', () {
      const config = ModeConfig(GameMode.classic);
      expect(config.durationSeconds, 0);
      expect(config.targetLines, 0);
    });

    test('timed mode has 120 seconds', () {
      const config = ModeConfig(GameMode.timed);
      expect(config.durationSeconds, 120);
      expect(config.targetLines, 0);
    });

    test('challenge mode has 40 target lines', () {
      const config = ModeConfig(GameMode.challenge);
      expect(config.durationSeconds, 0);
      expect(config.targetLines, 40);
    });
  });

  group('GameState with modes', () {
    test('initial with classic mode', () {
      final state = GameState.initial(mode: GameMode.classic);
      expect(state.gameMode, GameMode.classic);
      expect(state.remainingSeconds, 0);
      expect(state.targetLines, 0);
      expect(state.isCompleted, false);
    });

    test('initial with timed mode', () {
      final state = GameState.initial(mode: GameMode.timed);
      expect(state.gameMode, GameMode.timed);
      expect(state.remainingSeconds, 120);
      expect(state.targetLines, 0);
    });

    test('initial with challenge mode', () {
      final state = GameState.initial(mode: GameMode.challenge);
      expect(state.gameMode, GameMode.challenge);
      expect(state.remainingSeconds, 0);
      expect(state.targetLines, 40);
    });

    test('tickSecond decreases remaining time', () {
      final state = GameState.initial(mode: GameMode.timed);
      final ticked = state.tickSecond();
      expect(ticked.remainingSeconds, 119);
    });

    test('tickSecond at zero causes game over', () {
      final piece = Tetromino.random();
      final state = GameState(
        width: 10, height: 20,
        board: List.generate(20, (_) => List.filled(10, 0)),
        currentPiece: piece,
        currentX: 3, currentY: 0,
        score: 0, level: 1, linesCleared: 0,
        gameMode: GameMode.timed,
        remainingSeconds: 1,
      );
      final ticked = state.tickSecond();
      expect(ticked.remainingSeconds, 0);
      expect(ticked.isGameOver, true);
    });

    test('tickSecond does nothing in classic mode', () {
      final state = GameState.initial(mode: GameMode.classic);
      final ticked = state.tickSecond();
      expect(ticked.remainingSeconds, 0);
      expect(ticked.isGameOver, false);
    });

    test('tickSecond does nothing when paused', () {
      final state = GameState.initial(mode: GameMode.timed);
      final paused = state.togglePause();
      final ticked = paused.tickSecond();
      expect(ticked.remainingSeconds, 120);
    });

    test('tickSecond does nothing when game over', () {
      final piece = Tetromino.random();
      final state = GameState(
        width: 10, height: 20,
        board: List.generate(20, (_) => List.filled(10, 0)),
        currentPiece: piece,
        currentX: 3, currentY: 0,
        score: 0, level: 1, linesCleared: 0,
        isGameOver: true,
        gameMode: GameMode.timed,
        remainingSeconds: 50,
      );
      final ticked = state.tickSecond();
      expect(ticked.remainingSeconds, 50);
    });

    test('challenge mode completion sets isCompleted', () {
      // fill 19 rows, then clear one more to reach 40 lines
      final board = List.generate(20, (r) {
        if (r == 19) {
          return [1, 1, 1, 1, 1, 1, 1, 1, 1, 0];
        }
        return List.filled(10, 0);
      });
      final piece = Tetromino.create(TetrominoType.I);
      final state = GameState(
        width: 10, height: 20,
        board: board,
        currentPiece: piece,
        currentX: 6, currentY: 18,
        score: 0, level: 1, linesCleared: 39,
        gameMode: GameMode.challenge,
        targetLines: 40,
      );
      final result = state.hardDrop();
      expect(result.isCompleted, true);
      expect(result.isGameOver, true);
    });
  });
}
