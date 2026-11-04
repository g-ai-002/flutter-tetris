import 'package:flutter/material.dart';

export 'block_painting.dart';
export 'block_palette.dart';

/// 中国红 + 宣纸底色的视觉基调。
const Color appRed = Color(0xFFB03A2E);
const Color appGold = Color(0xFFC9A227);
const Color appInk = Color(0xFF2E2A24);
const Color appJade = Color(0xFF3F6B5B);
const Color appWood = Color(0xFF8B6239);

ThemeData buildLightTheme({String? fontFamily}) {
  const scheme = ColorScheme.light(
    primary: Color(0xFFB03A2E),
    onPrimary: Color(0xFFFFF8F2),
    primaryContainer: Color(0xFFF6DED7),
    onPrimaryContainer: Color(0xFF5A1A10),
    secondary: Color(0xFF7A6146),
    onSecondary: Color(0xFFFFF8F2),
    surface: Color(0xFFFFFBF2),
    onSurface: Color(0xFF2E2A24),
    surfaceContainerHighest: Color(0xFFF3EBDC),
    onSurfaceVariant: Color(0xFF7C7062),
    outline: Color(0xFFE3D7C3),
    outlineVariant: Color(0xFFEFE6D6),
    error: Color(0xFFB3261E),
    surfaceTint: Colors.transparent,
    tertiary: Color(0xFF3F6B5B),
  );

  return _buildBase(
    colorScheme: scheme,
    scaffoldColor: const Color(0xFFF6EFE1),
    fontFamily: fontFamily,
  );
}

ThemeData buildDarkTheme({String? fontFamily}) {
  const scheme = ColorScheme.dark(
    primary: Color(0xFFE08A72),
    onPrimary: Color(0xFF3A1109),
    primaryContainer: Color(0xFF5A2318),
    onPrimaryContainer: Color(0xFFF8DCD2),
    secondary: Color(0xFFC6AA85),
    onSecondary: Color(0xFF3A2A16),
    surface: Color(0xFF221E18),
    onSurface: Color(0xFFEFE6D8),
    surfaceContainerHighest: Color(0xFF2D2720),
    onSurfaceVariant: Color(0xFFA99C8A),
    outline: Color(0xFF3D362C),
    outlineVariant: Color(0xFF332D24),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF3A0A08),
    surfaceTint: Colors.transparent,
    tertiary: Color(0xFF8FBFAE),
  );

  return _buildBase(
    colorScheme: scheme,
    scaffoldColor: const Color(0xFF17140F),
    fontFamily: fontFamily,
  );
}

ThemeData _buildBase({
  required ColorScheme colorScheme,
  required Color scaffoldColor,
  String? fontFamily,
}) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldColor,
    fontFamily: fontFamily,
  );
  final textTheme = base.textTheme.apply(
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
    fontFamily: fontFamily,
  );

  return base.copyWith(
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
