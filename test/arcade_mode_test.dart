import 'package:flutter_tetris/game/game_mode.dart';
import 'package:flutter_tetris/game/match_rules.dart';
import 'package:flutter_tetris/game/scoreboard.dart';
import 'package:flutter_tetris/game/scoring.dart';
import 'package:flutter_tetris/game/tetris_controller.dart';
import 'package:flutter_tetris/game/tetromino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('街机规则', () {
    test('关闭暂存、幽灵与锁定重置，只保留一块预览', () {
      const rules = MatchRules(mode: GameMode.arcade);
      expect(rules.title, '街机模式');
      expect(rules.targetLines, isNull);
      expect(rules.timeLimit, isNull);
      expect(rules.holdEnabled, isFalse);
      expect(rules.ghostEnabled, isFalse);
      expect(rules.lockResetEnabled, isFalse);
      expect(rules.previewCount, 1);
      expect(rules.lockDelay, const Duration(milliseconds: 120));
    });

    test('经典计分按等级放大，最高 19 级', () {
      expect(arcadeClearScore(lines: 1, level: 1), 40);
      expect(arcadeClearScore(lines: 2, level: 2), 200);
      expect(arcadeClearScore(lines: 4, level: 5), 6000);
      expect(arcadeClearScore(lines: 0, level: 5), 0);
      expect(arcadeClearScore(lines: 5, level: 5), 0);
      expect(arcadeLevelForLines(0), 1);
      expect(arcadeLevelForLines(10), 2);
      expect(arcadeLevelForLines(500), kArcadeMaxLevel);
    });

    test('帧表重力从 800ms 收敛到 50ms', () {
      expect(arcadeGravityForLevel(1), const Duration(milliseconds: 800));
      expect(arcadeGravityForLevel(10), const Duration(milliseconds: 100));
      expect(arcadeGravityForLevel(19), const Duration(milliseconds: 50));
      expect(arcadeGravityForLevel(99), const Duration(milliseconds: 50));
    });

    test('标准玩法仍按 Guideline 规则运行', () {
      const rules = MatchRules(mode: GameMode.endless);
      expect(rules.holdEnabled, isTrue);
      expect(rules.ghostEnabled, isTrue);
      expect(rules.previewCount, 5);
      expect(rules.gravityFor(1), gravityForLevel(1));
    });
  });

  group('街机对局', () {
    test('只给一块预览且暂存无效', () {
      final controller = TetrisController(
        mode: GameMode.arcade,
        seed: 7,
        autoTick: false,
      );
      addTearDown(controller.dispose);
      controller.start();

      final first = controller.piece!.type;
      expect(controller.nextQueue, hasLength(1));
      expect(controller.canHold, isFalse);
      controller.hold();
      expect(controller.piece!.type, first);
      expect(controller.holdType, isNull);
    });

    test('街机计分不含连击、T-Spin 与全消奖励', () {
      final board = ScoreBoard(arcade: true);
      ClearOutcome clear(int rows) => board.registerClear(
        rows: rows,
        tSpin: true,
        mini: false,
        perfectClear: true,
      );

      expect(clear(1).score, 40);
      expect(clear(1).score, 40);
      expect(board.tSpins, 0);
      expect(board.combo, 2);
    });

    test('四行 1200 分，每 10 行升级且封顶 19 级', () {
      final board = ScoreBoard(arcade: true);
      ClearOutcome clear(int rows) => board.registerClear(
        rows: rows,
        tSpin: false,
        mini: false,
        perfectClear: false,
      );

      expect(clear(4).score, 1200);
      expect(clear(4).score, 1200);
      expect(clear(2).score, 100);
      expect(board.level, 2);
      expect(board.score, 2500);

      board.setLinesForTest(500);
      expect(board.level, kArcadeMaxLevel);
    });

    test('贴地后不再重置锁定计时，120ms 内落定', () {
      final controller = TetrisController(
        mode: GameMode.arcade,
        seed: 3,
        autoTick: false,
      );
      addTearDown(controller.dispose);
      controller.start();
      controller.setPieceForTest(
        const ActivePiece(type: TetrominoType.o, x: 4, y: 19),
      );

      controller.tick(const Duration(milliseconds: 100));
      expect(controller.moveLeft(), isTrue);
      controller.tick(const Duration(milliseconds: 30));
      expect(controller.lockSequence, 1);
      expect(controller.board.filledCount, 4);
    });

    test('标准模式贴地移动仍会重置锁定计时', () {
      final controller = TetrisController(
        mode: GameMode.endless,
        seed: 3,
        autoTick: false,
      );
      addTearDown(controller.dispose);
      controller.start();
      controller.setPieceForTest(
        const ActivePiece(type: TetrominoType.o, x: 4, y: 19),
      );

      controller.tick(const Duration(milliseconds: 400));
      expect(controller.moveLeft(), isTrue);
      controller.tick(const Duration(milliseconds: 200));
      expect(controller.lockSequence, 0);
      expect(controller.piece, isNotNull);
    });
  });
}
