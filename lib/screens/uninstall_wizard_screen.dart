import 'package:flutter/material.dart';

import '../cad/cad_service.dart';
import '../theme/app_dimens.dart';
import '../theme/semantic_colors.dart';
import '../widgets/info_callout.dart';
import '../widgets/log_panel.dart';
import '../widgets/wizard_scaffold.dart';

/// Guided AutoCAD removal: review what was found, choose what to remove,
/// watch it happen, confirm.
///
/// Detection already ran on the home screen, so the products arrive as an
/// argument rather than being re-scanned here.
class UninstallWizardScreen extends StatefulWidget {
  const UninstallWizardScreen({
    required this.service,
    required this.detectedProducts,
    super.key,
  });

  final CadService service;
  final List<String> detectedProducts;

  @override
  State<UninstallWizardScreen> createState() => _UninstallWizardScreenState();
}

class _UninstallWizardScreenState extends State<UninstallWizardScreen> {
  static const _steps = ['Review', 'Options', 'Remove', 'Complete'];

  int currentStep = 0;
  bool removeRegistry = false;
  bool removeAppData = false;
  bool isProcessing = false;
  bool isDone = false;
  String? errorMessage;
  final List<String> logs = [];

  CadService get service => widget.service;

  void _addLog(String message) {
    if (!mounted) return;
    setState(() => logs.add(message));
  }

  Future<void> _performUninstall() async {
    service.onLog = _addLog;

    setState(() {
      isProcessing = true;
      errorMessage = null;
      currentStep = 2;
      logs
        ..clear()
        ..add('Backend: ${service.backendName}')
        ..add('Starting AutoCAD uninstallation...')
        ..add('');
    });

    try {
      _addLog('Step 1/4: Uninstalling AutoCAD products...');
      await service.uninstallProducts(widget.detectedProducts);
      _addLog('✓ Uninstallation complete');
      _addLog('');

      _addLog('Step 2/4: Removing AutoCAD files...');
      await service.removeDirectories();
      _addLog('✓ Files removed');
      _addLog('');

      if (removeRegistry) {
        _addLog('Step 3/4: Cleaning registry...');
        await service.cleanRegistry();
        _addLog('✓ Registry cleaned');
      } else {
        _addLog('Step 3/4: Skipping registry cleanup');
      }
      _addLog('');

      if (removeAppData) {
        _addLog('Step 4/4: Removing user data...');
        await service.removeAppData();
        _addLog('✓ User data removed');
      } else {
        _addLog('Step 4/4: Skipping user data removal');
      }

      if (!mounted) return;
      setState(() {
        isProcessing = false;
        isDone = true;
        currentStep = 3;
        logs
          ..add('')
          ..add('═════════════════════════════════════')
          ..add('✓ AutoCAD uninstallation complete!')
          ..add('═════════════════════════════════════')
          ..add('')
          ..add('A system restart is recommended.');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isProcessing = false;
        errorMessage = e is CadServiceException ? e.message : '$e';
        logs
          ..add('')
          ..add('✗ Error: $errorMessage');
      });
    }
  }

  Future<void> _confirmAndUninstall() async {
    final scheme = Theme.of(context).colorScheme;
    final danger = context.semantic.danger;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: danger.fg, size: 28),
        title: const Text('Confirm Uninstallation'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This will remove:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text('• All AutoCAD products'),
              const Text('• AutoCAD program files'),
              if (removeRegistry) const Text('• AutoCAD registry entries'),
              if (removeAppData)
                const Text('• AutoCAD user settings and licenses'),
              const SizedBox(height: AppSpacing.lg),
              if (service.isSimulated)
                InfoCallout(
                  role: SemanticRole.simulation,
                  child: const Text(
                    'Simulation mode: nothing will actually be removed.',
                  ),
                )
              else
                InfoCallout(
                  role: SemanticRole.danger,
                  child: const Text(
                    'This action cannot be undone.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          // Destructive confirmation stays a solid, full-emphasis error fill.
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _performUninstall();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      title: 'Uninstall AutoCAD',
      service: service,
      stepLabels: _steps,
      currentStep: currentStep,
      // Leaving mid-removal would orphan the log.
      allowBack: !isProcessing,
      body: switch (currentStep) {
        0 => _buildReviewStep(),
        1 => _buildOptionsStep(),
        2 => _buildProcessingStep(),
        _ => _buildCompleteStep(),
      },
      navigationBar: _buildNavigationBar(),
    );
  }

  List<Widget> _buildReviewStep() {
    final theme = Theme.of(context);

    return [
      Text('Review Installations', style: theme.textTheme.headlineSmall),
      const SizedBox(height: AppSpacing.md),
      Text(
        'These AutoCAD products were found on your system and will be removed:',
        style: theme.textTheme.bodyLarge,
      ),
      const SizedBox(height: AppSpacing.lg),
      // Deliberately neutral, not success-green: this is a list of things about
      // to be destroyed, and green would read as reassurance.
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final product in widget.detectedProducts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(product, style: theme.textTheme.bodyLarge),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      // Irreversibility is danger-severity, not caution-severity.
      InfoCallout(
        role: SemanticRole.danger,
        child: const Text(
          'This action cannot be undone. Make sure you have backups of any '
          'important AutoCAD files or settings before proceeding.',
        ),
      ),
    ];
  }

  List<Widget> _buildOptionsStep() {
    final theme = Theme.of(context);

    return [
      Text('Removal Options', style: theme.textTheme.headlineSmall),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Select what you would like to remove:',
        style: theme.textTheme.bodyLarge,
      ),
      const SizedBox(height: AppSpacing.lg),
      Card(
        child: Column(
          children: [
            CheckboxListTile(
              title: const Text('Remove Registry Entries'),
              subtitle: const Text(
                'Clean all AutoCAD related registry keys and values',
              ),
              value: removeRegistry,
              onChanged: (value) =>
                  setState(() => removeRegistry = value ?? false),
            ),
            const Divider(),
            CheckboxListTile(
              title: const Text('Remove User Data & Licenses'),
              subtitle: const Text(
                'Delete AutoCAD settings, preferences, and license information',
              ),
              value: removeAppData,
              onChanged: (value) =>
                  setState(() => removeAppData = value ?? false),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      InfoCallout(
        role: SemanticRole.info,
        child: const Text(
          'All AutoCAD program files will be removed regardless of these '
          'selections.',
        ),
      ),
    ];
  }

  List<Widget> _buildProcessingStep() {
    final theme = Theme.of(context);

    return [
      Row(
        children: [
          Text('Uninstalling AutoCAD', style: theme.textTheme.headlineSmall),
          const SizedBox(width: AppSpacing.lg),
          if (isProcessing)
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
                'Uninstall failed',
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
              'Uninstallation Complete',
              style: theme.textTheme.headlineSmall?.copyWith(color: success.fg),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      InfoCallout(
        role: SemanticRole.warning,
        child: const Text(
          'A system restart is recommended to complete the removal process.',
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      LogPanel(lines: logs, height: 220),
    ];
  }

  Widget _buildNavigationBar() {
    final scheme = Theme.of(context).colorScheme;

    return WizardNavigationBar(
      leading: TextButton(
        onPressed: isProcessing || isDone
            ? null
            : () {
                if (currentStep == 0) {
                  Navigator.of(context).pop();
                } else {
                  setState(() => currentStep--);
                }
              },
        child: Text(currentStep == 0 ? 'Cancel' : 'Back'),
      ),
      trailing: switch (currentStep) {
        0 => FilledButton(
            onPressed: () => setState(() => currentStep = 1),
            child: const Text('Next'),
          ),
        1 => FilledButton.icon(
            onPressed: _confirmAndUninstall,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Uninstall'),
          ),
        2 => errorMessage != null
            ? FilledButton.icon(
                onPressed: _performUninstall,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              )
            : const FilledButton(
                onPressed: null,
                child: Text('Processing...'),
              ),
        _ => FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
      },
    );
  }
}
