import 'package:dt_tracker_ai/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('uses light mode by default', () async {
    final preferences = await SharedPreferences.getInstance();
    final controller = ThemeController(preferences);

    expect(controller.themeMode, ThemeMode.light);
  });

  test('persists the selected theme mode', () async {
    final preferences = await SharedPreferences.getInstance();
    final controller = ThemeController(preferences);

    await controller.setThemeMode(ThemeMode.dark);
    expect(controller.themeMode, ThemeMode.dark);
    expect(preferences.getString('app_theme_mode'), 'dark');

    final restoredController = ThemeController(preferences);
    expect(restoredController.themeMode, ThemeMode.dark);
  });
}
