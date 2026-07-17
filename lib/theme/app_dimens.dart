import 'package:flutter/material.dart';

/// Spacing scale. Every gap in the app comes from here.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Keeps line length readable when the window is maximized.
  static const contentMaxWidth = 720.0;
}

/// Corner radii. Larger containers get larger radii, so a callout inside a card
/// never looks tighter than the card around it.
abstract final class AppRadius {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;

  static const smAll = BorderRadius.all(Radius.circular(sm));
  static const mdAll = BorderRadius.all(Radius.circular(md));
}

/// Monospace stack for terminal output.
///
/// Falls back across platforms rather than bundling a font; 'Courier New' is
/// kept only as a last resort before the generic family.
abstract final class AppFonts {
  static const monoFallback = <String>[
    'SF Mono',
    'Menlo',
    'Cascadia Mono',
    'Consolas',
    'Courier New',
    'monospace',
  ];
}
