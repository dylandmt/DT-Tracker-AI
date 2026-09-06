import 'package:equatable/equatable.dart';

enum TrackerEventType { geofenceEnter, geofenceExit, unknown }

class EventLocation extends Equatable {
  final double latitude;
  final double longitude;

  const EventLocation({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}

class TrackerEventEntity extends Equatable {
  final String id;
  final String type;
  final String status;
  final bool isRead;
  final String vehicleId;
  final String? vehicleName;
  final String trackerId;
  final String? geofenceName;
  final String title;
  final String message;
  final DateTime occurredAt;
  final EventLocation? location;

  const TrackerEventEntity({
    required this.id,
    required this.type,
    required this.status,
    required this.isRead,
    required this.vehicleId,
    this.vehicleName,
    required this.trackerId,
    this.geofenceName,
    required this.title,
    required this.message,
    required this.occurredAt,
    this.location,
  });

  TrackerEventType get eventType => switch (type) {
    'geofence_enter' => TrackerEventType.geofenceEnter,
    'geofence_exit' => TrackerEventType.geofenceExit,
    _ => TrackerEventType.unknown,
  };

  @override
  List<Object?> get props => [
    id,
    type,
    status,
    isRead,
    vehicleId,
    vehicleName,
    trackerId,
    geofenceName,
    title,
    message,
    occurredAt,
    location,
  ];
}
