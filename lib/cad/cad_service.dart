import 'dart:io';

import 'package:meta/meta.dart';

import 'mock_cad_service.dart';
import 'windows_cad_service.dart';

/// Receives progress messages emitted while an operation runs.
typedef CadLogger = void Function(String message);

/// Vendor download for the AutoCAD replacement offered by this wizard.
const gstarCadDownloadUrl =
    'https://file.e-disti.com/GstarCAD2027EN_SP1_x64.exe';

const gstarCadInstallerFileName = 'GstarCAD2027EN_SP1_x64.exe';

/// Whether GstarCAD — the AutoCAD replacement — is present on the system.
enum GstarCadStatus { checking, installed, notInstalled, failed }

/// An operation failed for a reason worth showing the user verbatim.
///
/// Carries an actionable message, unlike a raw ProcessException.
class CadServiceException implements Exception {
  const CadServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Everything the wizard does to the host system, independent of how it is
/// carried out.
///
/// Windows gets [WindowsCadService], which really removes and installs things.
/// Every other platform gets [MockCadService] so the wizard can be developed
/// and demoed without a Windows machine.
abstract class CadService {
  CadService({this.onLog});

  /// Returns the implementation appropriate for the host platform.
  factory CadService.forPlatform({CadLogger? onLog}) {
    if (Platform.isWindows) {
      return WindowsCadService(onLog: onLog);
    }
    return MockCadService(onLog: onLog);
  }

  /// Where progress messages go. Each screen points this at its own log panel
  /// before starting an operation, since one service is shared app-wide.
  CadLogger? onLog;

  /// Whether operations are simulated rather than actually performed.
  ///
  /// The UI surfaces this so a simulated run is never mistaken for a real one.
  bool get isSimulated;

  /// Human-readable name of the backend, shown in the UI.
  String get backendName;

  @protected
  void log(String message) => onLog?.call(message);

  // --- AutoCAD removal ---

  Future<List<String>> detectInstallations();

  Future<void> uninstallProducts(List<String> products);

  Future<void> removeDirectories();

  Future<void> cleanRegistry();

  Future<void> removeAppData();

  // --- GstarCAD replacement ---

  /// Returns the installed GstarCAD product name, or null if not installed.
  Future<String?> detectGstarCad();

  /// Returns the path of an already-downloaded installer, or null if the
  /// installer has not been downloaded yet.
  Future<String?> findDownloadedInstaller();

  /// Downloads the vendor installer and returns its path.
  Future<String> downloadGstarCadInstaller();

  /// Launches a downloaded installer. The vendor's setup UI takes over from
  /// there; this does not attempt an unattended install.
  Future<void> launchGstarCadInstaller(String installerPath);
}
