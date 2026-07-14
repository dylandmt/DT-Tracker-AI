import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/tracker_event.dart';

class TrackerEventModel extends TrackerEventEntity {
  const TrackerEventModel({
    required super.id,
    required super.type,
    required super.status,
    required super.isRead,
    required super.vehicleId,
    required super.trackerId,
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
    return TrackerEventModel(
      id: document.id,
      type: data['type'] as String? ?? 'unknown',
      status: data['status'] as String? ?? 'new',
      isRead: data['isRead'] as bool? ?? false,
      vehicleId: data['vehicleId'] as String? ?? '',
      trackerId: data['trackerId'] as String? ?? '',
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
}
