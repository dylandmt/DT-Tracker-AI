import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/geofence.dart';
import '../../domain/repositories/geofence_repository.dart';
import '../datasources/geofence_remote_datasource.dart';
import '../models/geofence_model.dart';

class GeofenceRepositoryImpl implements GeofenceRepository {
  final GeofenceRemoteDataSource dataSource;
  final FirebaseAuth firebaseAuth;
  final NetworkInfo networkInfo;
  final Uuid _uuid = const Uuid();

  GeofenceRepositoryImpl({
    required this.dataSource,
    required this.firebaseAuth,
    required this.networkInfo,
  });

  String get _userId {
    final user = firebaseAuth.currentUser;
    if (user == null)
      throw const AuthException(message: 'User not authenticated');
    return user.uid;
  }

  @override
  Future<Either<Failure, List<GeofenceEntity>>> getGeofences() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await dataSource.getGeofences(_userId));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, GeofenceEntity>> getGeofenceById(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await dataSource.getGeofenceById(_userId, id));
    } on ServerException catch (e) {
      return Left(
        e.message.contains('not found')
            ? NotFoundFailure(message: e.message)
            : ServerFailure(message: e.message),
      );
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<GeofenceEntity>>> watchGeofences() {
    try {
      return dataSource
          .watchGeofences(_userId)
          .map((geofences) => Right<Failure, List<GeofenceEntity>>(geofences))
          .handleError(
            (Object error) => Left<Failure, List<GeofenceEntity>>(
              ServerFailure(message: error.toString()),
            ),
          );
    } on AuthException catch (e) {
      return Stream.value(Left(AuthFailure(message: e.message)));
    } catch (e) {
      return Stream.value(Left(UnknownFailure(message: e.toString())));
    }
  }

  @override
  Future<Either<Failure, GeofenceEntity>> createGeofence({
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required List<String> vehicleIds,
    required bool triggerOnEnter,
    required bool triggerOnExit,
    required bool isActive,
  }) => _write(
    GeofenceModel(
      id: _uuid.v4(),
      name: name,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      vehicleIds: vehicleIds,
      triggerOnEnter: triggerOnEnter,
      triggerOnExit: triggerOnExit,
      isActive: isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    create: true,
  );

  @override
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
  }) => _write(
    GeofenceModel(
      id: id,
      name: name,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      vehicleIds: vehicleIds,
      triggerOnEnter: triggerOnEnter,
      triggerOnExit: triggerOnExit,
      isActive: isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  );

  Future<Either<Failure, GeofenceEntity>> _write(
    GeofenceModel geofence, {
    bool create = false,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = create
          ? await dataSource.createGeofence(_userId, geofence)
          : await dataSource.updateGeofence(_userId, geofence);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGeofence(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await dataSource.deleteGeofence(_userId, id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
