import 'package:flutter_test/flutter_test.dart';

import 'package:dt_tracker_ai/features/auth/utils/permission_gate.dart';
import 'package:dt_tracker_ai/core/constants/route_constants.dart';

void main() {
  group('resolvePostAuthRoute', () {
    test('returns home when all conditions are met', () {
      final route = resolvePostAuthRoute(
        hasLocation: true,
        hasNotifications: true,
      );
      expect(route, RouteConstants.home);
    });

    test('routes to setup when location permission missing', () {
      final route = resolvePostAuthRoute(
        hasLocation: false,
        hasNotifications: true,
      );
      expect(route, RouteConstants.setup);
    });

    test('routes to setup when notifications permission missing', () {
      final route = resolvePostAuthRoute(
        hasLocation: true,
        hasNotifications: false,
      );
      expect(route, RouteConstants.setup);
    });

    test(
      'returns home when services are disabled but permissions are granted',
      () {
        final route = resolvePostAuthRoute(
          hasLocation: true,
          hasNotifications: true,
        );
        expect(route, RouteConstants.home);
      },
    );
  });
}
