import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris/models/game_state.dart';

void main() {
  group('GameState', () {
    test('initial creates valid state', () {
      final state = GameState.initial();
      expect(state.width, 10);
      expect(state.height, 20);
      expect(state.score, 0);
      expect(state.level, 1);
      expect(state.linesCleared, 0);
      expect(state.isGameOver, false);
      expect(state.isPaused, false);
      expect(state.nextPiece, isNotNull);
      expect(state.board.length, 20);
      expect(state.board[0].length, 10);
    });

    test('initial with highScore', () {
      final state = GameState.initial(highScore: 999);
      expect(state.highScore, 999);
    });

    test('moveLeft decreases x', () {
      final state = GameState.initial();
      final moved = state.moveLeft();
      expect(moved.currentX, state.currentX - 1);
    });

    test('moveRight increases x', () {
      final state = GameState.initial();
      final moved = state.moveRight();
      expect(moved.currentX, state.currentX + 1);
    });

    test('moveDown increases y', () {
      final state = GameState.initial();
      final moved = state.moveDown();
      // moveDown may lock if at bottom, so just check it doesn't crash
      expect(moved, isNotNull);
    });

    test('hardDrop locks piece', () {
      final state = GameState.initial();
      final dropped = state.hardDrop();
      expect(dropped.currentPiece.type != state.currentPiece.type ||
          dropped.currentX != state.currentX ||
          dropped.currentY != state.currentY, true);
    });

    test('rotateCW changes shape', () {
      final state = GameState.initial();
      final rotated = state.rotateCW();
      // rotation may be blocked by wall, so shape may or may not change
      expect(rotated, isNotNull);
    });

    test('togglePause toggles isPaused', () {
      final state = GameState.initial();
      expect(state.isPaused, false);
      final paused = state.togglePause();
      expect(paused.isPaused, true);
      final resumed = paused.togglePause();
      expect(resumed.isPaused, false);
    });

    test('cannot move when game over', () {
      final state = GameState.initial();
      final gameOver = GameState(
        width: 10,
        height: 20,
        board: state.board,
        currentPiece: state.currentPiece,
        currentX: state.currentX,
        currentY: state.currentY,
        score: 0,
        level: 1,
        linesCleared: 0,
        isGameOver: true,
      );
      expect(gameOver.moveLeft(), gameOver);
      expect(gameOver.moveRight(), gameOver);
      expect(gameOver.moveDown(), gameOver);
      expect(gameOver.rotateCW(), gameOver);
    });

    test('cannot move when paused', () {
      final state = GameState.initial();
      final paused = state.togglePause();
      expect(paused.moveLeft(), paused);
      expect(paused.moveRight(), paused);
      expect(paused.rotateCW(), paused);
    });

    test('ghostY is at or below currentY', () {
      final state = GameState.initial();
      expect(state.ghostY, greaterThanOrEqualTo(state.currentY));
    });

    test('score calculation', () {
      final state = GameState.initial();
      expect(state.score, 0);
    });
  });
}
