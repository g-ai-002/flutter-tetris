import 'package:flutter/material.dart';

import '../game/tetromino.dart';
import 'block_skin.dart';

export 'block_skin.dart';

/// 方块配色：每套皮肤自带浅色 / 深色两副色板。
///
/// 方块颜色取自传统颜料名，棋盘底色与界面强调色跟随皮肤，
/// 让首页、设置页与对局场地保持同一套观感。
class BlockPalette {
  const BlockPalette._({
    required this.skin,
    required this.dark,
    required this.colors,
    required this.accent,
    required this.secondary,
    required this.tertiary,
    required this.surface,
    required this.backdrop,
    required this.screenTop,
    required this.screenBottom,
    required this.boardTop,
    required this.boardBottom,
    required this.garbageBlock,
  });

  final BlockSkin skin;
  final bool dark;
  final Map<TetrominoType, Color> colors;

  /// 界面强调色，用于按钮、选中态与首页标题装饰。
  final Color accent;
  final Color secondary;
  final Color tertiary;
  final Color surface;
  final Color backdrop;
  final Color screenTop;
  final Color screenBottom;
  final Color boardTop;
  final Color boardBottom;
  final Color garbageBlock;

  /// 默认的宣纸皮肤，保留给无需关心皮肤的场景。
  static const BlockPalette light = _paperLight;
  static const BlockPalette darkPalette = _paperDark;

  static BlockPalette of(BlockSkin skin, {required bool dark}) =>
      switch (skin) {
        BlockSkin.paper => dark ? _paperDark : _paperLight,
        BlockSkin.celadon => dark ? _celadonDark : _celadonLight,
        BlockSkin.dunhuang => dark ? _dunhuangDark : _dunhuangLight,
        BlockSkin.ink => dark ? _inkDark : _inkLight,
      };

  Color colorOf(TetrominoType type) => colors[type]!;

  /// 方块名称对应的颜色，用于图例与预览。
  List<(TetrominoType, Color)> get legend => [
    for (final type in TetrominoType.values) (type, colorOf(type)),
  ];

  Color get boardBackground => boardBottom;

  /// 首页等整屏背景的纵向渐变。
  LinearGradient get screenGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [screenTop, screenBottom],
  );

  /// 棋盘底色的纵向渐变，Flame 场地与首页缩略棋盘共用。
  LinearGradient get boardGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [boardTop, boardBottom],
  );

  Color get boardBorder => Color.lerp(boardBottom, accent, dark ? 0.30 : 0.22)!;

  Color get gridLine => accent.withValues(alpha: dark ? 0.07 : 0.09);

  Color get wellShadow => dark
      ? Colors.black.withValues(alpha: 0.55)
      : accent.withValues(alpha: 0.16);

  Color get dangerTint => const Color(0xFFC2453D);

  Color get onSurface => dark
      ? Color.lerp(const Color(0xFFEFE6D8), accent, 0.10)!
      : Color.lerp(const Color(0xFF2E2A24), accent, 0.10)!;

  Color get onSurfaceVariant => dark
      ? Color.lerp(const Color(0xFFA99C8A), accent, 0.12)!
      : Color.lerp(const Color(0xFF7C7062), accent, 0.18)!;

  Color get onAccent => accent.computeLuminance() > 0.35
      ? const Color(0xFF201A14)
      : const Color(0xFFFFF8F2);

  Color get primaryContainer =>
      Color.alphaBlend(accent.withValues(alpha: dark ? 0.28 : 0.14), surface);

  Color get onPrimaryContainer => dark
      ? Color.lerp(accent, Colors.white, 0.55)!
      : Color.lerp(accent, Colors.black, 0.55)!;

  Color get secondaryContainer => Color.alphaBlend(
    secondary.withValues(alpha: dark ? 0.22 : 0.16),
    surface,
  );

  Color get surfaceHighest => Color.lerp(surface, accent, dark ? 0.10 : 0.06)!;

  Color get outline => Color.lerp(surface, onSurface, 0.14)!;

  Color get outlineVariant => Color.lerp(surface, onSurface, 0.08)!;

  Color get error => dark ? const Color(0xFFF2B8B5) : const Color(0xFFB3261E);

  Color get onError => dark ? const Color(0xFF3A0A08) : Colors.white;

  static const Map<TetrominoType, Color> _paperLightColors = {
    TetrominoType.i: Color(0xFF2E7DA3), TetrominoType.o: Color(0xFFD6A126),
    TetrominoType.t: Color(0xFF7A5AA6), TetrominoType.s: Color(0xFF4C8C6B),
    TetrominoType.z: Color(0xFFC2453D), TetrominoType.j: Color(0xFF3D5C99),
    TetrominoType.l: Color(0xFFC67B32),
  };

  static const Map<TetrominoType, Color> _paperDarkColors = {
    TetrominoType.i: Color(0xFF4FA3CC), TetrominoType.o: Color(0xFFE8B93F),
    TetrominoType.t: Color(0xFF9A7BC8), TetrominoType.s: Color(0xFF67B18C),
    TetrominoType.z: Color(0xFFE06054), TetrominoType.j: Color(0xFF5B7FC7),
    TetrominoType.l: Color(0xFFE0984F),
  };

  static const Map<TetrominoType, Color> _celadonLightColors = {
    TetrominoType.i: Color(0xFF3C7A86), TetrominoType.o: Color(0xFFC9A24B),
    TetrominoType.t: Color(0xFF6E7FA8), TetrominoType.s: Color(0xFF5E9678),
    TetrominoType.z: Color(0xFFB5534A), TetrominoType.j: Color(0xFF4A6E9E),
    TetrominoType.l: Color(0xFFB07B4A),
  };

  static const Map<TetrominoType, Color> _celadonDarkColors = {
    TetrominoType.i: Color(0xFF63A9B4), TetrominoType.o: Color(0xFFE0BC63),
    TetrominoType.t: Color(0xFF8E9FC8), TetrominoType.s: Color(0xFF7DBA98),
    TetrominoType.z: Color(0xFFD47468), TetrominoType.j: Color(0xFF6E92C6),
    TetrominoType.l: Color(0xFFCE9A64),
  };

  static const Map<TetrominoType, Color> _dunhuangLightColors = {
    TetrominoType.i: Color(0xFF2F6E8C), TetrominoType.o: Color(0xFFD2A33C),
    TetrominoType.t: Color(0xFF7C5A8E), TetrominoType.s: Color(0xFF4F8A6B),
    TetrominoType.z: Color(0xFFB8422F), TetrominoType.j: Color(0xFF335A8C),
    TetrominoType.l: Color(0xFFC07832),
  };

  static const Map<TetrominoType, Color> _dunhuangDarkColors = {
    TetrominoType.i: Color(0xFF4E93B2), TetrominoType.o: Color(0xFFE8BE5B),
    TetrominoType.t: Color(0xFFA07FB2), TetrominoType.s: Color(0xFF6FAE8B),
    TetrominoType.z: Color(0xFFD8624C), TetrominoType.j: Color(0xFF557FBE),
    TetrominoType.l: Color(0xFFDC9953),
  };

  static const Map<TetrominoType, Color> _inkLightColors = {
    TetrominoType.i: Color(0xFF4A6B82), TetrominoType.o: Color(0xFFB8912F),
    TetrominoType.t: Color(0xFF6E5B7E), TetrominoType.s: Color(0xFF5E7F63),
    TetrominoType.z: Color(0xFFA63D32), TetrominoType.j: Color(0xFF3E4E63),
    TetrominoType.l: Color(0xFF9A6A42),
  };

  static const Map<TetrominoType, Color> _inkDarkColors = {
    TetrominoType.i: Color(0xFF7699B2), TetrominoType.o: Color(0xFFD4B052),
    TetrominoType.t: Color(0xFF9884A8), TetrominoType.s: Color(0xFF84A889),
    TetrominoType.z: Color(0xFFC9665A), TetrominoType.j: Color(0xFF6A7E96),
    TetrominoType.l: Color(0xFFBE8C63),
  };

  static const BlockPalette _paperLight = BlockPalette._(
    skin: BlockSkin.paper, dark: false, colors: _paperLightColors,
    accent: Color(0xFFB03A2E), secondary: Color(0xFF7A6146), tertiary: Color(0xFF3F6B5B),
    surface: Color(0xFFFFFBF2), backdrop: Color(0xFFF6EFE1),
    screenTop: Color(0xFFFCF6E9), screenBottom: Color(0xFFF0E3CC),
    boardTop: Color(0xFFFDFAF2), boardBottom: Color(0xFFF7EEDC),
    garbageBlock: Color(0xFF9C9385),
  );

  static const BlockPalette _paperDark = BlockPalette._(
    skin: BlockSkin.paper, dark: true, colors: _paperDarkColors,
    accent: Color(0xFFE08A72), secondary: Color(0xFFC6AA85), tertiary: Color(0xFF8FBFAE),
    surface: Color(0xFF221E18), backdrop: Color(0xFF17140F),
    screenTop: Color(0xFF201B14), screenBottom: Color(0xFF121009),
    boardTop: Color(0xFF23201A), boardBottom: Color(0xFF15120E),
    garbageBlock: Color(0xFF7A7265),
  );

  static const BlockPalette _celadonLight = BlockPalette._(
    skin: BlockSkin.celadon, dark: false, colors: _celadonLightColors,
    accent: Color(0xFF2F6455), secondary: Color(0xFF6B7F73), tertiary: Color(0xFFA67C3D),
    surface: Color(0xFFF7FBF6), backdrop: Color(0xFFEDF2EA),
    screenTop: Color(0xFFF8FCF6), screenBottom: Color(0xFFE2EBE1),
    boardTop: Color(0xFFFBFDF9), boardBottom: Color(0xFFEFF6EC),
    garbageBlock: Color(0xFF9AA79C),
  );

  static const BlockPalette _celadonDark = BlockPalette._(
    skin: BlockSkin.celadon, dark: true, colors: _celadonDarkColors,
    accent: Color(0xFF8FC7B2), secondary: Color(0xFFA9BCAF), tertiary: Color(0xFFD8B06A),
    surface: Color(0xFF18211D), backdrop: Color(0xFF0F1713),
    screenTop: Color(0xFF18221D), screenBottom: Color(0xFF0C120F),
    boardTop: Color(0xFF1B2420), boardBottom: Color(0xFF0E1512),
    garbageBlock: Color(0xFF6E7D72),
  );

  static const BlockPalette _dunhuangLight = BlockPalette._(
    skin: BlockSkin.dunhuang, dark: false, colors: _dunhuangLightColors,
    accent: Color(0xFFA65A24), secondary: Color(0xFF8A6A45), tertiary: Color(0xFF3E6E86),
    surface: Color(0xFFFFF8EC), backdrop: Color(0xFFF7EBD9),
    screenTop: Color(0xFFFCF2E0), screenBottom: Color(0xFFF0DDC2),
    boardTop: Color(0xFFFFF9EE), boardBottom: Color(0xFFF6E9D2),
    garbageBlock: Color(0xFFA99680),
  );

  static const BlockPalette _dunhuangDark = BlockPalette._(
    skin: BlockSkin.dunhuang, dark: true, colors: _dunhuangDarkColors,
    accent: Color(0xFFE0A45C), secondary: Color(0xFFC7AE8C), tertiary: Color(0xFF82B4C9),
    surface: Color(0xFF241D15), backdrop: Color(0xFF191410),
    screenTop: Color(0xFF241C13), screenBottom: Color(0xFF110D09),
    boardTop: Color(0xFF272019), boardBottom: Color(0xFF120E0A),
    garbageBlock: Color(0xFF7E7365),
  );

  static const BlockPalette _inkLight = BlockPalette._(
    skin: BlockSkin.ink, dark: false, colors: _inkLightColors,
    accent: Color(0xFF33383D), secondary: Color(0xFF6B6F73), tertiary: Color(0xFF8C3A2E),
    surface: Color(0xFFFAFAF7), backdrop: Color(0xFFF1F1EC),
    screenTop: Color(0xFFF8F8F4), screenBottom: Color(0xFFE7E7E0),
    boardTop: Color(0xFFFCFCF9), boardBottom: Color(0xFFEFEFE9),
    garbageBlock: Color(0xFFA3A39B),
  );

  static const BlockPalette _inkDark = BlockPalette._(
    skin: BlockSkin.ink, dark: true, colors: _inkDarkColors,
    accent: Color(0xFFC9CDD2), secondary: Color(0xFFA6ABB0), tertiary: Color(0xFFE08C7C),
    surface: Color(0xFF1B1E20), backdrop: Color(0xFF121415),
    screenTop: Color(0xFF1A1D1F), screenBottom: Color(0xFF0E1011),
    boardTop: Color(0xFF1E2123), boardBottom: Color(0xFF101213),
    garbageBlock: Color(0xFF70756F),
  );
}

extension BlockSkinPalette on BlockSkin {
  BlockPalette palette({required bool dark}) =>
      BlockPalette.of(this, dark: dark);
}
