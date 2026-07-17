import 'package:flutter/material.dart';

import '../cad/cad_service.dart';
import '../theme/app_dimens.dart';
import '../theme/semantic_colors.dart';
import '../widgets/info_callout.dart';
import '../widgets/log_panel.dart';
import '../widgets/wizard_scaffold.dart';

/// Removes an installed GstarCAD via the command its registry entry provides.
class RemoveGstarCadScreen extends StatefulWidget {
  const RemoveGstarCadScreen({
    required this.service,
    required this.productName,
    super.key,
  });

  final CadService service;

  /// The installed product, as detected.
  final String productName;

  @override
  State<RemoveGstarCadScreen> createState() => _RemoveGstarCadScreenState();
}

class _RemoveGstarCadScreenState extends State<RemoveGstarCadScreen> {
  static const _steps = ['Confirm', 'Remove', 'Complete'];

  int currentStep = 0;
  bool isWorking = false;
  bool isDone = false;
  String? errorMessage;
  final List<String> logs = [];

  CadService get service => widget.service;

  void _addLog(String message) {
    if (!mounted) return;
    setState(() => logs.add(message));
  }

  Future<void> _remove() async {
    service.onLog = _addLog;

    setState(() {
      isWorking = true;
      errorMessage = null;
      currentStep = 1;
      logs
        ..clear()
        ..add('Backend: ${service.backendName}');
    });

    try {
      await service.uninstallGstarCad();
      if (!mounted) return;
      setState(() {
        isWorking = false;
        isDone = true;
        currentStep = 2;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isWorking = false;
        errorMessage = e is CadServiceException ? e.message : '$e';
        logs
          ..add('')
          ..add('✗ Removal failed: $errorMessage');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      title: 'Remove GstarCAD',
      service: service,
      stepLabels: _steps,
      currentStep: currentStep,
      allowBack: !isWorking,
      body: switch (currentStep) {
        0 => _buildConfirmStep(),
        1 => _buildProgressStep(),
        _ => _buildCompleteStep(),
      },
      navigationBar: _buildNavigationBar(),
    );
  }

  List<Widget> _buildConfirmStep() {
    final theme = Theme.of(context);

    return [
      Text('Remove GstarCAD', style: theme.textTheme.headlineSmall),
      const SizedBox(height: AppSpacing.md),
      Text(
        'This will run the uninstaller for:',
        style: theme.textTheme.bodyLarge,
      ),
      const SizedBox(height: AppSpacing.md),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              Icons.delete_outline,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(widget.productName, style: theme.textTheme.bodyLarge),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      InfoCallout(
        role: SemanticRole.danger,
        child: const Text(
          'This removes GstarCAD from this computer. Your drawings are not '
          'touched, but the application and its settings are.',
        ),
      ),
      if (service.isSimulated) ...[
        const SizedBox(height: AppSpacing.lg),
        InfoCallout(
          role: SemanticRole.simulation,
          child: const Text(
            'Simulation mode: nothing will actually be removed.',
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildProgressStep() {
    final theme = Theme.of(context);

    return [
      Row(
        children: [
          Text('Removing GstarCAD', style: theme.textTheme.headlineSmall),
          const SizedBox(width: AppSpacing.lg),
          if (isWorking)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      if (errorMessage != null) ...[
        InfoCallout(
          role: SemanticRole.danger,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Removal failed',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(errorMessage!),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
      LogPanel(lines: logs, height: 320),
    ];
  }

  List<Widget> _buildCompleteStep() {
    final theme = Theme.of(context);
    final success = context.semantic.success;

    return [
      Center(
        child: Column(
          children: [
            Icon(Icons.check_circle, color: success.fg, size: 56),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'GstarCAD Removed',
              style: theme.textTheme.headlineSmall?.copyWith(color: success.fg),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      LogPanel(lines: logs, height: 220),
    ];
  }

  Widget _buildNavigationBar() {
    final scheme = Theme.of(context).colorScheme;

    return WizardNavigationBar(
      leading: TextButton(
        onPressed:
            isWorking || isDone ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      trailing: switch (currentStep) {
        0 => FilledButton.icon(
            onPressed: _remove,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Remove GstarCAD'),
          ),
        1 => errorMessage != null
            ? FilledButton.icon(
                onPressed: _remove,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              )
            : const FilledButton(
                onPressed: null,
                child: Text('Working...'),
              ),
        _ => FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
      },
    );
  }
}
