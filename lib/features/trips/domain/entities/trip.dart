import 'package:equatable/equatable.dart';

enum TripStatus { active, completed }

class TripLocation extends Equatable {
  final double latitude;
  final double longitude;

  const TripLocation({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}

class TripEntity extends Equatable {
  final String tripId;
  final String uid;
  final String vehicleId;
  final String trackerId;
  final TripStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final TripLocation? startLocation;
  final TripLocation? endLocation;
  final double? startOdometerKm;
  final double? endOdometerKm;
  final double distanceKm;
  final int durationSeconds;
  final int pointCount;
  final double maxSpeedKmh;
  final double averageSpeedKmh;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TripEntity({
    required this.tripId,
    required this.uid,
    required this.vehicleId,
    required this.trackerId,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.startLocation,
    this.endLocation,
    this.startOdometerKm,
    this.endOdometerKm,
    required this.distanceKm,
    required this.durationSeconds,
    required this.pointCount,
    required this.maxSpeedKmh,
    required this.averageSpeedKmh,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == TripStatus.active;

  @override
  List<Object?> get props => [
    tripId,
    uid,
    vehicleId,
    trackerId,
    status,
    startedAt,
    endedAt,
    startLocation,
    endLocation,
    startOdometerKm,
    endOdometerKm,
    distanceKm,
    durationSeconds,
    pointCount,
    maxSpeedKmh,
    averageSpeedKmh,
    createdAt,
    updatedAt,
  ];
}
