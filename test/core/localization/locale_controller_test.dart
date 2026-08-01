import 'package:dt_tracker_ai/core/localization/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('uses the device locale when no preference is stored', () async {
    final preferences = await SharedPreferences.getInstance();
    final controller = LocaleController(preferences);

    expect(controller.locale, isNull);
  });

  test('persists a selected locale and clears it for system default', () async {
    final preferences = await SharedPreferences.getInstance();
    final controller = LocaleController(preferences);

    await controller.setLocale(const Locale('es'));
    expect(controller.locale, const Locale('es'));
    expect(preferences.getString('app_locale'), 'es');

    await controller.setLocale(null);
    expect(controller.locale, isNull);
    expect(preferences.containsKey('app_locale'), isFalse);
  });
}
