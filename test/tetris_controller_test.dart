import 'package:flutter_tetris/game/game_mode.dart';
import 'package:flutter_tetris/game/garbage.dart';
import 'package:flutter_tetris/game/level.dart';
import 'package:flutter_tetris/game/tetromino.dart';
import 'package:flutter_tetris/game/tetris_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  group('对局控制器', () {
    late TetrisController controller;

    setUp(() {
      controller = TetrisController(
        mode: GameMode.endless,
        seed: 2026,
        autoTick: false,
      );
      controller.start();
    });

    tearDown(() => controller.dispose());

    test('开局生成方块并准备五个预览', () {
      expect(controller.status, GameStatus.playing);
      expect(controller.piece, isNotNull);
      expect(controller.piece!.x, kSpawnColumn);
      expect(controller.piece!.y, 0);
      expect(controller.nextQueue.length, 5);
      expect(controller.score, 0);
      expect(controller.lines, 0);
      expect(controller.level, 1);
    });

    test('固定种子让方块序列在重开后复现', () {
      List<TetrominoType> sequence() => [
        controller.piece!.type,
        ...controller.nextQueue.take(3),
      ];
      final first = sequence();
      controller.restart();
      expect(sequence(), first);
    });

    test('左右移动受墙限制', () {
      controller.setPieceForTest(
        const ActivePiece(type: TetrominoType.t, x: 0, y: 10),
      );
      expect(controller.moveLeft(), isFalse);
      expect(controller.piece!.x, 0);
      expect(controller.moveRight(), isTrue);
      expect(controller.moveRight(), isTrue);
      expect(controller.piece!.x, 2);
      while (controller.moveRight()) {}
      expect(controller.piece!.x <= 8, isTrue);
    });

    test('旋转成功并保持位置', () {
      expect(controller.rotateClockwise(), isTrue);
      expect(controller.piece!.rotation, 1);
      expect(controller.rotateCounterClockwise(), isTrue);
      expect(controller.piece!.rotation, 0);
    });

    test('幽灵方块位于直落终点', () {
      final ghost = controller.ghostPiece!;
      expect(ghost.type, controller.piece!.type);
      expect(ghost.y, greaterThan(controller.piece!.y));
      expect(controller.board.fits(ghost.blocks), isTrue);
      expect(
        controller.board.fits(ghost.copyWith(y: ghost.y + 1).blocks),
        isFalse,
      );
    });

    test('软降每格加一分', () {
      final startY = controller.piece!.y;
      controller.softDrop();
      expect(controller.piece!.y, startY + 1);
      expect(controller.score, 1);
    });

    test('硬降立即落定并按格数计分', () {
      final piece = controller.piece!;
      final ghost = controller.ghostPiece!;
      final distance = ghost.y - piece.y;
      controller.hardDrop();
      expect(controller.score, distance * 2);
      expect(controller.pieces, 1);
      expect(controller.piece!.y, 0);
    });

    test('每次落定前只能暂存一次', () {
      final first = controller.piece!.type;
      controller.hold();
      expect(controller.holdType, first);
      expect(controller.canHold, isFalse);
      controller.hold();
      expect(controller.holdType, first);
      controller.hardDrop();
      expect(controller.canHold, isTrue);
      final current = controller.piece!.type;
      controller.hold();
      expect(controller.holdType, current);
      expect(controller.piece!.type, first);
    });

    test('贴地后锁定延迟到期才落定', () {
      controller.setPieceForTest(
        const ActivePiece(type: TetrominoType.o, x: 3, y: 19),
      );
      advance(controller, 400);
      expect(controller.pieces, 0);
      expect(controller.piece, isNotNull);
      advance(controller, 150);
      expect(controller.pieces, 1);
      expect(controller.piece!.y, 0);
    });

    test('消行得分、连击与消行动画', () {
      // 留一格残块，避免顺带触发全消奖励。
      controller.board.setCell(0, 18, TetrominoType.j);
      for (var x = 4; x < 10; x++) {
        controller.board.setCell(x, 20, TetrominoType.z);
      }
      controller.setPieceForTest(
        const ActivePiece(type: TetrominoType.i, x: 0, y: 19),
      );
      controller.hardDrop();
      expect(controller.lines, 1);
      expect(controller.clearingRows, [20]);
      expect(controller.score, 100);
      expect(controller.drainEvents(), contains(GameEvent.lineClear));

      advance(controller, 300);
      expect(controller.board.filledCount, 1);
      expect(controller.clearingRows, isEmpty);
      expect(controller.piece, isNotNull);
      expect(controller.combo, 1);

      // 第二次连续消行触发连击加分。
      for (var x = 4; x < 10; x++) {
        controller.board.setCell(x, 20, TetrominoType.z);
      }
      controller.setPieceForTest(
        const ActivePiece(type: TetrominoType.i, x: 0, y: 19),
      );
      controller.hardDrop();
      expect(controller.score, 100 + 100 + 50);
      expect(controller.combo, 2);
    });

    test('一次消四行并全消获得奖励', () {
      for (var y = 17; y < 21; y++) {
        for (var x = 1; x < 10; x++) {
          controller.board.setCell(x, y, TetrominoType.l);
        }
      }
      controller.setPieceForTest(
        const ActivePiece(type: TetrominoType.i, x: -2, y: 17, rotation: 1),
      );
      controller.hardDrop();
      expect(controller.lines, 4);
      expect(controller.score, 2800);
      expect(
        controller.drainEvents(),
        containsAll([GameEvent.tetris, GameEvent.perfectClear]),
      );
      advance(controller, 300);
      expect(controller.board.isEmpty, isTrue);
    });

    test('每十行升级并发出升级事件', () {
      controller.debugSetStats(lines: 9);
      for (var x = 4; x < 10; x++) {
        controller.board.setCell(x, 20, TetrominoType.s);
      }
      controller.setPieceForTest(
        const ActivePiece(type: TetrominoType.i, x: 0, y: 19),
      );
      controller.hardDrop();
      expect(controller.lines, 10);
      expect(controller.level, 2);
      expect(controller.drainEvents(), contains(GameEvent.levelUp));
    });

    test('零消 T-Spin 仍然计分，且不增加连击', () {
      for (final point in const [(3, 4), (5, 4), (3, 6), (5, 6)]) {
        controller.board.setCell(point.$1, point.$2, TetrominoType.z);
      }
      controller.setPieceForTest(
        const ActivePiece(type: TetrominoType.t, x: 3, y: 4),
      );
      expect(controller.rotateClockwise(), isTrue);
      expect(controller.piece!.rotation, 1);
      controller.lockNowForTest();
      expect(controller.lines, 0);
      expect(controller.score, 400);
      expect(controller.combo, 0);
    });

    test('零消 T-Spin Mini 按 Mini 计分', () {
      for (final point in const [(3, 4), (5, 4), (3, 6)]) {
        controller.board.setCell(point.$1, point.$2, TetrominoType.z);
      }
      controller.setPieceForTest(
        const ActivePiece(type: TetrominoType.t, x: 3, y: 4),
      );
      expect(controller.rotateClockwise(), isTrue);
      controller.lockNowForTest();
      expect(controller.score, 100);
    });

    test('方块完全锁在顶部时结束对局', () {
      controller.setPieceForTest(
        const ActivePiece(type: TetrominoType.o, x: 3, y: -2),
      );
      controller.lockNowForTest();
      expect(controller.status, GameStatus.over);
      expect(controller.result, isNotNull);
      expect(controller.result!.reason, contains('顶部'));
      expect(controller.result!.won, isFalse);
    });

    test('暂停期间不计时也不下落', () {
      controller.pause();
      advance(controller, 1000);
      expect(controller.elapsed, Duration.zero);
      expect(controller.piece!.y, 0);
      expect(controller.status, GameStatus.paused);

      controller.resume();
      advance(controller, 100);
      expect(controller.elapsed.inMilliseconds, 100);
      expect(controller.isPlaying, isTrue);
    });
  });

  group('模式目标', () {
    test('40 行竞速完成目标即获胜并记录完成时间', () {
      final controller = TetrisController(
        mode: GameMode.sprint,
        seed: 11,
        autoTick: false,
      );
      addTearDown(controller.dispose);
      controller.start();
      controller.debugSetStats(lines: 39);
      for (var x = 4; x < 10; x++) {
        controller.board.setCell(x, 20, TetrominoType.j);
      }
      controller.setPieceForTest(
        const ActivePiece(type: TetrominoType.i, x: 0, y: 19),
      );
      controller.hardDrop();
      advance(controller, 300);
      expect(controller.status, GameStatus.over);
      expect(controller.result!.won, isTrue);
      expect(controller.result!.reason, contains('40 行'));
      expect(controller.result!.elapsed.inMilliseconds <= 340, isTrue);
    });

    test('2 分钟计时到点结束', () {
      final controller = TetrisController(
        mode: GameMode.ultra,
        seed: 12,
        autoTick: false,
      );
      addTearDown(controller.dispose);
      controller.start();
      controller.debugSetStats(elapsed: const Duration(milliseconds: 119900));
      advance(controller, 200);
      expect(controller.status, GameStatus.over);
      expect(controller.result!.reason, '时间到');
      expect(controller.result!.elapsed, const Duration(seconds: 120));
      expect(controller.mode.timeLimit, const Duration(seconds: 120));
    });
  });

  group('关卡模式', () {
    test('开局载入地形、起始等级与限时', () {
      const level = LevelDefinition(
        id: 90,
        name: '地形测试',
        brief: '',
        targetLines: 2,
        timeLimit: Duration(seconds: 60),
        terrain: ['###.######'],
        startLevel: 4,
        seed: 7,
      );
      final controller = TetrisController(
        mode: GameMode.level,
        level: level,
        autoTick: false,
      );
      addTearDown(controller.dispose);
      controller.start();

      expect(controller.levelDef, same(level));
      expect(controller.board.filledCount, 9);
      expect(controller.board.isGarbage(0, 20), isTrue);
      expect(controller.level, 4);
      expect(controller.targetLines, 2);
      expect(controller.remaining, const Duration(seconds: 60));
      expect(controller.garbageInterval, isNull);
    });

    test('完成目标行数即通关并按剩余时间评星', () {
      const level = LevelDefinition(
        id: 91,
        name: '一行政略',
        brief: '',
        targetLines: 1,
        timeLimit: Duration(seconds: 30),
        terrain: [],
        seed: 8,
      );
      final controller = TetrisController(
        mode: GameMode.level,
        level: level,
        autoTick: false,
      );
      addTearDown(controller.dispose);
      controller.start();
      for (var x = 4; x < 10; x++) {
        controller.board.setCell(x, 20, TetrominoType.z);
      }
      controller.setPieceForTest(
        const ActivePiece(type: TetrominoType.i, x: 0, y: 19),
      );
      controller.hardDrop();
      advance(controller, 300);

      final result = controller.result!;
      expect(controller.status, GameStatus.over);
      expect(result.won, isTrue);
      expect(result.levelId, 91);
      expect(result.stars, 3);
      expect(result.reason, '完成 1 行');
    });

    test('关卡限时到点结束', () {
      const level = LevelDefinition(
        id: 92,
        name: '限时测试',
        brief: '',
        targetLines: 99,
        timeLimit: Duration(seconds: 2),
        terrain: [],
        seed: 9,
      );
      final controller = TetrisController(
        mode: GameMode.level,
        level: level,
        autoTick: false,
      );
      addTearDown(controller.dispose);
      controller.start();
      advance(controller, 2100);

      expect(controller.status, GameStatus.over);
      expect(controller.result!.reason, '时间到');
      expect(controller.result!.won, isFalse);
      expect(controller.result!.levelId, 92);
    });

    test('垃圾行按间隔上涌并抬起当前方块', () {
      const level = LevelDefinition(
        id: 93,
        name: '上涌测试',
        brief: '',
        targetLines: 99,
        timeLimit: Duration(seconds: 60),
        terrain: [],
        garbage: GarbageRule(interval: Duration(seconds: 1)),
        seed: 10,
      );
      final controller = TetrisController(
        mode: GameMode.level,
        level: level,
        autoTick: false,
      );
      addTearDown(controller.dispose);
      controller.start();
      advance(controller, 1100);

      expect(controller.garbageRises, 1);
      expect(controller.board.filledCount, 9);
      expect(controller.garbageSecondsLeft, isNotNull);
      expect(controller.status, GameStatus.playing);
    });
  });
}
