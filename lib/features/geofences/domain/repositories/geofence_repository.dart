import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/geofence.dart';

abstract class GeofenceRepository {
  Future<Either<Failure, List<GeofenceEntity>>> getGeofences();
  Future<Either<Failure, GeofenceEntity>> getGeofenceById(String id);
  Stream<Either<Failure, List<GeofenceEntity>>> watchGeofences();
  Future<Either<Failure, GeofenceEntity>> createGeofence({
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required List<String> vehicleIds,
    required bool triggerOnEnter,
    required bool triggerOnExit,
    required bool isActive,
  });
  Future<Either<Failure, GeofenceEntity>> updateGeofence({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required List<String> vehicleIds,
    required bool triggerOnEnter,
    required bool triggerOnExit,
    required bool isActive,
  });
  Future<Either<Failure, void>> deleteGeofence(String id);
}
