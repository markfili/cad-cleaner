import 'dart:io';

import 'package:process/process.dart';

import 'cad_service.dart';

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

    try {
      // Kill any running AutoCAD processes so files aren't locked.
      await _runCommand('taskkill', ['/F', '/IM', 'acad.exe']);
      await _runCommand('taskkill', ['/F', '/IM', 'accoread.exe']);

      for (final product in products) {
        log('Uninstalling $product...');
        for (final path in _uninstallRegistryPaths) {
          final psScript = '''
            \$key = Get-ItemProperty "$path\\*" -ErrorAction SilentlyContinue |
                    Where-Object { \$_.DisplayName -eq "$product" }

            if (\$key) {
              \$uninstallString = \$key.UninstallString
              if (\$uninstallString -like "MsiExec.exe*") {
                \$productCode = \$uninstallString -replace 'MsiExec.exe /X', '' -replace ' /.*', ''
                & MsiExec.exe /X\$productCode /qn
              } elseif (\$uninstallString) {
                & cmd /c "\$uninstallString"
              }
            }
          ''';

          await _runPowerShell(psScript);
        }
      }
    } catch (e) {
      log('Error uninstalling products: $e');
    }
  }

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
    await _processManager.start([installerPath]);
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
    try {
      final result = await _processManager.run([
        'powershell',
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        script,
      ]);

      if (result.exitCode == 0) {
        return result.stdout.toString();
      }
      log('PowerShell error: ${result.stderr}');
      return '';
    } catch (e) {
      log('Error running PowerShell: $e');
      return '';
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
