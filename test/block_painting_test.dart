import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_tetris/game/tetromino.dart';
import 'package:flutter_tetris/theme/block_painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(resetBlockPaintCacheForTest);

  Canvas recorder() => Canvas(ui.PictureRecorder());

  test('同色同尺寸的方块笔触复用画笔', () {
    final canvas = recorder();
    const color = Color(0xFF4285F4);

    paintBlock(canvas, const Rect.fromLTWH(0, 0, 30, 30), color);
    final builds = debugBlockPaintBuilds;
    expect(builds, 3, reason: '渐变填充、高光与描边各一支');

    paintBlock(canvas, const Rect.fromLTWH(120, 60, 30, 30), color);
    expect(debugBlockPaintBuilds, builds, reason: '平移不改尺寸，画笔可复用');

    paintBlock(canvas, const Rect.fromLTWH(0, 0, 40, 40), color);
    expect(debugBlockPaintBuilds, builds + 1, reason: '尺寸变化只需重建渐变');

    paintBlock(
      canvas,
      const Rect.fromLTWH(0, 0, 30, 30),
      color,
      opacity: 0.5,
    );
    expect(debugBlockPaintBuilds, builds + 4, reason: '半透明另算一套画笔');
  });

  test('幽灵块画笔同样按键复用', () {
    final canvas = recorder();
    const color = Color(0xFF34A853);

    paintGhostBlock(canvas, const Rect.fromLTWH(0, 0, 24, 24), color);
    final builds = debugBlockPaintBuilds;
    expect(builds, 2, reason: '淡填充与描边各一支');

    paintGhostBlock(canvas, const Rect.fromLTWH(48, 0, 24, 24), color);
    paintGhostBlock(canvas, const Rect.fromLTWH(0, 24, 24, 24), color);
    expect(debugBlockPaintBuilds, builds);
  });

  test('预览绘制按包围盒居中且不新建画笔', () {
    final canvas = recorder();
    const blocks = [Block(0, 0), Block(1, 0)];
    const color = Color(0xFFFBBC05);

    paintMiniPiece(canvas, const Size(44, 44), blocks, color);
    final builds = debugBlockPaintBuilds;
    paintMiniPiece(canvas, const Size(44, 44), blocks, color);
    expect(debugBlockPaintBuilds, builds);
  });
}
