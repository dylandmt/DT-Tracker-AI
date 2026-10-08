import 'package:dt_tracker_ai/config/environment/environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps the current environment to its Firebase Auth tenant', () {
    switch (EnvironmentConfig.current) {
      case Environment.dev:
        expect(EnvironmentConfig.firebaseAuthTenantId, 'dt-tracker-dev-4q4r4');
      case Environment.staging:
        expect(
          EnvironmentConfig.firebaseAuthTenantId,
          'dt-tracker-staging-dik3f',
        );
      case Environment.prod:
        expect(EnvironmentConfig.firebaseAuthTenantId, 'dt-tracker-prod-zo5r7');
    }
  });
}
