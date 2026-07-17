import 'package:flutter/material.dart';

import '../cad/cad_service.dart';
import '../theme/app_dimens.dart';
import '../theme/semantic_colors.dart';
import '../widgets/simulation_banner.dart';
import '../widgets/info_callout.dart';
import 'install_wizard_screen.dart';
import 'remove_gstarcad_screen.dart';
import 'uninstall_wizard_screen.dart';

/// Landing screen: what is installed, and the two wizards that change it.
///
/// Both checks run automatically on open, and again whenever a wizard returns,
/// so the cards always reflect the current system state.
class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.service, super.key});

  final CadService service;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> autocadProducts = [];
  bool isDetectingAutocad = true;

  /// Autodesk registry keys still on the system. Empty means clean.
  List<String> leftoverRegistryKeys = [];

  GstarCadStatus gstarStatus = GstarCadStatus.checking;
  String? gstarProductName;
  String? downloadedInstallerPath;

  CadService get service => widget.service;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    // The home screen reports state rather than narrating it; the wizards own
    // the log panels.
    service.onLog = null;
    await Future.wait([_detectAutocad(), _checkGstarCad()]);
  }

  Future<void> _detectAutocad() async {
    setState(() => isDetectingAutocad = true);
    try {
      final products = await service.detectInstallations();
      // Registry leftovers outlive the products themselves, so this is checked
      // whether or not AutoCAD is still installed.
      final leftovers = await service.findRemainingRegistryKeys();
      if (!mounted) return;
      setState(() {
        autocadProducts = products;
        leftoverRegistryKeys = leftovers;
        isDetectingAutocad = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        autocadProducts = [];
        isDetectingAutocad = false;
      });
    }
  }

  Future<void> _checkGstarCad() async {
    setState(() => gstarStatus = GstarCadStatus.checking);
    try {
      final results = await Future.wait([
        service.detectGstarCad(),
        service.findDownloadedInstaller(),
      ]);
      if (!mounted) return;
      setState(() {
        gstarProductName = results[0];
        downloadedInstallerPath = results[1];
        gstarStatus = gstarProductName == null
            ? GstarCadStatus.notInstalled
            : GstarCadStatus.installed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => gstarStatus = GstarCadStatus.failed);
    }
  }

  Future<void> _openUninstallWizard() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UninstallWizardScreen(
          service: service,
          detectedProducts: autocadProducts,
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _openInstallWizard() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InstallWizardScreen(
          service: service,
          downloadedInstallerPath: downloadedInstallerPath,
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _openRemoveGstarCad() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RemoveGstarCadScreen(
          service: service,
          productName: gstarProductName ?? 'GstarCAD',
        ),
      ),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CAD Cleaner'),
        actions: [
          IconButton(
            tooltip: 'Re-scan',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          if (service.isSimulated) SimulationBanner(service: service),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.contentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAutocadCard(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildGstarCadCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutocadCard() {
    final installed = autocadProducts.isNotEmpty;
    final semantic = context.semantic;

    return _StatusCard(
      title: 'AutoCAD',
      subtitle: 'The CAD suite this tool removes',
      busy: isDetectingAutocad,
      busyLabel: 'Checking whether AutoCAD is installed...',
      icon: installed ? Icons.check_circle : Icons.remove_circle_outline,
      iconColor: installed
          ? semantic.success.fg
          : Theme.of(context).colorScheme.onSurfaceVariant,
      status: installed
          ? 'Installed — ${autocadProducts.length} product(s) found'
          : 'Not installed',
      details: installed ? autocadProducts : const [],
      footer: _buildRegistryCheck(),
      // Nothing to uninstall when nothing was found.
      action: FilledButton.icon(
        onPressed: installed ? _openUninstallWizard : null,
        icon: const Icon(Icons.delete_outline, size: 18),
        label: const Text('Start Uninstall Wizard'),
      ),
    );
  }

  /// Whether the Autodesk registry keys are actually gone.
  ///
  /// Removal runs with -ErrorAction SilentlyContinue, so leftovers are silent
  /// unless something reads the registry back and says so.
  Widget? _buildRegistryCheck() {
    if (isDetectingAutocad) {
      return null;
    }

    final clean = leftoverRegistryKeys.isEmpty;
    return InfoCallout(
      role: clean ? SemanticRole.success : SemanticRole.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            clean
                ? 'Registry clean — no Autodesk keys found'
                : 'Registry not clear — ${leftoverRegistryKeys.length} '
                    'Autodesk key(s) still present',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (!clean) ...[
            const SizedBox(height: AppSpacing.xs),
            for (final key in leftoverRegistryKeys)
              Text(
                key,
                style: const TextStyle(
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: 11,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildGstarCadCard() {
    final semantic = context.semantic;
    final scheme = Theme.of(context).colorScheme;

    if (gstarStatus == GstarCadStatus.failed) {
      return _StatusCard(
        title: 'GstarCAD',
        subtitle: 'The AutoCAD replacement',
        busy: false,
        icon: Icons.error_outline,
        iconColor: semantic.danger.fg,
        status: 'Could not determine GstarCAD status.',
        action: OutlinedButton.icon(
          onPressed: _checkGstarCad,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Retry'),
        ),
      );
    }

    final installed = gstarStatus == GstarCadStatus.installed;
    final downloaded = downloadedInstallerPath != null;

    final String status;
    if (installed) {
      status = 'Installed — ${gstarProductName ?? 'GstarCAD'}';
    } else if (downloaded) {
      status = 'Not installed — installer already downloaded';
    } else {
      status = 'Not installed — installer not downloaded';
    }

    return _StatusCard(
      title: 'GstarCAD',
      subtitle: 'The AutoCAD replacement',
      busy: gstarStatus == GstarCadStatus.checking,
      busyLabel: 'Checking whether GstarCAD is installed...',
      icon: installed ? Icons.check_circle : Icons.download_outlined,
      iconColor: installed ? semantic.success.fg : scheme.primary,
      status: status,
      details: [
        if (downloaded) downloadedInstallerPath!,
      ],
      detailsAreMonospace: true,
      // Removal is only offered for something actually installed.
      secondaryAction: installed
          ? OutlinedButton.icon(
              onPressed: _openRemoveGstarCad,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Remove GstarCAD'),
            )
          : null,
      action: FilledButton.icon(
        onPressed: _openInstallWizard,
        icon: Icon(installed ? Icons.refresh : Icons.download, size: 18),
        label: Text(installed ? 'Reinstall GstarCAD' : 'Start Install Wizard'),
      ),
    );
  }
}

/// One product's state plus the button that acts on it.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.icon,
    required this.iconColor,
    required this.status,
    required this.action,
    this.busyLabel,
    this.details = const [],
    this.detailsAreMonospace = false,
    this.footer,
    this.secondaryAction,
  });

  final String title;
  final String subtitle;
  final bool busy;
  final String? busyLabel;
  final IconData icon;
  final Color iconColor;
  final String status;
  final List<String> details;
  final bool detailsAreMonospace;

  /// Extra content below the status, above the actions.
  final Widget? footer;

  /// Lower-emphasis action shown left of [action].
  final Widget? secondaryAction;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            if (busy)
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      busyLabel ?? 'Checking...',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              )
            else ...[
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(status, style: theme.textTheme.bodyLarge),
                  ),
                ],
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final detail in details)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            detail,
                            style: detailsAreMonospace
                                ? theme.textTheme.labelSmall?.copyWith(
                                    fontFamilyFallback: AppFonts.monoFallback,
                                  )
                                : theme.textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
            if (footer != null) ...[
              const SizedBox(height: AppSpacing.lg),
              footer!,
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (secondaryAction != null) ...[
                  secondaryAction!,
                  const SizedBox(width: AppSpacing.md),
                ],
                action,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
