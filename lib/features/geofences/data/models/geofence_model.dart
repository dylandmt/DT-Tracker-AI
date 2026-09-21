import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/geofence.dart';

class GeofenceModel extends GeofenceEntity {
  const GeofenceModel({
    required super.id,
    required super.name,
    required super.latitude,
    required super.longitude,
    required super.radiusMeters,
    required super.vehicleIds,
    required super.triggerOnEnter,
    required super.triggerOnExit,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory GeofenceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;
    final center = data['center'] as Map<String, dynamic>;
    return GeofenceModel(
      id: document.id,
      name: data['name'] as String,
      latitude: (center['latitude'] as num).toDouble(),
      longitude: (center['longitude'] as num).toDouble(),
      radiusMeters: (data['radiusMeters'] as num).toDouble(),
      vehicleIds: List<String>.from(data['vehicleIds'] as List),
      triggerOnEnter: data['triggerOnEnter'] as bool,
      triggerOnExit: data['triggerOnExit'] as bool,
      isActive: data['isActive'] as bool,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory GeofenceModel.fromApiJson(Map<String, dynamic> json) {
    final center = json['center'] as Map<String, dynamic>;
    return GeofenceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (center['latitude'] as num).toDouble(),
      longitude: (center['longitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num).toDouble(),
      vehicleIds: List<String>.from(json['vehicleIds'] as List),
      triggerOnEnter: json['triggerOnEnter'] as bool,
      triggerOnExit: json['triggerOnExit'] as bool,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toCreateJson() => {
    'name': name,
    'center': {'latitude': latitude, 'longitude': longitude},
    'radiusMeters': radiusMeters,
    'vehicleIds': vehicleIds,
    'triggerOnEnter': triggerOnEnter,
    'triggerOnExit': triggerOnExit,
    'isActive': isActive,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> toUpdateJson() => {
    'name': name,
    'center': {'latitude': latitude, 'longitude': longitude},
    'radiusMeters': radiusMeters,
    'vehicleIds': vehicleIds,
    'triggerOnEnter': triggerOnEnter,
    'triggerOnExit': triggerOnExit,
    'isActive': isActive,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
