import 'package:equatable/equatable.dart';

/// Vehicle entity representing a user's vehicle
class VehicleEntity extends Equatable {
  /// Unique identifier for the vehicle
  final String id;

  /// Vehicle name (required)
  final String name;

  /// License plate number (required)
  final String plateNumber;

  /// Vehicle brand/make (e.g., Toyota, Ford)
  final String? brand;

  /// Vehicle model (e.g., Corolla, F-150)
  final String? model;

  /// Manufacturing year
  final int? year;

  /// Vehicle color
  final String? color;

  /// List of image URLs (max 5)
  final List<String> imageUrls;

  /// Linked tracker IMEI (null if no tracker linked)
  final String? trackerId;

  /// When the tracker was linked
  final DateTime? trackerLinkedAt;

  /// When the vehicle was created
  final DateTime createdAt;

  /// When the vehicle was last updated
  final DateTime updatedAt;

  const VehicleEntity({
    required this.id,
    required this.name,
    required this.plateNumber,
    this.brand,
    this.model,
    this.year,
    this.color,
    this.imageUrls = const [],
    this.trackerId,
    this.trackerLinkedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Maximum number of images allowed per vehicle
  static const int maxImages = 5;

  /// Whether a tracker is linked to this vehicle
  bool get hasTracker => trackerId != null;

  /// Whether more images can be added
  bool get canAddMoreImages => imageUrls.length < maxImages;

  /// Number of remaining image slots
  int get remainingImageSlots => maxImages - imageUrls.length;

  /// Get the primary image URL (first image or null)
  String? get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  /// Get display name for the vehicle
  String get displayName {
    if (brand != null && model != null) {
      return '$brand $model';
    } else if (brand != null) {
      return brand!;
    }
    return name;
  }

  /// Get full description (brand model year)
  String? get fullDescription {
    final parts = <String>[];
    if (brand != null) parts.add(brand!);
    if (model != null) parts.add(model!);
    if (year != null) parts.add(year.toString());
    return parts.isNotEmpty ? parts.join(' ') : null;
  }

  /// Create a copy with modified fields
  VehicleEntity copyWith({
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
    return VehicleEntity(
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

  /// Create a copy with tracker unlinked
  VehicleEntity withoutTracker() {
    return VehicleEntity(
      id: id,
      name: name,
      plateNumber: plateNumber,
      brand: brand,
      model: model,
      year: year,
      color: color,
      imageUrls: imageUrls,
      trackerId: null,
      trackerLinkedAt: null,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        plateNumber,
        brand,
        model,
        year,
        color,
        imageUrls,
        trackerId,
        trackerLinkedAt,
        createdAt,
        updatedAt,
      ];
}
