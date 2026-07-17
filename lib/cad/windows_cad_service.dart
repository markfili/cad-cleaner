import 'dart:convert';
import 'dart:io';

import 'package:process/process.dart';

import 'cad_service.dart';
import 'registry_product.dart';
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

  /// Uninstall commands captured during detection, keyed by display name.
  ///
  /// The uninstall string is captured up front rather than looked up again by
  /// name later: the name is only a label, and round-tripping it through
  /// PowerShell's text output corrupts anything long or non-ASCII, which then
  /// matches nothing.
  final Map<String, String?> _uninstallStringsByName = {};

  @override
  Future<List<String>> detectInstallations() async {
    final products = await _queryProducts(
      "\$_.DisplayName -like '*AutoCAD*' -or \$_.DisplayName -like '*Autodesk*'",
    );

    _uninstallStringsByName
      ..clear()
      ..addEntries(
        products.map((p) => MapEntry(p.displayName, p.uninstallString)),
      );

    return _uninstallStringsByName.keys.toList();
  }

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
    // Populate the cache if the wizard was reached without a scan.
    if (_uninstallStringsByName.isEmpty) {
      await detectInstallations();
    }

    if (!_uninstallStringsByName.containsKey(product)) {
      return 'no registry entry matches this name any more — re-scan and try '
          'again';
    }

    return _runUninstallCommand(_uninstallStringsByName[product]);
  }

  /// Runs one uninstall command. Returns null on success, or a reason.
  Future<String?> _runUninstallCommand(String? raw) async {
    if (raw == null || raw.isEmpty) {
      // The entry exists but offers no command. Saying "not found" here would
      // send the user looking for the wrong problem.
      return 'its registry entry has no uninstall command, so it has to be '
          'removed with its own installer';
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

  /// Queries the uninstall registry keys for entries matching a PowerShell
  /// condition, returning name *and* uninstall command together.
  ///
  /// The result goes to a UTF-8 file as JSON rather than coming back on
  /// stdout. PowerShell formats console output for a display: it wraps long
  /// lines (~120 columns when redirected) and re-encodes text through the
  /// console codepage, both of which silently corrupt product names.
  Future<List<RegistryProduct>> _queryProducts(String condition) async {
    final outputPath =
        '${Directory.systemTemp.path}\\cad_cleaner_registry_query.json';
    final paths = _uninstallRegistryPaths.map((p) => "'$p'").join(',');

    final script = "\$ErrorActionPreference = 'SilentlyContinue'; "
        '\$items = @(); '
        'foreach (\$p in @($paths)) { '
        '  \$items += Get-ItemProperty "\$p\\*" | '
        '    Where-Object { $condition } | '
        '    Select-Object DisplayName, DisplayVersion, UninstallString, QuietUninstallString '
        '}; '
        'ConvertTo-Json -InputObject @(\$items) -Compress -Depth 3 | '
        "Set-Content -LiteralPath '${_psQuote(outputPath)}' -Encoding UTF8";

    final result = await _runPowerShellRaw(script);
    if (result.exitCode != 0) {
      log('Registry query failed: ${result.stderr}');
      return [];
    }

    final file = File(outputPath);
    if (!file.existsSync()) {
      log('Registry query produced no output.');
      return [];
    }

    try {
      return parseRegistryProductsJson(await file.readAsString(encoding: utf8));
    } catch (e) {
      log('Could not read the registry query output: $e');
      return [];
    } finally {
      try {
        file.deleteSync();
      } catch (_) {
        // A leftover temp file is not worth failing the scan over.
      }
    }
  }

  /// Escapes a value for a PowerShell single-quoted string.
  String _psQuote(String value) => value.replaceAll("'", "''");

  @override
  Future<void> removeDirectories() => _removeAll([
        r'C:\Program Files\Autodesk',
        r'C:\Program Files (x86)\Autodesk',
        r'C:\ProgramData\Autodesk',
      ]);

  static const _autodeskRegistryKeys = [
    r'HKLM:\Software\Autodesk',
    r'HKLM:\Software\Wow6432Node\Autodesk',
    r'HKCU:\Software\Autodesk',
    r'HKCU:\Software\Classes\AutoCAD.*',
    r'HKCU:\Software\Classes\.dwg',
    r'HKCU:\Software\Classes\.dxf',
  ];

  @override
  Future<void> cleanRegistry() async {
    for (final path in _autodeskRegistryKeys) {
      log('Removing registry key $path');
      await _runPowerShell(
        'Remove-Item -Path "$path" -Recurse -Force -ErrorAction SilentlyContinue',
      );
    }

    // Remove-Item ran with -ErrorAction SilentlyContinue, so it reports nothing
    // whether it worked or not. Read the registry back and see.
    log('Verifying the registry keys are gone...');
    final remaining = await findRemainingRegistryKeys();

    if (remaining.isEmpty) {
      log('  ✓ verified: no Autodesk registry keys remain');
      return;
    }

    for (final key in remaining) {
      log('  ✗ still present: $key');
    }
    throw CadServiceException(
      'The registry was not fully cleared — ${remaining.length} key(s) are '
      'still present: ${remaining.join(', ')}. They may be held by a running '
      'process, or need permissions this account does not have.',
    );
  }

  @override
  Future<List<String>> findRemainingRegistryKeys() async {
    final remaining = <String>[];

    for (final path in _autodeskRegistryKeys) {
      // A marker rather than Test-Path's `True`/`False`, so a localised or
      // unexpected PowerShell response can't read as a false negative.
      final result = await _runPowerShell(
        'if (Test-Path -Path "$path") { Write-Output "PRESENT" }',
      );
      if (result.contains('PRESENT')) {
        remaining.add(path);
      }
    }

    return remaining;
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
    final products =
        await _queryProducts("\$_.DisplayName -like '*GstarCAD*'");
    return products.isEmpty ? null : products.first.displayName;
  }

  @override
  Future<void> uninstallGstarCad() async {
    final products = await _queryProducts("\$_.DisplayName -like '*GstarCAD*'");

    if (products.isEmpty) {
      throw const CadServiceException(
        'No GstarCAD installation was found in the registry, so there is '
        'nothing to remove.',
      );
    }

    final failures = <String>[];
    for (final product in products) {
      log('Uninstalling ${product.displayName}...');
      final reason = await _runUninstallCommand(product.uninstallString);
      if (reason == null) {
        log('  ✓ ${product.displayName} removed');
      } else {
        log('  ✗ ${product.displayName}: $reason');
        failures.add(product.displayName);
      }
    }

    if (failures.isNotEmpty) {
      throw CadServiceException(
        'GstarCAD could not be fully removed: ${failures.join(', ')}. See the '
        'log for what each one reported.',
      );
    }
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
