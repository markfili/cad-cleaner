import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'semantic_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
        scheme: AppColors.light,
        canvas: AppColors.lightCanvas,
        semantic: SemanticColors.lightColors,
      );

  static ThemeData get dark => _build(
        scheme: AppColors.dark,
        canvas: AppColors.darkCanvas,
        semantic: SemanticColors.darkColors,
      );

  static ThemeData _build({
    required ColorScheme scheme,
    required Color canvas,
    required SemanticColors semantic,
  }) {
    final textTheme = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      textTheme: textTheme,
      extensions: [semantic],

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium,
        shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),

      // Canvas/surface contrast provides the depth cue, so cards carry a
      // hairline border instead of a shadow.
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: scheme.outlineVariant),
          borderRadius: AppRadius.mdAll,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        // Dialogs genuinely float, so they keep a real shadow.
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyLarge,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: scheme.outlineVariant,
        linearMinHeight: 6,
      ),

      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),

      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final onSurface = scheme.onSurface;
    final variant = scheme.onSurfaceVariant;

    return TextTheme(
      headlineSmall: TextStyle(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 14, height: 20 / 14, color: onSurface),
      bodyMedium: TextStyle(fontSize: 13, height: 18 / 13, color: variant),
      labelLarge: const TextStyle(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w500,
        color: variant,
      ),
    );
  }
}
