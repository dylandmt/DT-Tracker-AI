import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

void main() {
  test('Spanish and English ARB files have matching keys and placeholders', () {
    final english = _arb('en');
    final spanish = _arb('es');
    final englishKeys = _keys(english);
    final spanishKeys = _keys(spanish);

    expect(spanishKeys.difference(englishKeys), isEmpty);
    expect(englishKeys.difference(spanishKeys), isEmpty);

    for (final key in englishKeys) {
      final englishMetadata = english['@$key'] as Map<String, dynamic>?;
      final spanishMetadata = spanish['@$key'] as Map<String, dynamic>?;
      final englishPlaceholders =
          (englishMetadata?['placeholders'] as Map<String, dynamic>? ?? {})
              .keys
              .toSet();
      final spanishPlaceholders =
          (spanishMetadata?['placeholders'] as Map<String, dynamic>? ?? {})
              .keys
              .toSet();
      expect(spanishPlaceholders, englishPlaceholders, reason: key);
    }
  });
}
