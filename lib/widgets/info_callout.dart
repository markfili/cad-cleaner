import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/semantic_colors.dart';

/// A semantic notice: tinted fill, left accent bar, and a role icon.
///
/// Replaces the ad-hoc `Container(color: Colors.orange[50], border: ...)`
/// boxes so severity comes from one place — which matters here, because
/// severity is a safety signal, not decoration.
class InfoCallout extends StatelessWidget {
  const InfoCallout({
    required this.role,
    required this.child,
    this.icon,
    super.key,
  });

  final SemanticRole role;
  final Widget child;

  /// Defaults to the role's conventional icon.
  final IconData? icon;

  IconData get _defaultIcon => switch (role) {
        SemanticRole.success => Icons.check_circle_outline,
        SemanticRole.warning => Icons.warning_amber_rounded,
        SemanticRole.danger => Icons.dangerous_outlined,
        SemanticRole.info => Icons.info_outline,
        SemanticRole.simulation => Icons.science_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic.forRole(role);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: AppRadius.smAll,
        // A 3px accent bar rather than a full saturated outline.
        border: Border(left: BorderSide(color: colors.fg, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? _defaultIcon, size: 18, color: colors.fg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DefaultTextStyle.merge(
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: colors.onContainer),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
