import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/geofence.dart';
import '../repositories/geofence_repository.dart';

class GeofenceParams extends Equatable {
  final String? id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final List<String> vehicleIds;
  final bool triggerOnEnter;
  final bool triggerOnExit;
  final bool isActive;

  const GeofenceParams({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.vehicleIds,
    required this.triggerOnEnter,
    required this.triggerOnExit,
    required this.isActive,
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
  ];
}

class GetGeofences implements UseCase<List<GeofenceEntity>, NoParams> {
  final GeofenceRepository repository;
  GetGeofences(this.repository);
  @override
  Future<Either<Failure, List<GeofenceEntity>>> call(NoParams params) =>
      repository.getGeofences();
}

class GetGeofenceById implements UseCase<GeofenceEntity, IdParams> {
  final GeofenceRepository repository;
  GetGeofenceById(this.repository);
  @override
  Future<Either<Failure, GeofenceEntity>> call(IdParams params) =>
      repository.getGeofenceById(params.id);
}

class WatchGeofences implements StreamUseCase<List<GeofenceEntity>, NoParams> {
  final GeofenceRepository repository;
  WatchGeofences(this.repository);
  @override
  Stream<Either<Failure, List<GeofenceEntity>>> call(NoParams params) =>
      repository.watchGeofences();
}

class CreateGeofence implements UseCase<GeofenceEntity, GeofenceParams> {
  final GeofenceRepository repository;
  CreateGeofence(this.repository);
  @override
  Future<Either<Failure, GeofenceEntity>> call(GeofenceParams params) =>
      repository.createGeofence(
        name: params.name,
        latitude: params.latitude,
        longitude: params.longitude,
        radiusMeters: params.radiusMeters,
        vehicleIds: params.vehicleIds,
        triggerOnEnter: params.triggerOnEnter,
        triggerOnExit: params.triggerOnExit,
        isActive: params.isActive,
      );
}

class UpdateGeofence implements UseCase<GeofenceEntity, GeofenceParams> {
  final GeofenceRepository repository;
  UpdateGeofence(this.repository);
  @override
  Future<Either<Failure, GeofenceEntity>> call(GeofenceParams params) =>
      repository.updateGeofence(
        id: params.id!,
        name: params.name,
        latitude: params.latitude,
        longitude: params.longitude,
        radiusMeters: params.radiusMeters,
        vehicleIds: params.vehicleIds,
        triggerOnEnter: params.triggerOnEnter,
        triggerOnExit: params.triggerOnExit,
        isActive: params.isActive,
      );
}

class DeleteGeofence implements UseCase<void, IdParams> {
  final GeofenceRepository repository;
  DeleteGeofence(this.repository);
  @override
  Future<Either<Failure, void>> call(IdParams params) =>
      repository.deleteGeofence(params.id);
}
