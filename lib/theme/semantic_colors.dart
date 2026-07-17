import 'package:flutter/material.dart';

/// The meaning a callout carries. Severity is a design decision with safety
/// consequences here, so it is named rather than passed as a raw color.
enum SemanticRole { success, warning, danger, info, simulation }

/// One role's three colors: accent, fill, and text on that fill.
@immutable
class SemanticColorSet {
  const SemanticColorSet({
    required this.fg,
    required this.container,
    required this.onContainer,
  });

  /// Accent: icons and the left accent bar.
  final Color fg;

  /// Callout fill.
  final Color container;

  /// Text on [container].
  final Color onContainer;

  static SemanticColorSet lerp(
    SemanticColorSet a,
    SemanticColorSet b,
    double t,
  ) {
    return SemanticColorSet(
      fg: Color.lerp(a.fg, b.fg, t)!,
      container: Color.lerp(a.container, b.container, t)!,
      onContainer: Color.lerp(a.onContainer, b.onContainer, t)!,
    );
  }
}

/// Semantic colors that M3's [ColorScheme] has no slot for.
@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  const SemanticColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.simulation,
  });

  final SemanticColorSet success;
  final SemanticColorSet warning;
  final SemanticColorSet danger;
  final SemanticColorSet info;

  /// Violet, deliberately not reused by any other role: a simulated run must
  /// never be visually confused with an informational notice.
  final SemanticColorSet simulation;

  SemanticColorSet forRole(SemanticRole role) => switch (role) {
        SemanticRole.success => success,
        SemanticRole.warning => warning,
        SemanticRole.danger => danger,
        SemanticRole.info => info,
        SemanticRole.simulation => simulation,
      };

  static const lightColors = SemanticColors(
    success: SemanticColorSet(
      fg: Color(0xFF1E8E5A),
      container: Color(0xFFDDF3E7),
      onContainer: Color(0xFF114A30),
    ),
    warning: SemanticColorSet(
      fg: Color(0xFFA15C00),
      container: Color(0xFFFBEBD2),
      onContainer: Color(0xFF5C3A00),
    ),
    danger: SemanticColorSet(
      fg: Color(0xFFC4291F),
      container: Color(0xFFFBE1DE),
      onContainer: Color(0xFF7A160F),
    ),
    info: SemanticColorSet(
      fg: Color(0xFF2A6DB0),
      container: Color(0xFFDDEBFB),
      onContainer: Color(0xFF123A5C),
    ),
    simulation: SemanticColorSet(
      fg: Color(0xFF6E3FA3),
      container: Color(0xFFEEE2F9),
      onContainer: Color(0xFF3D1F63),
    ),
  );

  static const darkColors = SemanticColors(
    success: SemanticColorSet(
      fg: Color(0xFF4ADE94),
      container: Color(0xFF16382A),
      onContainer: Color(0xFFB9F3D3),
    ),
    warning: SemanticColorSet(
      fg: Color(0xFFF0B429),
      container: Color(0xFF4A3505),
      onContainer: Color(0xFFFBDFA1),
    ),
    danger: SemanticColorSet(
      fg: Color(0xFFFF6B5E),
      container: Color(0xFF4A1613),
      onContainer: Color(0xFFFFC7C0),
    ),
    info: SemanticColorSet(
      fg: Color(0xFF6FA8E8),
      container: Color(0xFF16283D),
      onContainer: Color(0xFFC6E0FB),
    ),
    simulation: SemanticColorSet(
      fg: Color(0xFFC79EED),
      container: Color(0xFF2E1C46),
      onContainer: Color(0xFFEBD9FA),
    ),
  );

  @override
  SemanticColors copyWith({
    SemanticColorSet? success,
    SemanticColorSet? warning,
    SemanticColorSet? danger,
    SemanticColorSet? info,
    SemanticColorSet? simulation,
  }) {
    return SemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      simulation: simulation ?? this.simulation,
    );
  }

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) {
      return this;
    }
    return SemanticColors(
      success: SemanticColorSet.lerp(success, other.success, t),
      warning: SemanticColorSet.lerp(warning, other.warning, t),
      danger: SemanticColorSet.lerp(danger, other.danger, t),
      info: SemanticColorSet.lerp(info, other.info, t),
      simulation: SemanticColorSet.lerp(simulation, other.simulation, t),
    );
  }
}

extension SemanticColorsX on BuildContext {
  SemanticColors get semantic => Theme.of(this).extension<SemanticColors>()!;
}
