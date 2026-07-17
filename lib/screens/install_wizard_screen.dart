import 'package:flutter/material.dart';

import '../cad/cad_service.dart';
import '../theme/app_dimens.dart';
import '../theme/semantic_colors.dart';
import '../widgets/info_callout.dart';
import '../widgets/log_panel.dart';
import '../widgets/wizard_scaffold.dart';

/// Guided GstarCAD install: review the download, fetch it, hand off to the
/// vendor's setup.
///
/// If the installer was already downloaded, the download step is skipped
/// unless the user asks for a fresh copy.
class InstallWizardScreen extends StatefulWidget {
  const InstallWizardScreen({
    required this.service,
    this.downloadedInstallerPath,
    super.key,
  });

  final CadService service;

  /// Path of an installer already on disk, if any.
  final String? downloadedInstallerPath;

  @override
  State<InstallWizardScreen> createState() => _InstallWizardScreenState();
}

class _InstallWizardScreenState extends State<InstallWizardScreen> {
  static const _steps = ['Review', 'Install', 'Complete'];

  int currentStep = 0;
  bool isWorking = false;
  bool isDone = false;
  bool forceRedownload = false;
  String? installerPath;
  final List<String> logs = [];

  CadService get service => widget.service;

  bool get _hasDownload => installerPath != null;

  @override
  void initState() {
    super.initState();
    installerPath = widget.downloadedInstallerPath;
  }

  void _addLog(String message) {
    if (!mounted) return;
    setState(() => logs.add(message));
  }

  Future<void> _runInstall() async {
    service.onLog = _addLog;

    setState(() {
      isWorking = true;
      currentStep = 1;
      logs
        ..clear()
        ..add('Backend: ${service.backendName}');
    });

    try {
      var path = installerPath;

      if (path == null || forceRedownload) {
        path = await service.downloadGstarCadInstaller();
        if (!mounted) return;
        setState(() => installerPath = path);
      } else {
        _addLog('Using the installer already downloaded at $path');
      }

      _addLog('');
      await service.launchGstarCadInstaller(path);

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
        logs
          ..add('')
          ..add('✗ Install failed: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      title: 'Install GstarCAD',
      service: service,
      stepLabels: _steps,
      currentStep: currentStep,
      allowBack: !isWorking,
      body: switch (currentStep) {
        0 => _buildReviewStep(),
        1 => _buildProgressStep(),
        _ => _buildCompleteStep(),
      },
      navigationBar: _buildNavigationBar(),
    );
  }

  List<Widget> _buildReviewStep() {
    final theme = Theme.of(context);

    return [
      Text('Install GstarCAD 2027', style: theme.textTheme.headlineSmall),
      const SizedBox(height: AppSpacing.md),
      Text(
        'GstarCAD is the AutoCAD replacement offered by this wizard. The '
        'installer is downloaded from the vendor:',
        style: theme.textTheme.bodyLarge,
      ),
      const SizedBox(height: AppSpacing.sm),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: AppRadius.smAll,
        ),
        child: SelectableText(
          gstarCadDownloadUrl,
          style: const TextStyle(
            fontFamilyFallback: AppFonts.monoFallback,
            fontSize: 12,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      if (_hasDownload)
        InfoCallout(
          role: SemanticRole.success,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Installer already downloaded',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                installerPath!,
                style: const TextStyle(
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // A plain Checkbox rather than CheckboxListTile: the tile paints
              // its ink on the nearest Material, which this callout hides.
              Row(
                children: [
                  Checkbox(
                    value: forceRedownload,
                    onChanged: (value) =>
                        setState(() => forceRedownload = value ?? false),
                  ),
                  const Expanded(child: Text('Download a fresh copy anyway')),
                ],
              ),
            ],
          ),
        )
      else
        InfoCallout(
          role: SemanticRole.info,
          child: const Text(
            'The download is several hundred MB and may take a while.',
          ),
        ),
      const SizedBox(height: AppSpacing.lg),
      InfoCallout(
        role: SemanticRole.warning,
        child: const Text(
          "Once the download finishes, the vendor's setup window opens and you "
          'complete the installation there. This wizard does not install '
          'GstarCAD unattended.',
        ),
      ),
      if (service.isSimulated) ...[
        const SizedBox(height: AppSpacing.lg),
        InfoCallout(
          role: SemanticRole.simulation,
          child: const Text(
            'Simulation mode: nothing will actually be downloaded or installed.',
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
          Text('Downloading & Launching', style: theme.textTheme.headlineSmall),
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
              'Installer Launched',
              style: theme.textTheme.headlineSmall?.copyWith(color: success.fg),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      InfoCallout(
        role: service.isSimulated ? SemanticRole.simulation : SemanticRole.info,
        child: Text(
          service.isSimulated
              ? 'Simulated: the install was faked, so nothing changed on this '
                  'machine.'
              : 'Follow the GstarCAD setup window to finish installing. Return '
                  'here afterwards and the status will refresh.',
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      LogPanel(lines: logs, height: 220),
    ];
  }

  Widget _buildNavigationBar() {
    return WizardNavigationBar(
      leading: TextButton(
        onPressed:
            isWorking || isDone ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      trailing: switch (currentStep) {
        0 => FilledButton.icon(
            onPressed: _runInstall,
            icon: const Icon(Icons.download, size: 18),
            label: Text(
              _hasDownload && !forceRedownload
                  ? 'Run Installer'
                  : 'Download & Install',
            ),
          ),
        1 => const FilledButton(
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
