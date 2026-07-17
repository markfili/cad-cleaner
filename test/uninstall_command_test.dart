import 'package:flutter_test/flutter_test.dart';

import 'package:cad_cleaner/cad/uninstall_command.dart';

void main() {
  group('parseUninstallString', () {
    test('handles an unquoted path containing spaces', () {
      // The real-world Autodesk shape, and the one that broke: passing this to
      // `cmd /c` made cmd treat "C:\Program" as the command.
      final command = parseUninstallString(
        r'C:\Program Files\Autodesk\AdODIS\V1\Setup.exe --uninstall -q',
      );

      expect(
        command,
        const UninstallCommand(
          executable: r'C:\Program Files\Autodesk\AdODIS\V1\Setup.exe',
          arguments: '--uninstall -q',
        ),
      );
      // The path must survive intact — not truncated at the first space.
      expect(command!.executable, contains('Program Files'));
    });

    test('handles a quoted path containing spaces', () {
      expect(
        parseUninstallString(
          r'"C:\Program Files (x86)\Autodesk\Uninstall.exe" /S',
        ),
        const UninstallCommand(
          executable: r'C:\Program Files (x86)\Autodesk\Uninstall.exe',
          arguments: '/S',
        ),
      );
    });

    test('handles an executable with no arguments', () {
      expect(
        parseUninstallString(r'C:\Program Files\Foo\uninst.exe'),
        const UninstallCommand(
          executable: r'C:\Program Files\Foo\uninst.exe',
        ),
      );
    });

    test('rewrites MSI entries to a quiet, no-restart uninstall', () {
      expect(
        parseUninstallString(
          'MsiExec.exe /X{5783F2D7-2001-0407-0000-0060B0CE6BBA}',
        ),
        const UninstallCommand(
          executable: 'msiexec.exe',
          arguments: '/x {5783F2D7-2001-0407-0000-0060B0CE6BBA} /qn /norestart',
        ),
      );
    });

    test('accepts the /I and lowercase /x spellings of MSI entries', () {
      for (final raw in [
        'MsiExec.exe /I{5783F2D7-2001-0407-0000-0060B0CE6BBA}',
        'msiexec.exe /x{5783F2D7-2001-0407-0000-0060B0CE6BBA}',
        r'C:\Windows\System32\MsiExec.exe /X{5783F2D7-2001-0407-0000-0060B0CE6BBA}',
      ]) {
        final command = parseUninstallString(raw);
        expect(command?.executable, 'msiexec.exe', reason: raw);
        expect(command?.arguments, contains('/qn'), reason: raw);
        expect(command?.arguments, contains('/norestart'), reason: raw);
      }
    });

    test('does not mistake a GUID in a plain exe path for an MSI entry', () {
      final command = parseUninstallString(
        r'C:\ProgramData\{5783F2D7-2001-0407-0000-0060B0CE6BBA}\setup.exe /uninstall',
      );

      expect(command?.executable, endsWith(r'\setup.exe'));
      expect(command?.arguments, '/uninstall');
    });

    test('trims surrounding whitespace', () {
      expect(
        parseUninstallString('   C:\\Foo\\uninst.exe /S   '),
        const UninstallCommand(
          executable: r'C:\Foo\uninst.exe',
          arguments: '/S',
        ),
      );
    });

    test('returns null rather than guessing at unusable input', () {
      expect(parseUninstallString(''), isNull);
      expect(parseUninstallString('   '), isNull);
      expect(parseUninstallString('rundll32 shell32.dll,Control_RunDLL'), isNull);
    });
  });
}
