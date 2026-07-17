import 'dart:io';

import 'package:process/process.dart';

import 'cad_service.dart';
import 'uninstall_command.dart';

/// Performs real removal of AutoCAD and real installation of GstarCAD via
/// PowerShell and the Windows registry.
///
/// Every removal operation here is destructive and irreversible.
class WindowsCadService extends CadService {
  WindowsCadService({super.onLog});

  final ProcessManager _processManager = const LocalProcessManager();

  @override
  bool get isSimulated => false;

  @override
  String get backendName => 'Windows (live)';

  static const _uninstallRegistryPaths = [
    r'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall',
    r'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
  ];

  // --- AutoCAD removal ---

  @override
  Future<List<String>> detectInstallations() =>
      _findProductsMatching('*AutoCAD*', alsoMatch: '*Autodesk*');

  @override
  Future<void> uninstallProducts(List<String> products) async {
    if (products.isEmpty) {
      return;
    }

    // Kill any running AutoCAD processes so files aren't locked.
    await _runCommand('taskkill', ['/F', '/IM', 'acad.exe']);
    await _runCommand('taskkill', ['/F', '/IM', 'accoread.exe']);

    final failures = <String>[];

    for (final product in products) {
      log('Uninstalling $product...');
      final reason = await _uninstallOne(product);
      if (reason == null) {
        log('  ✓ $product removed');
      } else {
        log('  ✗ $product: $reason');
        failures.add(product);
      }
    }

    // Reporting "complete" while products remain would be a lie; the wizard
    // shows this as a failure with the log alongside it.
    if (failures.isNotEmpty) {
      throw CadServiceException(
        failures.length == products.length
            ? 'None of the AutoCAD products could be uninstalled. See the log '
                'for what each one reported.'
            : 'These products could not be uninstalled: ${failures.join(', ')}. '
                'The rest were removed. See the log for details.',
      );
    }
  }

  /// Uninstalls one product. Returns null on success, or a reason on failure.
  Future<String?> _uninstallOne(String product) async {
    final raw = await _readUninstallString(product);
    if (raw == null || raw.isEmpty) {
      return 'no uninstall entry found in the registry';
    }

    final command = parseUninstallString(raw);
    if (command == null) {
      return 'could not interpret its uninstall command ($raw)';
    }

    log('  running ${command.executable}');

    // Start-Process takes the executable and arguments separately, so a path
    // containing spaces needs no quoting gymnastics. The old code passed the
    // whole string to `cmd /c`, which split it at the first space and failed
    // with '"C:\Program" is not recognized...'.
    final script = StringBuffer()
      ..write("\$p = Start-Process -FilePath '${_psQuote(command.executable)}'");
    if (command.arguments.isNotEmpty) {
      script.write(" -ArgumentList '${_psQuote(command.arguments)}'");
    }
    script.write(' -Wait -PassThru -ErrorAction Stop; exit \$p.ExitCode');

    final result = await _runPowerShellRaw(script.toString());
    final exitCode = result.exitCode;

    // 0 = done, 3010 = done but wants a reboot, 1605 = already gone.
    if (exitCode == 0 || exitCode == 3010 || exitCode == 1605) {
      return null;
    }
    final details = result.stderr.toString().trim();
    return details.isEmpty ? 'exit code $exitCode' : details;
  }

  /// Returns the product's QuietUninstallString, or UninstallString.
  Future<String?> _readUninstallString(String product) async {
    for (final path in _uninstallRegistryPaths) {
      final result = await _runPowerShell(
        '\$k = Get-ItemProperty "$path\\*" -ErrorAction SilentlyContinue | '
        "Where-Object { \$_.DisplayName -eq '${_psQuote(product)}' } | "
        'Select-Object -First 1; '
        'if (\$k) { if (\$k.QuietUninstallString) { \$k.QuietUninstallString } '
        'else { \$k.UninstallString } }',
      );

      final value = result.trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  /// Escapes a value for a PowerShell single-quoted string.
  String _psQuote(String value) => value.replaceAll("'", "''");

  @override
  Future<void> removeDirectories() => _removeAll([
        r'C:\Program Files\Autodesk',
        r'C:\Program Files (x86)\Autodesk',
        r'C:\ProgramData\Autodesk',
      ]);

  @override
  Future<void> cleanRegistry() async {
    const registryPaths = [
      r'HKLM:\Software\Autodesk',
      r'HKLM:\Software\Wow6432Node\Autodesk',
      r'HKCU:\Software\Autodesk',
      r'HKCU:\Software\Classes\AutoCAD.*',
      r'HKCU:\Software\Classes\.dwg',
      r'HKCU:\Software\Classes\.dxf',
    ];

    for (final path in registryPaths) {
      try {
        log('Removing registry key $path');
        await _runPowerShell(
          'Remove-Item -Path "$path" -Recurse -Force -ErrorAction SilentlyContinue',
        );
      } catch (e) {
        log('Error removing registry $path: $e');
      }
    }
  }

  @override
  Future<void> removeAppData() async {
    final directories = <String>[];

    for (final variable in ['LOCALAPPDATA', 'APPDATA', 'ProgramData']) {
      final base = Platform.environment[variable];
      if (base != null) {
        directories.add('$base\\Autodesk');
      }
    }

    await _removeAll(directories);
  }

  // --- GstarCAD replacement ---

  @override
  Future<String?> detectGstarCad() async {
    final products = await _findProductsMatching('*GstarCAD*');
    return products.isEmpty ? null : products.first;
  }

  String get _installerPath =>
      '${Directory.systemTemp.path}\\$gstarCadInstallerFileName';

  @override
  Future<String?> findDownloadedInstaller() async {
    final file = File(_installerPath);
    if (!file.existsSync()) {
      return null;
    }
    // A truncated file from an interrupted download is worse than no file at
    // all, since it would launch and fail. Treat an empty one as absent.
    if (await file.length() == 0) {
      return null;
    }
    return _installerPath;
  }

  @override
  Future<String> downloadGstarCadInstaller() async {
    final destination = _installerPath;

    log('Downloading GstarCAD from $gstarCadDownloadUrl');
    await _download(gstarCadDownloadUrl, destination);
    log('Download complete: $destination');

    return destination;
  }

  @override
  Future<void> launchGstarCadInstaller(String installerPath) async {
    log('Launching $installerPath');

    // Process.start uses CreateProcess, which cannot elevate: when the target
    // requests admin it fails with "The requested operation requires
    // elevation". ShellExecute's runas verb raises the UAC prompt instead, so
    // this works whether or not we are already elevated.
    // -ErrorAction Stop + try/catch: a failed Start-Process is a
    // non-terminating error by default, so powershell.exe would exit 0 and the
    // failure would go unnoticed.
    final quoted = installerPath.replaceAll("'", "''");
    final result = await _processManager.run([
      'powershell',
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      "try { Start-Process -FilePath '$quoted' -Verb RunAs -ErrorAction Stop } "
          'catch { Write-Error \$_.Exception.Message; exit 1 }',
    ]);

    if (result.exitCode != 0) {
      final details = result.stderr.toString().trim();
      // Declining the UAC prompt is a user choice, not a fault; say so plainly
      // rather than surfacing a raw PowerShell error.
      if (details.contains('canceled') || details.contains('cancelled')) {
        throw const CadServiceException(
          'The Windows elevation prompt was dismissed, so the installer did '
          'not start. Choose "Yes" on that prompt to install GstarCAD.',
        );
      }
      throw CadServiceException(
        'Could not launch the installer.${details.isEmpty ? '' : ' $details'}',
      );
    }

    log('The GstarCAD setup window has taken over — follow its prompts.');
  }

  Future<void> _download(String url, String destination) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Download failed with HTTP ${response.statusCode}',
          uri: Uri.parse(url),
        );
      }

      final total = response.contentLength;
      var received = 0;
      var lastReportedPercent = 0;

      final sink = File(destination).openWrite();
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;

          if (total > 0) {
            final percent = (received / total * 100).floor();
            if (percent >= lastReportedPercent + 10) {
              lastReportedPercent = percent - (percent % 10);
              log('  $lastReportedPercent% (${_megabytes(received)} of ${_megabytes(total)})');
            }
          }
        }
      } finally {
        await sink.close();
      }
    } finally {
      client.close();
    }
  }

  /// Returns DisplayNames from the uninstall registry keys matching a pattern.
  Future<List<String>> _findProductsMatching(
    String pattern, {
    String? alsoMatch,
  }) async {
    final products = <String>[];

    try {
      final condition = alsoMatch == null
          ? '\$_.DisplayName -like "$pattern"'
          : '\$_.DisplayName -like "$pattern" -or \$_.DisplayName -like "$alsoMatch"';

      for (final path in _uninstallRegistryPaths) {
        final result = await _runPowerShell(
          'Get-ItemProperty "$path\\*" -ErrorAction SilentlyContinue | '
          'Where-Object { $condition } | '
          'Select-Object -ExpandProperty DisplayName',
        );

        if (result.isNotEmpty) {
          products.addAll(
            result.split('\n').map((line) => line.trim()).where(
                  (line) => line.isNotEmpty,
                ),
          );
        }
      }

      return products.toSet().toList();
    } catch (e) {
      log('Error querying installed products: $e');
      return [];
    }
  }

  Future<void> _removeAll(List<String> directories) async {
    for (final dir in directories) {
      try {
        if (Directory(dir).existsSync()) {
          log('Removing $dir');
          await _runPowerShell(
            'Remove-Item -Path "$dir" -Recurse -Force -ErrorAction SilentlyContinue',
          );
        }
      } catch (e) {
        log('Error removing directory $dir: $e');
      }
    }
  }

  Future<String> _runPowerShell(String script) async {
    final result = await _runPowerShellRaw(script);
    if (result.exitCode == 0) {
      return result.stdout.toString();
    }
    log('PowerShell error: ${result.stderr}');
    return '';
  }

  /// Runs PowerShell and hands back the raw result, so callers that care about
  /// the exit code can see it rather than getting an empty string.
  Future<ProcessResult> _runPowerShellRaw(String script) async {
    try {
      return await _processManager.run([
        'powershell',
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        script,
      ]);
    } catch (e) {
      log('Error running PowerShell: $e');
      return ProcessResult(0, -1, '', '$e');
    }
  }

  Future<ProcessResult> _runCommand(String executable, List<String> args) async {
    try {
      return await _processManager.run([executable, ...args]);
    } catch (e) {
      log('Error running command: $e');
      return ProcessResult(0, 1, '', 'Error: $e');
    }
  }
}

String _megabytes(int bytes) => '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
