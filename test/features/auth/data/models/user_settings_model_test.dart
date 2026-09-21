import 'package:flutter_test/flutter_test.dart';

import 'package:dt_tracker_ai/features/auth/data/models/user_model.dart';
import 'package:dt_tracker_ai/features/auth/domain/entities/user.dart';

void main() {
  group('UserSettings', () {
    test('copyWith changes only email notification preference', () {
      const settings = UserSettings(
        speedAlertEnabled: false,
        speedLimitKmh: 95,
        geofenceAlertEnabled: false,
        pushNotificationsEnabled: false,
      );

      final updated = settings.copyWith(emailNotificationsEnabled: true);

      expect(updated.speedAlertEnabled, isFalse);
      expect(updated.speedLimitKmh, 95);
      expect(updated.geofenceAlertEnabled, isFalse);
      expect(updated.pushNotificationsEnabled, isFalse);
      expect(updated.emailNotificationsEnabled, isTrue);
    });
  });

  group('UserSettingsModel', () {
    test('uses false for a missing email notification preference', () {
      final settings = UserSettingsModel.fromJson(const {
        'speedAlertEnabled': true,
        'speedLimitKmh': 120,
        'geofenceAlertEnabled': true,
        'pushNotificationsEnabled': true,
      });

      expect(settings.emailNotificationsEnabled, isFalse);
    });

    test('serializes the email notification preference', () {
      const settings = UserSettingsModel(emailNotificationsEnabled: true);

      expect(settings.toJson()['emailNotificationsEnabled'], isTrue);
    });
  });
}
