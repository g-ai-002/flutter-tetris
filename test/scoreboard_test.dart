import 'package:flutter_tetris/game/scoreboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('对局计分板', () {
    test('初始状态与落定格数计分', () {
      final board = ScoreBoard();
      expect(board.score, 0);
      expect(board.lines, 0);
      expect(board.level, 1);
      expect(board.combo, 0);
      expect(board.pieces, 0);
      expect(board.backToBack, isFalse);

      board.addDropScore(3, pointsPerCell: 1);
      board.addDropScore(5, pointsPerCell: 2);
      board.countPiece();
      expect(board.score, 13);
      expect(board.pieces, 1);
    });

    test('普通消行按等级计分并累计连击', () {
      final board = ScoreBoard();
      final first = board.registerClear(
        rows: 1,
        tSpin: false,
        mini: false,
        perfectClear: false,
      );
      expect(first.rows, 1);
      expect(first.score, 100);
      expect(first.levelUp, isFalse);
      expect(board.combo, 1);

      final second = board.registerClear(
        rows: 1,
        tSpin: false,
        mini: false,
        perfectClear: false,
      );
      expect(second.score, 150);
      expect(board.score, 250);
      expect(board.combo, 2);
      expect(board.maxCombo, 2);
      expect(board.lines, 2);
    });

    test('四行连续奖励与全消奖励', () {
      final board = ScoreBoard();
      final first = board.registerClear(
        rows: 4,
        tSpin: false,
        mini: false,
        perfectClear: false,
      );
      expect(first.score, 800);
      expect(board.backToBack, isTrue);

      final second = board.registerClear(
        rows: 4,
        tSpin: false,
        mini: false,
        perfectClear: false,
      );
      expect(second.score, 1200 + 50);
      expect(board.backToBack, isTrue);

      final perfect = board.registerClear(
        rows: 2,
        tSpin: false,
        mini: false,
        perfectClear: true,
      );
      expect(perfect.score, 300 + 1200 + 100);
    });

    test('零消 T-Spin 计分但重置连击并保留连续奖励', () {
      final board = ScoreBoard();
      board.registerClear(
        rows: 4,
        tSpin: false,
        mini: false,
        perfectClear: false,
      );
      board.registerClear(
        rows: 1,
        tSpin: false,
        mini: false,
        perfectClear: false,
      );
      expect(board.combo, 2);
      expect(board.backToBack, isFalse);

      final zero = board.registerClear(
        rows: 0,
        tSpin: true,
        mini: false,
        perfectClear: false,
      );
      expect(zero.score, 400);
      expect(board.combo, 0);

      board.registerClear(
        rows: 4,
        tSpin: false,
        mini: false,
        perfectClear: false,
      );
      expect(board.backToBack, isTrue);
      final mini = board.registerClear(
        rows: 0,
        tSpin: true,
        mini: true,
        perfectClear: false,
      );
      expect(mini.score, 100);
      expect(board.backToBack, isTrue);
    });

    test('每十行升级并支持关卡起始等级', () {
      final board = ScoreBoard(startLevel: 4);
      expect(board.level, 4);
      final first = board.registerClear(
        rows: 4,
        tSpin: false,
        mini: false,
        perfectClear: false,
      );
      expect(first.levelUp, isFalse);
      expect(board.level, 4);

      board.setLinesForTest(9);
      final up = board.registerClear(
        rows: 1,
        tSpin: false,
        mini: false,
        perfectClear: false,
      );
      expect(up.levelUp, isTrue);
      expect(board.level, 5);
      expect(board.lines, 10);
    });

    test('记录四行、T-Spin 与全消次数', () {
      final board = ScoreBoard();
      board.registerClear(
        rows: 4,
        tSpin: false,
        mini: false,
        perfectClear: true,
      );
      board.registerClear(
        rows: 2,
        tSpin: true,
        mini: false,
        perfectClear: false,
      );
      board.registerClear(
        rows: 1,
        tSpin: false,
        mini: false,
        perfectClear: false,
      );
      board.registerClear(
        rows: 0,
        tSpin: true,
        mini: false,
        perfectClear: false,
      );

      expect(board.tetrises, 1);
      expect(board.tSpins, 1);
      expect(board.perfectClears, 1);

      board.reset(startLevel: 1);
      expect(board.tetrises, 0);
      expect(board.tSpins, 0);
      expect(board.perfectClears, 0);
    });

    test('重开重置全部累计状态', () {
      final board = ScoreBoard();
      board.addDropScore(2, pointsPerCell: 2);
      board.countPiece();
      board.registerClear(
        rows: 4,
        tSpin: false,
        mini: false,
        perfectClear: true,
      );

      board.reset(startLevel: 3);
      expect(board.score, 0);
      expect(board.lines, 0);
      expect(board.level, 3);
      expect(board.combo, 0);
      expect(board.maxCombo, 0);
      expect(board.pieces, 0);
      expect(board.tetrises, 0);
      expect(board.tSpins, 0);
      expect(board.perfectClears, 0);
      expect(board.backToBack, isFalse);
    });
  });
}
