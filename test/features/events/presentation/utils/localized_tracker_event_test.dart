import 'package:dt_tracker_ai/features/events/domain/entities/tracker_event.dart';
import 'package:dt_tracker_ai/features/events/presentation/utils/localized_tracker_event.dart';
import 'package:dt_tracker_ai/l10n/app_localizations_en.dart';
import 'package:dt_tracker_ai/l10n/app_localizations_es.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final geofenceEnterEvent = TrackerEventEntity(
    id: 'event-id',
    type: 'geofence_enter',
    status: 'new',
    isRead: false,
    vehicleId: 'vehicle-id',
    vehicleName: 'CUERVO',
    trackerId: 'tracker-id',
    geofenceName: 'CASA',
    title: 'Geofence event',
    message: 'Vehicle crossed a boundary',
    occurredAt: DateTime(2026),
  );

  test('localizes geofence events in Spanish', () {
    final event = localizedTrackerEvent(
      AppLocalizationsEs(),
      geofenceEnterEvent,
    );

    expect(event.title, 'Entrada a geocerca');
    expect(event.message, 'Tu vehículo CUERVO ha entrado a CASA.');
  });

  test('keeps backend content for unknown event types', () {
    final unknownEvent = TrackerEventEntity(
      id: 'event-id',
      type: 'unknown',
      status: 'new',
      isRead: false,
      vehicleId: 'vehicle-id',
      trackerId: 'tracker-id',
      title: 'Unknown event',
      message: 'Unrecognized event',
      occurredAt: DateTime(2026),
    );

    final event = localizedTrackerEvent(AppLocalizationsEn(), unknownEvent);

    expect(event.title, 'Unknown event');
    expect(event.message, 'Unrecognized event');
  });
}
