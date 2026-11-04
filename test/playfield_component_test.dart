import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tetris/flame/playfield_component.dart';
import 'package:flutter_tetris/game/game_mode.dart';
import 'package:flutter_tetris/game/tetromino.dart';
import 'package:flutter_tetris/game/tetris_controller.dart';
import 'package:flutter_tetris/theme/block_palette.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('场地组件可以绘制方块、幽灵块与消行特效', () {
    final controller = TetrisController(
      mode: GameMode.endless,
      seed: 21,
      autoTick: false,
    );
    addTearDown(controller.dispose);
    controller.start();
    final style = ValueNotifier(
      const PlayfieldStyle(palette: BlockPalette.light),
    );
    addTearDown(style.dispose);
    final component = PlayfieldComponent(controller: controller, style: style)
      ..size = Vector2(300, 600);

    final first = ui.PictureRecorder();
    component.render(Canvas(first));
    expect(first.endRecording(), isNotNull);

    for (var x = 4; x < 10; x++) {
      controller.board.setCell(x, 20, TetrominoType.t);
    }
    controller.setPieceForTest(
      const ActivePiece(type: TetrominoType.i, x: 0, y: 19),
    );
    controller.hardDrop();
    expect(controller.isClearing, isTrue);
    component.update(0.016);

    final second = ui.PictureRecorder();
    component.render(Canvas(second));
    expect(second.endRecording(), isNotNull);

    style.value = const PlayfieldStyle(
      palette: BlockPalette.darkPalette,
      showGhost: false,
      showGrid: false,
    );
    final third = ui.PictureRecorder();
    component.render(Canvas(third));
    expect(third.endRecording(), isNotNull);
  });
}
