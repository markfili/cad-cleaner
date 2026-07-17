import 'package:flutter/material.dart';

/// Hand-authored color schemes.
///
/// Not seed-generated: M3 seeding is tuned for mobile brand moments, and this
/// is a dense desktop utility where chrome should recede.
abstract final class AppColors {
  // Canvas sits behind the cards; on desktop the canvas/surface contrast is
  // what separates them, so shadows aren't needed.
  static const lightCanvas = Color(0xFFF4F6F9);
  static const darkCanvas = Color(0xFF14181F);

  static const light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2F5FCE),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDCE6FB),
    onPrimaryContainer: Color(0xFF16327A),
    secondary: Color(0xFF5B6472),
    onSecondary: Color(0xFFFFFFFF),
    error: Color(0xFFC4291F),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFBE1DE),
    onErrorContainer: Color(0xFF7A160F),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1B2430),
    onSurfaceVariant: Color(0xFF5B6472),
    surfaceContainerLow: Color(0xFFF7F8FA),
    surfaceContainerHigh: Color(0xFFEAEDF2),
    outline: Color(0xFFC6CDD6),
    outlineVariant: Color(0xFFE1E5EA),
  );

  // Dark surfaces get *lighter* as they elevate, so `surface` is lighter than
  // the canvas rather than the reverse.
  static const dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF7DA2F5),
    onPrimary: Color(0xFF0B234D),
    primaryContainer: Color(0xFF223A6E),
    onPrimaryContainer: Color(0xFFC9DBFB),
    secondary: Color(0xFFA0A8B4),
    onSecondary: Color(0xFF14181F),
    error: Color(0xFFFF6B5E),
    onError: Color(0xFF3A0A06),
    errorContainer: Color(0xFF4A1613),
    onErrorContainer: Color(0xFFFFC7C0),
    surface: Color(0xFF1B2029),
    onSurface: Color(0xFFE7EAEF),
    onSurfaceVariant: Color(0xFFA0A8B4),
    surfaceContainerLow: Color(0xFF181D25),
    surfaceContainerHigh: Color(0xFF20262F),
    outline: Color(0xFF333B48),
    outlineVariant: Color(0xFF262C36),
  );
}
