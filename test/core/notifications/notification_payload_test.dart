import 'package:flutter_test/flutter_test.dart';

import 'package:dt_tracker_ai/core/notifications/notification_payload.dart';

void main() {
  test('accepts a geofence enter payload from FCM data', () {
    final payload = NotificationPayload.fromData({
      'type': 'geofence_enter',
      'eventId': 'event-id',
      'vehicleId': 'vehicle-id',
      'trackerId': 'tracker-id',
      'geofenceId': 'geofence-id',
      'geofenceName': 'Home',
    });

    expect(payload.isGeofenceEvent, isTrue);
    expect(payload.eventId, 'event-id');
    expect(
      NotificationPayload.tryFromJson(payload.toJson())?.type,
      'geofence_enter',
    );
  });

  test('does not treat unrelated FCM data as a geofence action', () {
    final payload = NotificationPayload.fromData({'type': 'low_battery'});

    expect(payload.isGeofenceEvent, isFalse);
    expect(NotificationPayload.tryFromJson(payload.toJson()), isNull);
  });
}
