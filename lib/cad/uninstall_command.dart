/// An uninstall registry entry parsed into something safely launchable.
///
/// Lives apart from [WindowsCadService] so the parsing can be tested off
/// Windows — it is the part that gets subtly wrong, and the part that broke.
class UninstallCommand {
  const UninstallCommand({required this.executable, this.arguments = ''});

  /// Full path to the executable, without surrounding quotes.
  final String executable;

  /// Everything after the executable, passed through verbatim. May be empty.
  final String arguments;

  @override
  String toString() =>
      arguments.isEmpty ? executable : '$executable $arguments';

  @override
  bool operator ==(Object other) =>
      other is UninstallCommand &&
      other.executable == executable &&
      other.arguments == arguments;

  @override
  int get hashCode => Object.hash(executable, arguments);
}

final _msiProductCode = RegExp(
  r'\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}',
);

/// `"C:\Path With Spaces\setup.exe" /S`
final _quotedExecutable = RegExp(r'^"([^"]+)"\s*(.*)$');

/// `C:\Program Files\Autodesk\...\Setup.exe --uninstall`
///
/// Non-greedy up to the first `.exe`, because the path is frequently unquoted
/// *and* contains spaces — splitting on whitespace yields `C:\Program`, which
/// is what the old `cmd /c "$uninstallString"` choked on.
final _unquotedExecutable = RegExp(r'^(.*?\.exe)\s*(.*)$', caseSensitive: false);

/// Turns a registry UninstallString into an executable plus arguments.
///
/// Returns null when the string can't be understood, so the caller can report
/// that rather than running something unpredictable.
UninstallCommand? parseUninstallString(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return null;
  }

  // MSI entries are rewritten to a quiet, no-restart uninstall. Matching the
  // product code directly handles /X, /x and /I spellings without caring which.
  final productCode = _msiProductCode.firstMatch(value);
  if (productCode != null && value.toLowerCase().contains('msiexec')) {
    return UninstallCommand(
      executable: 'msiexec.exe',
      arguments: '/x ${productCode.group(0)} /qn /norestart',
    );
  }

  final quoted = _quotedExecutable.firstMatch(value);
  if (quoted != null) {
    return UninstallCommand(
      executable: quoted.group(1)!,
      arguments: quoted.group(2)!.trim(),
    );
  }

  final unquoted = _unquotedExecutable.firstMatch(value);
  if (unquoted != null) {
    return UninstallCommand(
      executable: unquoted.group(1)!,
      arguments: unquoted.group(2)!.trim(),
    );
  }

  return null;
}
