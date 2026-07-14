import 'package:equatable/equatable.dart';

class GeofenceEntity extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final List<String> vehicleIds;
  final bool triggerOnEnter;
  final bool triggerOnExit;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GeofenceEntity({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.vehicleIds,
    required this.triggerOnEnter,
    required this.triggerOnExit,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    latitude,
    longitude,
    radiusMeters,
    vehicleIds,
    triggerOnEnter,
    triggerOnExit,
    isActive,
    createdAt,
    updatedAt,
  ];
}
