import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/vehicle.dart';

/// Vehicle model for Firestore serialization
class VehicleModel extends VehicleEntity {
  const VehicleModel({
    required super.id,
    required super.name,
    required super.plateNumber,
    super.brand,
    super.model,
    super.year,
    super.color,
    super.imageUrls = const [],
    super.trackerId,
    super.trackerLinkedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create a VehicleModel from a Firestore document snapshot
  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleModel.fromJson(data, doc.id);
  }

  /// Create a VehicleModel from JSON with explicit ID
  factory VehicleModel.fromJson(Map<String, dynamic> json, String id) {
    return VehicleModel(
      id: id,
      name: json['name'] as String? ?? '',
      plateNumber: json['plateNumber'] as String? ?? '',
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      year: json['year'] as int?,
      color: json['color'] as String?,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      trackerId: json['trackerId'] as String?,
      trackerLinkedAt: json['trackerLinkedAt'] != null
          ? (json['trackerLinkedAt'] as Timestamp).toDate()
          : null,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Create a VehicleModel from a VehicleEntity
  factory VehicleModel.fromEntity(VehicleEntity entity) {
    return VehicleModel(
      id: entity.id,
      name: entity.name,
      plateNumber: entity.plateNumber,
      brand: entity.brand,
      model: entity.model,
      year: entity.year,
      color: entity.color,
      imageUrls: entity.imageUrls,
      trackerId: entity.trackerId,
      trackerLinkedAt: entity.trackerLinkedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Factory for creating a new vehicle
  factory VehicleModel.create({
    required String id,
    required String name,
    required String plateNumber,
    String? brand,
    String? model,
    int? year,
    String? color,
  }) {
    final now = DateTime.now();
    return VehicleModel(
      id: id,
      name: name,
      plateNumber: plateNumber,
      brand: brand,
      model: model,
      year: year,
      color: color,
      imageUrls: const [],
      trackerId: null,
      trackerLinkedAt: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'plateNumber': plateNumber,
      'brand': brand,
      'model': model,
      'year': year,
      'color': color,
      'imageUrls': imageUrls,
      'trackerId': trackerId,
      'trackerLinkedAt':
          trackerLinkedAt != null ? Timestamp.fromDate(trackerLinkedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Convert to JSON for updates (excludes createdAt)
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'plateNumber': plateNumber,
      'brand': brand,
      'model': model,
      'year': year,
      'color': color,
      'imageUrls': imageUrls,
      'trackerId': trackerId,
      'trackerLinkedAt':
          trackerLinkedAt != null ? Timestamp.fromDate(trackerLinkedAt!) : null,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  /// Create a copy with modified fields
  @override
  VehicleModel copyWith({
    String? id,
    String? name,
    String? plateNumber,
    String? brand,
    String? model,
    int? year,
    String? color,
    List<String>? imageUrls,
    String? trackerId,
    DateTime? trackerLinkedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      plateNumber: plateNumber ?? this.plateNumber,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      imageUrls: imageUrls ?? this.imageUrls,
      trackerId: trackerId ?? this.trackerId,
      trackerLinkedAt: trackerLinkedAt ?? this.trackerLinkedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
