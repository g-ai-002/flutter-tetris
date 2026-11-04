import 'package:flutter/material.dart';

import '../game/tetromino.dart';

/// 方块配色：取自传统颜料名，浅色模式下沉稳，深色模式下提亮。
class BlockPalette {
  const BlockPalette({required this.dark});

  final bool dark;

  static const BlockPalette light = BlockPalette(dark: false);
  static const BlockPalette darkPalette = BlockPalette(dark: true);

  static const Map<TetrominoType, Color> _lightColors = {
    TetrominoType.i: Color(0xFF2E7DA3),
    TetrominoType.o: Color(0xFFD6A126),
    TetrominoType.t: Color(0xFF7A5AA6),
    TetrominoType.s: Color(0xFF4C8C6B),
    TetrominoType.z: Color(0xFFC2453D),
    TetrominoType.j: Color(0xFF3D5C99),
    TetrominoType.l: Color(0xFFC67B32),
  };

  static const Map<TetrominoType, Color> _darkColors = {
    TetrominoType.i: Color(0xFF4FA3CC),
    TetrominoType.o: Color(0xFFE8B93F),
    TetrominoType.t: Color(0xFF9A7BC8),
    TetrominoType.s: Color(0xFF67B18C),
    TetrominoType.z: Color(0xFFE06054),
    TetrominoType.j: Color(0xFF5B7FC7),
    TetrominoType.l: Color(0xFFE0984F),
  };

  Color colorOf(TetrominoType type) =>
      (dark ? _darkColors : _lightColors)[type]!;

  /// 方块名称对应的颜色，用于图例与预览。
  List<(TetrominoType, Color)> get legend => [
    for (final type in TetrominoType.values) (type, colorOf(type)),
  ];

  Color get boardBackground =>
      dark ? const Color(0xFF1A1712) : const Color(0xFFFFFCF4);

  Color get boardBorder =>
      dark ? const Color(0xFF4A4033) : const Color(0xFFE2D6BF);

  Color get gridLine => dark
      ? Colors.white.withValues(alpha: 0.055)
      : const Color(0xFF8C6239).withValues(alpha: 0.10);

  Color get wellShadow => dark
      ? Colors.black.withValues(alpha: 0.55)
      : const Color(0xFF7A5A38).withValues(alpha: 0.16);

  Color get dangerTint => const Color(0xFFC2453D);

  Color get ghostStroke => dark
      ? Colors.white.withValues(alpha: 0.30)
      : const Color(0xFF5A4A38).withValues(alpha: 0.32);
}
