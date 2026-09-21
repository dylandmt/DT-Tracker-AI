import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/tracker_event.dart';

/// Uses the event type, rather than backend text, for localized event content.
({String title, String message}) localizedTrackerEvent(
  AppLocalizations l10n,
  TrackerEventEntity event,
) {
  return switch (event.eventType) {
    TrackerEventType.geofenceEnter => (
      title: l10n.geofenceEnterEventTitle,
      message: event.geofenceName == null
          ? l10n.geofenceEnterEventMessageWithoutGeofence(
              event.vehicleName ?? event.vehicleId,
            )
          : l10n.geofenceEnterEventMessage(
              event.vehicleName ?? event.vehicleId,
              event.geofenceName!,
            ),
    ),
    TrackerEventType.geofenceExit => (
      title: l10n.geofenceExitEventTitle,
      message: event.geofenceName == null
          ? l10n.geofenceExitEventMessageWithoutGeofence(
              event.vehicleName ?? event.vehicleId,
            )
          : l10n.geofenceExitEventMessage(
              event.vehicleName ?? event.vehicleId,
              event.geofenceName!,
            ),
    ),
    TrackerEventType.unknown => (title: event.title, message: event.message),
  };
}
