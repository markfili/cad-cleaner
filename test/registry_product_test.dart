import 'package:flutter_test/flutter_test.dart';

import 'package:cad_cleaner/cad/registry_product.dart';

void main() {
  group('parseRegistryProductsJson', () {
    test('reads name and uninstall command together', () {
      final products = parseRegistryProductsJson('''
[{"DisplayName":"AutoCAD 2020","DisplayVersion":"23.1",
  "UninstallString":"C:\\\\Program Files\\\\Autodesk\\\\AdODIS\\\\V1\\\\Setup.exe --uninstall",
  "QuietUninstallString":null}]
''');

      expect(products, hasLength(1));
      expect(products.single.displayName, 'AutoCAD 2020');
      expect(products.single.version, '23.1');
      expect(
        products.single.uninstallString,
        r'C:\Program Files\Autodesk\AdODIS\V1\Setup.exe --uninstall',
      );
    });

    test('prefers QuietUninstallString when the vendor provides one', () {
      final products = parseRegistryProductsJson(
        '[{"DisplayName":"AutoCAD 2020",'
        '"UninstallString":"C:\\\\setup.exe",'
        '"QuietUninstallString":"C:\\\\setup.exe /S"}]',
      );

      expect(products.single.uninstallString, r'C:\setup.exe /S');
    });

    test('keeps non-ASCII names intact', () {
      // Names round-tripped through PowerShell's console codepage came back
      // mangled, so the later name lookup matched nothing. Reading UTF-8 JSON
      // has to preserve them exactly.
      final products = parseRegistryProductsJson(
        '[{"DisplayName":"AutoCAD 2020 – Español","UninstallString":"C:\\\\s.exe"}]',
      );

      expect(products.single.displayName, 'AutoCAD 2020 – Español');
    });

    test('keeps long names intact', () {
      // Console output wraps at ~120 columns, which split long names in two.
      final long = 'Autodesk AutoCAD 2020 - English Language Pack With A Very '
          'Long Marketing Name That Exceeds The Console Width Limit Of About '
          '120 Columns';
      final products = parseRegistryProductsJson(
        '[{"DisplayName":"$long","UninstallString":"C:\\\\s.exe"}]',
      );

      expect(products, hasLength(1));
      expect(products.single.displayName, long);
    });

    test('strips the BOM Windows PowerShell writes', () {
      final products = parseRegistryProductsJson(
        '﻿[{"DisplayName":"AutoCAD 2020","UninstallString":"C:\\\\s.exe"}]',
      );

      expect(products.single.displayName, 'AutoCAD 2020');
    });

    test('accepts a bare object as well as an array', () {
      final products = parseRegistryProductsJson(
        '{"DisplayName":"AutoCAD 2020","UninstallString":"C:\\\\s.exe"}',
      );

      expect(products.single.displayName, 'AutoCAD 2020');
    });

    test('reports an entry with no uninstall command as null, not missing', () {
      // These two cases need different messages, so they must stay distinct:
      // the product IS installed, it just can't be removed this way.
      final products = parseRegistryProductsJson(
        '[{"DisplayName":"AutoCAD 2020","UninstallString":null,'
        '"QuietUninstallString":null}]',
      );

      expect(products, hasLength(1));
      expect(products.single.displayName, 'AutoCAD 2020');
      expect(products.single.uninstallString, isNull);
    });

    test('skips entries with no DisplayName', () {
      final products = parseRegistryProductsJson(
        '[{"UninstallString":"C:\\\\s.exe"},'
        '{"DisplayName":"  ","UninstallString":"C:\\\\s.exe"},'
        '{"DisplayName":"AutoCAD 2020"}]',
      );

      expect(products.map((p) => p.displayName), ['AutoCAD 2020']);
    });

    test('handles empty results', () {
      expect(parseRegistryProductsJson('[]'), isEmpty);
      expect(parseRegistryProductsJson(''), isEmpty);
      expect(parseRegistryProductsJson('   '), isEmpty);
      expect(parseRegistryProductsJson('﻿'), isEmpty);
    });

    test('throws on malformed JSON rather than silently returning nothing', () {
      expect(
        () => parseRegistryProductsJson('{not json'),
        throwsFormatException,
      );
    });
  });
}
