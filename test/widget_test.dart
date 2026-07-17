import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cad_cleaner/cad/mock_cad_service.dart';
import 'package:cad_cleaner/main.dart';

/// The wizard is a desktop app; the default 800x600 test viewport clips the
/// cards, so give it a window closer to the real thing.
void useDesktopWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Pumps the app and waits for the home screen's startup checks to finish.
Future<void> pumpHome(WidgetTester tester) async {
  useDesktopWindow(tester);
  await tester.pumpWidget(CadCleanerApp(service: MockCadService()));
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

void main() {
  group('home screen', () {
    testWidgets('checks both products automatically on open',
        (WidgetTester tester) async {
      useDesktopWindow(tester);
      await tester.pumpWidget(CadCleanerApp(service: MockCadService()));

      // Both checks are in flight before any interaction.
      expect(
        find.text('Checking whether AutoCAD is installed...'),
        findsOneWidget,
      );
      expect(
        find.text('Checking whether GstarCAD is installed...'),
        findsOneWidget,
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Installed — 4 product(s) found'), findsOneWidget);
      expect(
        find.text('Not installed — installer not downloaded'),
        findsOneWidget,
      );
    });

    testWidgets('shows only the two status cards and their buttons',
        (WidgetTester tester) async {
      await pumpHome(tester);

      expect(find.text('AutoCAD'), findsOneWidget);
      expect(find.text('GstarCAD'), findsOneWidget);
      expect(find.text('Start Uninstall Wizard'), findsOneWidget);
      expect(find.text('Start Install Wizard'), findsOneWidget);

      // Wizard content lives behind the buttons, not on the landing screen.
      expect(find.text('Removal Options'), findsNothing);
      expect(find.text('Review Installations'), findsNothing);
    });

    testWidgets('discloses the simulated backend', (WidgetTester tester) async {
      await pumpHome(tester);

      expect(
        find.textContaining('Simulated (no changes are made)'),
        findsOneWidget,
      );
    });
  });

  group('uninstall wizard', () {
    testWidgets('runs through to completion', (WidgetTester tester) async {
      await pumpHome(tester);

      await tester.tap(find.text('Start Uninstall Wizard'));
      await tester.pumpAndSettle();
      expect(find.text('Review Installations'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Removal Options'), findsOneWidget);

      await tester.tap(find.text('Uninstall'));
      await tester.pumpAndSettle();

      // Destructive work is gated behind a confirmation.
      expect(find.text('Confirm Uninstallation'), findsOneWidget);
      await tester.tap(find.text('Proceed'));
      await tester.pumpAndSettle(const Duration(seconds: 30));

      expect(find.text('Uninstallation Complete'), findsOneWidget);
    });

    testWidgets('removed products are gone from the home card afterwards',
        (WidgetTester tester) async {
      await pumpHome(tester);
      expect(find.text('Installed — 4 product(s) found'), findsOneWidget);

      await tester.tap(find.text('Start Uninstall Wizard'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uninstall'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Proceed'));
      await tester.pumpAndSettle(const Duration(seconds: 30));

      // Returning home re-scans; the uninstalled products must not reappear.
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Not installed'), findsOneWidget);
      expect(find.text('Installed — 4 product(s) found'), findsNothing);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Start Uninstall Wizard'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('is unreachable when no AutoCAD is installed',
        (WidgetTester tester) async {
      useDesktopWindow(tester);
      await tester
          .pumpWidget(CadCleanerApp(service: _EmptyMockCadService()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Not installed'), findsOneWidget);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Start Uninstall Wizard'),
      );
      expect(button.onPressed, isNull);
    });
  });

  group('install wizard', () {
    testWidgets('downloads, launches, and updates the home card',
        (WidgetTester tester) async {
      await pumpHome(tester);

      await tester.tap(find.text('Start Install Wizard'));
      await tester.pumpAndSettle();
      expect(find.text('Install GstarCAD 2027'), findsOneWidget);

      await tester.tap(find.text('Download & Install'));
      await tester.pumpAndSettle(const Duration(seconds: 30));
      expect(find.text('Installer Launched'), findsOneWidget);

      // Returning home re-checks, so the card reflects the install.
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(
        find.text('Installed — GstarCAD 2027 (simulated)'),
        findsOneWidget,
      );
      expect(find.text('Reinstall GstarCAD'), findsOneWidget);
    });

    testWidgets('skips the download when an installer is already on disk',
        (WidgetTester tester) async {
      useDesktopWindow(tester);
      await tester
          .pumpWidget(CadCleanerApp(service: _PreDownloadedMockCadService()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(
        find.text('Not installed — installer already downloaded'),
        findsOneWidget,
      );

      await tester.tap(find.text('Start Install Wizard'));
      await tester.pumpAndSettle();

      expect(find.text('Installer already downloaded'), findsOneWidget);
      // The button offers to run it rather than re-fetch it.
      expect(find.text('Run Installer'), findsOneWidget);

      await tester.tap(find.text('Run Installer'));
      await tester.pumpAndSettle(const Duration(seconds: 30));

      expect(find.text('Installer Launched'), findsOneWidget);
      expect(
        find.textContaining('Using the installer already downloaded'),
        findsOneWidget,
      );
    });
  });
}

/// A system with no AutoCAD installed.
class _EmptyMockCadService extends MockCadService {
  @override
  Future<List<String>> detectInstallations() async => [];
}

/// A system where the GstarCAD installer was already fetched.
class _PreDownloadedMockCadService extends MockCadService {
  @override
  Future<String?> findDownloadedInstaller() async =>
      '/tmp/GstarCAD2027EN_SP1_x64.exe';
}
