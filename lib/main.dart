import 'package:flutter/material.dart';

import 'cad/cad_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(CadCleanerApp(service: CadService.forPlatform()));
}

class CadCleanerApp extends StatelessWidget {
  const CadCleanerApp({required this.service, super.key});

  /// Injected so tests and non-Windows hosts can run against the mock backend.
  final CadService service;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CAD Cleaner',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: HomeScreen(service: service),
    );
  }
}
