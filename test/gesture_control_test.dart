import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris/game/tetris_input.dart';

void main() {
  group('TetrisInput.directionFromDelta', () {
    test('按主分量判定方向', () {
      expect(
        TetrisInput.directionFromDelta(const Offset(20, 0)),
        SwipeDirection.right,
      );
      expect(
        TetrisInput.directionFromDelta(const Offset(-20, 0)),
        SwipeDirection.left,
      );
      expect(
        TetrisInput.directionFromDelta(const Offset(0, 20)),
        SwipeDirection.down,
      );
      expect(
        TetrisInput.directionFromDelta(const Offset(0, -20)),
        SwipeDirection.up,
      );
      expect(
        TetrisInput.directionFromDelta(const Offset(8, 30)),
        SwipeDirection.down,
      );
      expect(
        TetrisInput.directionFromDelta(const Offset(30, 8)),
        SwipeDirection.right,
      );
    });
  });

  group('TetrisInput.actionFromDelta', () {
    test('按主分量映射到游戏动作', () {
      expect(
        TetrisInput.actionFromDelta(const Offset(-20, 0)),
        SwipeAction.moveLeft,
      );
      expect(
        TetrisInput.actionFromDelta(const Offset(20, 0)),
        SwipeAction.moveRight,
      );
      expect(
        TetrisInput.actionFromDelta(const Offset(0, 20)),
        SwipeAction.hardDrop,
      );
      expect(
        TetrisInput.actionFromDelta(const Offset(0, -20)),
        SwipeAction.rotate,
      );
      expect(
        TetrisInput.actionFromDelta(const Offset(30, 8)),
        SwipeAction.moveRight,
      );
    });

    test('位移不足阈值时不产生动作', () {
      expect(TetrisInput.actionFromDelta(Offset.zero), isNull);
      expect(TetrisInput.actionFromDelta(const Offset(6, 0)), isNull);
      expect(TetrisInput.actionFromDelta(const Offset(0, -11)), isNull);
    });
  });
}
