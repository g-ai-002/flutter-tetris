import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_tetris/game/tetromino.dart';
import 'package:flutter_tetris/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('主题与配色', () {
    test('浅色与深色主题各自成立', () {
      final light = buildLightTheme(fontFamily: 'Microsoft YaHei UI');
      final dark = buildDarkTheme();
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.scaffoldBackgroundColor, const Color(0xFFF6EFE1));
      expect(dark.scaffoldBackgroundColor, const Color(0xFF17140F));
      expect(light.colorScheme.primary, appRed);
    });

    test('七种方块都有可辨识的颜色', () {
      const light = BlockPalette.light;
      const dark = BlockPalette.darkPalette;
      final lightColors = <Color>{};
      final darkColors = <Color>{};
      for (final type in TetrominoType.values) {
        final lightColor = light.colorOf(type);
        final darkColor = dark.colorOf(type);
        expect(lightColor.a, 1);
        expect(darkColor.a, 1);
        expect(lightColor, isNot(darkColor));
        lightColors.add(lightColor);
        darkColors.add(darkColor);
      }
      expect(lightColors.length, 7);
      expect(darkColors.length, 7);
      expect(light.legend.length, 7);
      expect(light.boardBackground, isNot(dark.boardBackground));
    });

    test('方块绘制与预览不抛异常', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const palette = BlockPalette.light;
      const rect = Rect.fromLTWH(0, 0, 32, 32);
      paintBlock(canvas, rect, palette.colorOf(TetrominoType.t));
      paintBlock(canvas, rect, palette.colorOf(TetrominoType.i), active: true);
      paintGhostBlock(canvas, rect, palette.colorOf(TetrominoType.o));
      paintMiniPiece(
        canvas,
        const Size(60, 60),
        kTetrominoShapes[TetrominoType.l]![0],
        palette.colorOf(TetrominoType.l),
      );
      expect(recorder.endRecording().toImageSync(120, 120), isNotNull);
    });
  });
}
