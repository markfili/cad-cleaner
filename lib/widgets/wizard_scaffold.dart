import 'package:flutter/material.dart';

import '../cad/cad_service.dart';
import '../theme/app_dimens.dart';
import 'simulation_banner.dart';

/// Shared wizard chrome: step header, constrained content column, bottom nav.
///
/// Chrome stays full-bleed; only the readable column is constrained, so body
/// text doesn't stretch edge-to-edge on a maximized desktop window.
class WizardScaffold extends StatelessWidget {
  const WizardScaffold({
    required this.title,
    required this.service,
    required this.stepLabels,
    required this.currentStep,
    required this.body,
    required this.navigationBar,
    this.allowBack = true,
    super.key,
  });

  final String title;
  final CadService service;
  final List<String> stepLabels;
  final int currentStep;
  final List<Widget> body;
  final Widget navigationBar;
  final bool allowBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: allowBack,
      ),
      body: Column(
        children: [
          if (service.isSimulated) SimulationBanner(service: service),
          _StepHeader(labels: stepLabels, currentStep: currentStep),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.contentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: body,
                  ),
                ),
              ),
            ),
          ),
          navigationBar,
        ],
      ),
    );
  }
}

/// Numbered stepper — reads better than a bare progress bar for 3-4 steps.
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.labels, required this.currentStep});

  final List<String> labels;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.contentMaxWidth,
          ),
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                _StepDot(
                  index: i,
                  label: labels[i],
                  isDone: i < currentStep,
                  isCurrent: i == currentStep,
                ),
                if (i < labels.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      color: i < currentStep
                          ? scheme.primary
                          : scheme.outlineVariant,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.label,
    required this.isDone,
    required this.isCurrent,
  });

  final int index;
  final String label;
  final bool isDone;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Color background;
    final Color foreground;
    if (isDone) {
      background = scheme.primary;
      foreground = scheme.onPrimary;
    } else if (isCurrent) {
      background = scheme.primaryContainer;
      foreground = scheme.onPrimaryContainer;
    } else {
      background = scheme.surfaceContainerHigh;
      foreground = scheme.onSurfaceVariant;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: isCurrent ? Border.all(color: scheme.primary, width: 2) : null,
          ),
          alignment: Alignment.center,
          child: isDone
              ? Icon(Icons.check, size: 14, color: foreground)
              : Text(
                  '${index + 1}',
                  style: textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            color: isCurrent ? scheme.onSurface : scheme.onSurfaceVariant,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Bottom action bar shared by both wizards.
class WizardNavigationBar extends StatelessWidget {
  const WizardNavigationBar({
    required this.leading,
    required this.trailing,
    super.key,
  });

  final Widget leading;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [leading, trailing],
      ),
    );
  }
}
