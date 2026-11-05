import 'package:flutter/material.dart';

import 'block_palette.dart';

export 'block_painting.dart';
export 'block_palette.dart';

/// 中国红 + 宣纸底色的视觉基调，用于不随皮肤变化的点缀。
const Color appRed = Color(0xFFB03A2E);
const Color appGold = Color(0xFFC9A227);
const Color appInk = Color(0xFF2E2A24);
const Color appJade = Color(0xFF3F6B5B);
const Color appWood = Color(0xFF8B6239);

ThemeData buildLightTheme({
  String? fontFamily,
  BlockSkin skin = BlockSkin.paper,
}) => _buildBase(
  palette: BlockPalette.of(skin, dark: false),
  fontFamily: fontFamily,
);

ThemeData buildDarkTheme({
  String? fontFamily,
  BlockSkin skin = BlockSkin.paper,
}) => _buildBase(
  palette: BlockPalette.of(skin, dark: true),
  fontFamily: fontFamily,
);

ThemeData _buildBase({required BlockPalette palette, String? fontFamily}) {
  final base = palette.dark
      ? const ColorScheme.dark()
      : const ColorScheme.light();
  final colorScheme = base.copyWith(
    primary: palette.accent,
    onPrimary: palette.onAccent,
    primaryContainer: palette.primaryContainer,
    onPrimaryContainer: palette.onPrimaryContainer,
    secondary: palette.secondary,
    onSecondary: palette.onAccent,
    secondaryContainer: palette.secondaryContainer,
    onSecondaryContainer: palette.onSurface,
    tertiary: palette.tertiary,
    onTertiary: palette.onAccent,
    error: palette.error,
    onError: palette.onError,
    surface: palette.surface,
    onSurface: palette.onSurface,
    surfaceContainerHighest: palette.surfaceHighest,
    onSurfaceVariant: palette.onSurfaceVariant,
    outline: palette.outline,
    outlineVariant: palette.outlineVariant,
    surfaceTint: Colors.transparent,
  );

  final baseTheme = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.backdrop,
    fontFamily: fontFamily,
  );
  final textTheme = baseTheme.textTheme.apply(
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
    fontFamily: fontFamily,
  );

  return baseTheme.copyWith(
    textTheme: textTheme.copyWith(
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 52,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.7)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 46),
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      showCheckmark: false,
      side: BorderSide(color: colorScheme.outline),
      shape: const StadiumBorder(),
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 13,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outline.withValues(alpha: 0.6),
      thickness: 0.6,
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    splashFactory: InkSparkle.splashFactory,
  );
}
