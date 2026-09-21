import 'package:flutter_test/flutter_test.dart';

import 'package:dt_tracker_ai/features/events/domain/entities/tracker_event.dart';

void main() {
  TrackerEventEntity eventWithType(String type) => TrackerEventEntity(
    id: 'event-id',
    type: type,
    status: 'new',
    isRead: false,
    vehicleId: 'vehicle-id',
    trackerId: 'tracker-id',
    title: 'Geofence event',
    message: 'Vehicle crossed a boundary',
    occurredAt: DateTime(2026),
  );

  test('maps geofence enter events', () {
    expect(
      eventWithType('geofence_enter').eventType,
      TrackerEventType.geofenceEnter,
    );
  });

  test('maps unsupported event types safely', () {
    expect(eventWithType('future_event').eventType, TrackerEventType.unknown);
  });
}
