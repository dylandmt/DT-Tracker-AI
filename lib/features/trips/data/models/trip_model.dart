import '../../domain/entities/trip.dart';

class TripModel extends TripEntity {
  const TripModel({
    required super.tripId,
    required super.uid,
    required super.vehicleId,
    required super.trackerId,
    required super.status,
    required super.startedAt,
    super.endedAt,
    super.startLocation,
    super.endLocation,
    super.startOdometerKm,
    super.endOdometerKm,
    required super.distanceKm,
    required super.durationSeconds,
    required super.pointCount,
    required super.maxSpeedKmh,
    required super.averageSpeedKmh,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) => TripModel(
    tripId: json['tripId'] as String,
    uid: json['uid'] as String,
    vehicleId: json['vehicleId'] as String,
    trackerId: json['trackerId'] as String,
    status: json['status'] == 'completed'
        ? TripStatus.completed
        : TripStatus.active,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: _dateOrNull(json['endedAt']),
    startLocation: _locationOrNull(json['startLocation']),
    endLocation: _locationOrNull(json['endLocation']),
    startOdometerKm: _doubleOrNull(json['startOdometerKm']),
    endOdometerKm: _doubleOrNull(json['endOdometerKm']),
    distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
    durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
    pointCount: (json['pointCount'] as num?)?.toInt() ?? 0,
    maxSpeedKmh: (json['maxSpeedKmh'] as num?)?.toDouble() ?? 0,
    averageSpeedKmh: (json['averageSpeedKmh'] as num?)?.toDouble() ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  static DateTime? _dateOrNull(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;

  static double? _doubleOrNull(dynamic value) => (value as num?)?.toDouble();

  static TripLocation? _locationOrNull(dynamic value) {
    if (value is! Map<String, dynamic>) return null;
    final latitude = (value['lat'] as num?)?.toDouble();
    final longitude = (value['lng'] as num?)?.toDouble();
    if (latitude == null || longitude == null) return null;
    return TripLocation(latitude: latitude, longitude: longitude);
  }
}
