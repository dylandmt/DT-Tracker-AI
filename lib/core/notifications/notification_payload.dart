import 'dart:convert';

class NotificationPayload {
  final String type;
  final String? eventId;
  final String? vehicleId;
  final String? trackerId;
  final String? geofenceId;
  final String? geofenceName;

  const NotificationPayload({
    required this.type,
    this.eventId,
    this.vehicleId,
    this.trackerId,
    this.geofenceId,
    this.geofenceName,
  });

  bool get isGeofenceEvent =>
      type == 'geofence_enter' || type == 'geofence_exit';

  factory NotificationPayload.fromData(Map<String, dynamic> data) {
    String? value(String key) => data[key]?.toString();

    return NotificationPayload(
      type: value('type') ?? '',
      eventId: value('eventId'),
      vehicleId: value('vehicleId'),
      trackerId: value('trackerId'),
      geofenceId: value('geofenceId'),
      geofenceName: value('geofenceName'),
    );
  }

  static NotificationPayload? tryFromJson(String? value) {
    if (value == null || value.isEmpty) return null;

    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) return null;
      final payload = NotificationPayload.fromData(decoded);
      return payload.isGeofenceEvent ? payload : null;
    } on FormatException {
      return null;
    }
  }

  Map<String, String> toData() => {
    'type': type,
    if (eventId != null) 'eventId': eventId!,
    if (vehicleId != null) 'vehicleId': vehicleId!,
    if (trackerId != null) 'trackerId': trackerId!,
    if (geofenceId != null) 'geofenceId': geofenceId!,
    if (geofenceName != null) 'geofenceName': geofenceName!,
  };

  String toJson() => jsonEncode(toData());
}
