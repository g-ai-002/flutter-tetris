import 'package:flutter/material.dart';

const _primary = Color(0xFF1E88E5);

class _ThemeColors {
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color onSurfaceVariant;
  final Color error;
  final Color onError;
  final Color outline;
  final Color scaffoldBg;

  const _ThemeColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.error,
    required this.onError,
    required this.outline,
    required this.scaffoldBg,
  });

  static const light = _ThemeColors(
    primary: _primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFBBDEFB),
    onPrimaryContainer: Color(0xFF0D47A1),
    secondary: Color(0xFF26A69A),
    onSecondary: Colors.white,
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF222222),
    surfaceVariant: Color(0xFFEEF0F3),
    onSurfaceVariant: Color(0xFF6B7280),
    error: Color(0xFFE53935),
    onError: Colors.white,
    outline: Color(0xFFE5E7EB),
    scaffoldBg: Color(0xFFF7F8FA),
  );

  static const dark = _ThemeColors(
    primary: Color(0xFF64B5F6),
    onPrimary: Color(0xFF0D47A1),
    primaryContainer: Color(0xFF1565C0),
    onPrimaryContainer: Color(0xFFE3F2FD),
    secondary: Color(0xFF4DB6AC),
    onSecondary: Color(0xFF003B36),
    surface: Color(0xFF202225),
    onSurface: Color(0xFFE6E8EB),
    surfaceVariant: Color(0xFF2A2C30),
    onSurfaceVariant: Color(0xFFA1A6AD),
    error: Color(0xFFEF5350),
    onError: Color(0xFF1A1A1A),
    outline: Color(0xFF34383E),
    scaffoldBg: Color(0xFF17181B),
  );
}

ThemeData buildLightTheme({String? fontFamily}) =>
    _buildTheme(_ThemeColors.light, Brightness.light, fontFamily);

ThemeData buildDarkTheme({String? fontFamily}) =>
    _buildTheme(_ThemeColors.dark, Brightness.dark, fontFamily);

ThemeData _buildTheme(_ThemeColors c, Brightness brightness, String? fontFamily) {
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: c.primary,
    onPrimary: c.onPrimary,
    primaryContainer: c.primaryContainer,
    onPrimaryContainer: c.onPrimaryContainer,
    secondary: c.secondary,
    onSecondary: c.onSecondary,
    surface: c.surface,
    onSurface: c.onSurface,
    surfaceContainerHighest: c.surfaceVariant,
    onSurfaceVariant: c.onSurfaceVariant,
    error: c.error,
    onError: c.onError,
    outline: c.outline,
    surfaceTint: Colors.transparent,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: c.scaffoldBg,
    fontFamily: fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: c.surface,
      foregroundColor: c.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 48,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: c.onSurface,
        fontFamily: fontFamily,
      ),
      shape: Border(bottom: BorderSide(color: c.outline, width: 0.5)),
    ),
    dividerTheme: DividerThemeData(color: c.outline, thickness: 0.5, space: 0.5),
    cardTheme: CardThemeData(
      elevation: 0,
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
      ),
    ),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.onSurface, fontFamily: fontFamily),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.onSurface, fontFamily: fontFamily),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.onSurface, fontFamily: fontFamily),
      bodyLarge: TextStyle(fontSize: 15, color: c.onSurface, fontFamily: fontFamily),
      bodyMedium: TextStyle(fontSize: 14, color: c.onSurface, fontFamily: fontFamily),
      bodySmall: TextStyle(fontSize: 12, color: c.onSurfaceVariant, fontFamily: fontFamily),
    ),
  );
}
