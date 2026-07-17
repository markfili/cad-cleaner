import 'dart:convert';

/// One entry from a Windows uninstall registry key.
class RegistryProduct {
  const RegistryProduct({
    required this.displayName,
    this.uninstallString,
    this.version,
  });

  final String displayName;

  /// QuietUninstallString when the vendor provides one, else UninstallString.
  /// Null when the entry has neither — some products are only removable
  /// through their own installer.
  final String? uninstallString;

  final String? version;

  @override
  String toString() => version == null ? displayName : '$displayName $version';
}

/// Parses the JSON emitted by the registry query.
///
/// Kept as plain Dart, apart from [WindowsCadService], so it can be tested off
/// Windows. Throws [FormatException] on malformed JSON.
List<RegistryProduct> parseRegistryProductsJson(String raw) {
  var text = raw.trim();
  if (text.isEmpty) {
    return [];
  }
  // Windows PowerShell's `Set-Content -Encoding UTF8` writes a BOM.
  if (text.startsWith('﻿')) {
    text = text.substring(1).trim();
  }
  if (text.isEmpty) {
    return [];
  }

  final decoded = json.decode(text);
  // ConvertTo-Json collapses a single-element array to a bare object on some
  // PowerShell versions, so accept either shape.
  final entries = decoded is List ? decoded : [decoded];

  final products = <RegistryProduct>[];
  for (final entry in entries) {
    if (entry is! Map) {
      continue;
    }

    final name = _string(entry['DisplayName']);
    if (name == null) {
      continue;
    }

    products.add(
      RegistryProduct(
        displayName: name,
        // A vendor's quiet string is preferred: it uninstalls without
        // prompting, which is what this wizard wants.
        uninstallString: _string(entry['QuietUninstallString']) ??
            _string(entry['UninstallString']),
        version: _string(entry['DisplayVersion']),
      ),
    );
  }
  return products;
}

/// Returns a trimmed non-empty string, or null for anything else.
String? _string(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
