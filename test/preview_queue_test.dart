import 'package:flutter_tetris/game/game_mode.dart';
import 'package:flutter_tetris/game/tetromino.dart';
import 'package:flutter_tetris/game/tetris_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('预览队列', () {
    late TetrisController controller;

    setUp(() {
      controller = TetrisController(
        mode: GameMode.endless,
        seed: 20261107,
        autoTick: false,
      );
      controller.start();
    });

    tearDown(() => controller.dispose());

    test('重复读取预览不改变顺序', () {
      final first = controller.nextQueue;
      final second = controller.nextQueue;
      expect(second, first);
      expect(first.length, 5);
    });

    test('落定后出场的方块与预览首位一致，队列整体前移', () {
      final preview = controller.nextQueue;
      controller.hardDrop();

      expect(controller.piece!.type, preview.first);
      expect(controller.nextQueue.take(4).toList(), preview.skip(1).toList());
    });

    test('连续落定十个方块始终按预览顺序出场', () {
      final expected = <TetrominoType>[controller.piece!.type];
      while (expected.length < 10) {
        controller.hardDrop();
        expected.add(controller.piece!.type);
      }

      controller.restart();
      for (final type in expected) {
        expect(controller.piece!.type, type);
        controller.hardDrop();
      }
    });
  });
}
