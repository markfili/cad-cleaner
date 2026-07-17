import 'dart:io';

import 'package:flutter/material.dart';

import '../cad/cad_service.dart';
import '../theme/app_dimens.dart';
import '../theme/semantic_colors.dart';

/// Makes it unmistakable that a simulated run changed nothing.
///
/// This is a correctness feature, not decoration: it is persistent,
/// non-dismissible, and uses a hue reserved for simulation alone.
class SimulationBanner extends StatelessWidget {
  const SimulationBanner({required this.service, super.key});

  final CadService service;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic.simulation;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      color: colors.container,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.science_outlined, size: 18, color: colors.fg),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'SIMULATION MODE',
            style: textTheme.labelLarge?.copyWith(
              color: colors.fg,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '${service.backendName} on ${Platform.operatingSystem} — real '
              'removal and installation only happen on Windows.',
              style: textTheme.bodyMedium?.copyWith(color: colors.onContainer),
            ),
          ),
        ],
      ),
    );
  }
}
