import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_tetris/flame/board_effects.dart';
import 'package:flutter_tetris/game/board.dart';
import 'package:flutter_tetris/game/tetromino.dart';
import 'package:flutter_tetris/theme/block_palette.dart';
import 'package:flutter_test/flutter_test.dart';

Board filledBoard({int rows = 1}) {
  final board = Board();
  for (var y = board.rows - rows; y < board.rows; y++) {
    for (var x = 0; x < board.columns; x++) {
      board.setCell(x, y, TetrominoType.t);
    }
  }
  return board;
}

void main() {
  test('消行碎屑按格子生成，四行消除加强震屏并随时间清空', () {
    final effects = BoardEffects(random: math.Random(1));
    final board = filledBoard(rows: 4);

    effects.spawnClearBurst(
      board: board,
      rows: [18, 19, 20],
      palette: BlockPalette.light,
      cellSize: 30,
    );
    expect(effects.particleCount, 30);
    expect(effects.shake, 3.5);

    effects.spawnClearBurst(
      board: board,
      rows: [17, 18, 19, 20],
      palette: BlockPalette.light,
      cellSize: 30,
    );
    expect(effects.shake, 7);

    effects.update(2);
    expect(effects.particleCount, 0);
    expect(effects.shake, 0);
  });

  test('粒子总量不超过上限', () {
    final effects = BoardEffects(random: math.Random(2));
    final board = filledBoard();
    for (var i = 0; i < 40; i++) {
      effects.spawnClearBurst(
        board: board,
        rows: [board.rows - 1],
        palette: BlockPalette.light,
        cellSize: 30,
      );
    }
    expect(effects.particleCount, BoardEffects.maxParticles);
  });

  test('落定微尘与硬降拖影各自生成并淡出', () {
    final effects = BoardEffects(random: math.Random(3));
    final board = Board();

    effects.spawnLockDust(
      blocks: const [Block(4, 18), Block(5, 18), Block(4, 19), Block(5, 19)],
      type: TetrominoType.o,
      palette: BlockPalette.light,
      cellSize: 30,
      hiddenRows: board.hiddenRows,
    );
    expect(effects.particleCount, inInclusiveRange(0, 4));

    effects.spawnDropTrail(
      board: board,
      column: 4,
      rows: 6,
      blocks: const [Block(4, 18)],
      cellSize: 30,
    );
    expect(effects.trailCount, 1);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    effects.paintTrails(canvas, hiddenRows: board.hiddenRows, cellSize: 30);
    effects.paintParticles(canvas);
    expect(recorder.endRecording(), isNotNull);

    effects.update(0.3);
    expect(effects.trailCount, 0);
  });

  test('没有拖影高度时不生成特效', () {
    final effects = BoardEffects(random: math.Random(4));
    effects.spawnDropTrail(board: Board(), column: 0, rows: 0, blocks: const [], cellSize: 30);
    expect(effects.trailCount, 0);
  });
}
