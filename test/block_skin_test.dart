import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris/flame/playfield_component.dart';
import 'package:flutter_tetris/game/tetromino.dart';
import 'package:flutter_tetris/providers/settings_provider.dart';
import 'package:flutter_tetris/theme/app_theme.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('棋盘皮肤', () {
    test('每套皮肤在浅色与深色下都有七种可辨识方块色', () {
      for (final skin in BlockSkin.values) {
        for (final dark in [false, true]) {
          final palette = skin.palette(dark: dark);
          final colors = <Color>{};
          for (final type in TetrominoType.values) {
            final color = palette.colorOf(type);
            expect(color.a, 1, reason: '${skin.name}-$dark-${type.name}');
            colors.add(color);
          }
          expect(colors.length, TetrominoType.values.length);
          expect(palette.legend.length, TetrominoType.values.length);
          expect(palette.boardTop, isNot(palette.boardBottom));
          expect(palette.screenGradient.colors, [palette.screenTop, palette.screenBottom]);
          expect(palette.boardGradient.colors, [palette.boardTop, palette.boardBottom]);
        }
      }
    });

    test('四套皮肤拥有各自的强调色与棋盘底色', () {
      for (final dark in [false, true]) {
        final accents = <Color>{};
        final boards = <Color>{};
        for (final skin in BlockSkin.values) {
          final palette = skin.palette(dark: dark);
          accents.add(palette.accent);
          boards.add(palette.boardTop);
          expect(palette.primaryContainer, isNot(palette.surface));
          expect(palette.onAccent, isNot(palette.accent));
        }
        expect(accents.length, BlockSkin.values.length);
        expect(boards.length, BlockSkin.values.length);
      }
    });

    test('默认皮肤为宣纸，未知名称回退到宣纸', () {
      expect(BlockSkin.fromName(null), BlockSkin.paper);
      expect(BlockSkin.fromName('unknown'), BlockSkin.paper);
      expect(BlockSkin.fromName('celadon'), BlockSkin.celadon);
      expect(BlockPalette.light.skin, BlockSkin.paper);
      expect(BlockPalette.darkPalette.skin, BlockSkin.paper);
    });

    test('Material 主题强调色跟随皮肤', () {
      for (final skin in BlockSkin.values) {
        final lightPalette = skin.palette(dark: false);
        final darkPalette = skin.palette(dark: true);
        final light = buildLightTheme(skin: skin);
        final dark = buildDarkTheme(skin: skin);
        expect(light.colorScheme.primary, lightPalette.accent);
        expect(dark.colorScheme.primary, darkPalette.accent);
        expect(light.scaffoldBackgroundColor, lightPalette.backdrop);
        expect(dark.scaffoldBackgroundColor, darkPalette.backdrop);
        expect(light.colorScheme.surface, lightPalette.surface);
        expect(dark.colorScheme.onSurface, darkPalette.onSurface);
      }
    });

    test('切换皮肤会触发场地样式更新', () {
      const paper = PlayfieldStyle(palette: BlockPalette.light);
      final celadon = PlayfieldStyle(palette: BlockSkin.celadon.palette(dark: false));
      expect(paper, isNot(celadon));
      expect(paper, isNot(const PlayfieldStyle(palette: BlockPalette.darkPalette)));
    });
  });

  group('皮肤偏好', () {
    test('默认宣纸，写入后可读回', () async {
      final storage = await prepareStorage();
      expect(storage.blockSkin, BlockSkin.paper);
      await storage.setBlockSkin(BlockSkin.dunhuang);
      expect(storage.blockSkin, BlockSkin.dunhuang);
      await storage.setBlockSkin(BlockSkin.ink);
      expect(storage.blockSkin, BlockSkin.ink);
    });

    test('设置 Provider 切换皮肤并通知界面', () async {
      final storage = await prepareStorage({'block_skin': BlockSkin.celadon.name});
      final provider = SettingsProvider(storage);
      var notified = 0;
      provider.addListener(() => notified++);
      expect(provider.blockSkin, BlockSkin.celadon);
      await provider.setBlockSkin(BlockSkin.ink);
      expect(provider.blockSkin, BlockSkin.ink);
      expect(storage.blockSkin, BlockSkin.ink);
      expect(notified, 1);
    });
  });
}
