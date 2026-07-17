import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// Terminal-style panel showing operation output as it happens.
///
/// Stays dark in both themes, the way an embedded terminal conventionally does.
class LogPanel extends StatelessWidget {
  const LogPanel({required this.lines, this.height, super.key});

  final List<String> lines;
  final double? height;

  static const _background = Color(0xFF0D1117);
  static const _defaultText = Color(0xFFE6E8EB);
  static const _successText = Color(0xFF4ADE94);
  static const _errorText = Color(0xFFF85149);
  static const _dimText = Color(0xFF6E7681);

  /// The log already marks lines with ✓/✗/═, so colour follows those markers
  /// rather than needing a parallel severity channel.
  Color _colorFor(String line) {
    if (line.contains('✗')) return _errorText;
    if (line.contains('✓')) return _successText;
    if (line.startsWith('═')) return _dimText;
    // Indented detail lines (per-file, per-key progress) recede.
    if (line.startsWith('  ')) return _dimText;
    return _defaultText;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: _background,
        borderRadius: AppRadius.mdAll,
      ),
      child: SingleChildScrollView(
        reverse: true,
        child: SelectableText.rich(
          TextSpan(
            children: [
              for (final line in lines)
                TextSpan(
                  text: '$line\n',
                  style: TextStyle(color: _colorFor(line)),
                ),
            ],
          ),
          style: const TextStyle(
            fontFamilyFallback: AppFonts.monoFallback,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
