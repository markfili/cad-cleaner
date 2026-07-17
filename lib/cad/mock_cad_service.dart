import 'cad_service.dart';

/// Simulates every operation with realistic delays and log output.
///
/// Used on macOS and Linux so the wizard can be developed and demoed without a
/// Windows machine. Nothing is read from or written to the host system.
class MockCadService extends CadService {
  MockCadService({super.onLog});

  /// Pretend AutoCAD products found on the fake system.
  static const _fakeProducts = [
    'AutoCAD 2024 - English',
    'AutoCAD Mechanical 2024',
    'Autodesk Civil 3D 2024',
    'Autodesk Revit 2023',
  ];

  static const _fakeDirectories = [
    r'C:\Program Files\Autodesk',
    r'C:\Program Files (x86)\Autodesk',
    r'C:\ProgramData\Autodesk',
  ];

  static const _fakeRegistryKeys = [
    r'HKLM:\Software\Autodesk',
    r'HKLM:\Software\Wow6432Node\Autodesk',
    r'HKCU:\Software\Autodesk',
    r'HKCU:\Software\Classes\.dwg',
    r'HKCU:\Software\Classes\.dxf',
  ];

  static const _fakeAppDataDirectories = [
    r'C:\Users\Demo\AppData\Local\Autodesk',
    r'C:\Users\Demo\AppData\Roaming\Autodesk',
    r'C:\ProgramData\Autodesk',
  ];

  /// The fake system's current state, mutated by the simulated operations so a
  /// demo run reflects what the wizards did.
  final List<String> _installedProducts = List.of(_fakeProducts);
  bool _gstarCadDownloaded = false;
  bool _gstarCadInstalled = false;

  @override
  bool get isSimulated => true;

  @override
  String get backendName => 'Simulated (no changes are made)';

  @override
  Future<List<String>> detectInstallations() async {
    await _pause(900);
    log('Querying uninstall registry keys...');
    await _pause(700);
    return List.of(_installedProducts);
  }

  @override
  Future<void> uninstallProducts(List<String> products) async {
    if (products.isEmpty) {
      return;
    }

    log('Closing running AutoCAD processes...');
    await _pause(600);

    for (final product in products) {
      log('Uninstalling $product...');
      await _pause(800);
      // Actually drop it, so a later scan reports it gone.
      _installedProducts.remove(product);
    }
  }

  @override
  Future<void> removeDirectories() async {
    for (final dir in _fakeDirectories) {
      log('Removing $dir');
      await _pause(500);
    }
  }

  @override
  Future<void> cleanRegistry() async {
    for (final key in _fakeRegistryKeys) {
      log('Removing registry key $key');
      await _pause(350);
    }
  }

  @override
  Future<void> removeAppData() async {
    for (final dir in _fakeAppDataDirectories) {
      log('Removing $dir');
      await _pause(400);
    }
  }

  @override
  Future<String?> detectGstarCad() async {
    await _pause(700);
    return _gstarCadInstalled ? 'GstarCAD 2027 (simulated)' : null;
  }

  static const _fakeInstallerPath = '/tmp/$gstarCadInstallerFileName';
  static const _fakeTotalBytes = 780 * 1024 * 1024;

  @override
  Future<String?> findDownloadedInstaller() async {
    await _pause(300);
    return _gstarCadDownloaded ? _fakeInstallerPath : null;
  }

  @override
  Future<String> downloadGstarCadInstaller() async {
    log('Downloading GstarCAD from $gstarCadDownloadUrl');
    for (var percent = 10; percent <= 100; percent += 10) {
      await _pause(300);
      final received = _fakeTotalBytes * percent ~/ 100;
      log('  $percent% (${_megabytes(received)} of ${_megabytes(_fakeTotalBytes)})');
    }
    _gstarCadDownloaded = true;
    log('Download complete: $_fakeInstallerPath');
    log('(Simulated — nothing was actually downloaded.)');

    return _fakeInstallerPath;
  }

  @override
  Future<void> launchGstarCadInstaller(String installerPath) async {
    log('Launching $installerPath');
    await _pause(900);
    _gstarCadInstalled = true;
    log('Simulated install finished — nothing was actually run.');
  }

  Future<void> _pause(int milliseconds) =>
      Future<void>.delayed(Duration(milliseconds: milliseconds));
}

String _megabytes(int bytes) => '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
