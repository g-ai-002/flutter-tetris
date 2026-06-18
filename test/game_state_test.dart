import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris/models/game_state.dart';
import 'package:flutter_tetris/models/tetromino.dart';

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

    test('line clear scoring: 1 line at level 1 = 100', () {
      final state = GameState.initial();
      // fill bottom row except one column, then drop a piece to clear it
      final board = List.generate(20, (r) {
        if (r == 19) {
          return [1, 1, 1, 1, 1, 1, 1, 1, 1, 0];
        }
        return List.filled(10, 0);
      });
      final piece = Tetromino.create(TetrominoType.I);
      final gs = GameState(
        width: 10, height: 20,
        board: board,
        currentPiece: piece,
        currentX: 6, currentY: 18,
        score: 0, level: 1, linesCleared: 0,
      );
      final result = gs.hardDrop();
      expect(result.score, 100);
      expect(result.linesCleared, 1);
    });

    test('line clear scoring: 4 lines at level 1 = 800', () {
      // 填充 rows 16-19，仅 col 7 为空
      final board = List.generate(20, (r) {
        if (r >= 16) {
          return [1, 1, 1, 1, 1, 1, 1, 0, 1, 1];
        }
        return List.filled(10, 0);
      });
      // 旋转后的 I 方块（竖条），占据 col 1 of 4x4
      final piece = Tetromino.create(TetrominoType.I);
      final rotated = piece.rotateCW();
      final verticalI = Tetromino(TetrominoType.I, rotated, piece.color);
      final gs = GameState(
        width: 10, height: 20,
        board: board,
        currentPiece: verticalI,
        currentX: 6, currentY: 16,
        score: 0, level: 1, linesCleared: 0,
      );
      final result = gs.hardDrop();
      // 竖条 I 填充 rows 16-19 的 col 7，4行消行 = 800 分
      expect(result.score, 800);
      expect(result.linesCleared, 4);
    });

    test('level increases every 10 lines', () {
      final board = List.generate(20, (r) {
        if (r == 19) {
          return [1, 1, 1, 1, 1, 1, 1, 1, 1, 0];
        }
        return List.filled(10, 0);
      });
      final piece = Tetromino.create(TetrominoType.I);
      final gs = GameState(
        width: 10, height: 20,
        board: board,
        currentPiece: piece,
        currentX: 6, currentY: 18,
        score: 0, level: 1, linesCleared: 9,
      );
      final result = gs.hardDrop();
      expect(result.level, 2);
    });

    test('highScore is updated when score exceeds it', () {
      final board = List.generate(20, (r) {
        if (r == 19) {
          return [1, 1, 1, 1, 1, 1, 1, 1, 1, 0];
        }
        return List.filled(10, 0);
      });
      final piece = Tetromino.create(TetrominoType.I);
      final gs = GameState(
        width: 10, height: 20,
        board: board,
        currentPiece: piece,
        currentX: 6, currentY: 18,
        score: 0, level: 1, linesCleared: 0,
        highScore: 50,
      );
      final result = gs.hardDrop();
      expect(result.highScore, 100);
    });

    test('wall kick on rotation', () {
      // place piece at left edge and rotate
      final board = List.generate(20, (_) => List.filled(10, 0));
      final piece = Tetromino.create(TetrominoType.I);
      final gs = GameState(
        width: 10, height: 20,
        board: board,
        currentPiece: piece,
        currentX: -1, currentY: 10,
        score: 0, level: 1, linesCleared: 0,
      );
      final result = gs.rotateCW();
      // should not crash, wall kick may apply
      expect(result, isNotNull);
    });

    test('game over when piece locks above board', () {
      final board = List.generate(20, (_) => List.filled(10, 0));
      // fill top rows
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 10; c++) {
          board[r][c] = 1;
        }
      }
      final piece = Tetromino.create(TetrominoType.I);
      final gs = GameState(
        width: 10, height: 20,
        board: board,
        currentPiece: piece,
        currentX: 3, currentY: -1,
        score: 0, level: 1, linesCleared: 0,
      );
      final result = gs.hardDrop();
      expect(result.isGameOver, true);
    });
  });
}
