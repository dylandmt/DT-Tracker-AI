import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/tracker_event.dart';

class TrackerEventModel extends TrackerEventEntity {
  const TrackerEventModel({
    required super.id,
    required super.type,
    required super.status,
    required super.isRead,
    required super.vehicleId,
    super.vehicleName,
    required super.trackerId,
    super.geofenceName,
    required super.title,
    required super.message,
    required super.occurredAt,
    super.location,
  });

  factory TrackerEventModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;
    final location = data['location'];
    final eventData = data['data'];
    return TrackerEventModel(
      id: document.id,
      type: data['type'] as String? ?? 'unknown',
      status: data['status'] as String? ?? 'new',
      isRead: data['isRead'] as bool? ?? false,
      vehicleId: data['vehicleId'] as String? ?? '',
      vehicleName: _stringValue(data, eventData, 'vehicleName'),
      trackerId: data['trackerId'] as String? ?? '',
      geofenceName: _stringValue(data, eventData, 'geofenceName'),
      title: data['title'] as String? ?? 'Tracker event',
      message: data['message'] as String? ?? '',
      occurredAt:
          (data['occurredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: location is Map<String, dynamic>
          ? EventLocation(
              latitude: (location['latitude'] as num).toDouble(),
              longitude: (location['longitude'] as num).toDouble(),
            )
          : null,
    );
  }

  static String? _stringValue(
    Map<String, dynamic> data,
    Object? eventData,
    String field,
  ) {
    final value =
        data[field] ??
        (eventData is Map<String, dynamic> ? eventData[field] : null);
    return value is String && value.isNotEmpty ? value : null;
  }
}
