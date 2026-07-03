import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/trip_point.dart';
import '../../domain/entities/vehicle_location.dart';
import '../../domain/repositories/map_repository.dart';
import '../datasources/map_remote_datasource.dart';
import '../models/trip_point_model.dart';

/// Implementation of [MapRepository]
class MapRepositoryImpl implements MapRepository {
  final MapRemoteDataSource mapDataSource;
  final NetworkInfo networkInfo;

  MapRepositoryImpl({
    required this.mapDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<VehicleLocationEntity>>>
      getVehicleLocations() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final locations = await mapDataSource.getVehicleLocations();
      return Right(locations);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<VehicleLocationEntity>>>
      watchVehicleLocations() async* {
    if (!await networkInfo.isConnected) {
      yield const Left(NetworkFailure(message: 'No internet connection'));
      return;
    }

    yield* mapDataSource.watchVehicleLocations().map<
        Either<Failure, List<VehicleLocationEntity>>>(
      (locations) => Right(locations),
    ).handleError(
      (error) {
        if (error is AuthException) {
          return Left(AuthFailure(message: error.message));
        } else if (error is ServerException) {
          return Left(ServerFailure(message: error.message));
        }
        return Left(UnknownFailure(message: error.toString()));
      },
    );
  }

  @override
  Future<Either<Failure, VehicleLocationEntity>> getVehicleLocation(
    String vehicleId,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final location = await mapDataSource.getVehicleLocation(vehicleId);
      return Right(location);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, VehicleLocationEntity>> watchVehicleLocation(
    String vehicleId,
  ) async* {
    if (!await networkInfo.isConnected) {
      yield const Left(NetworkFailure(message: 'No internet connection'));
      return;
    }

    yield* mapDataSource.watchVehicleLocation(vehicleId).map<
        Either<Failure, VehicleLocationEntity>>(
      (location) => Right(location),
    ).handleError(
      (error) {
        if (error is AuthException) {
          return Left(AuthFailure(message: error.message));
        } else if (error is ServerException) {
          return Left(ServerFailure(message: error.message));
        }
        return Left(UnknownFailure(message: error.toString()));
      },
    );
  }

  @override
  Future<Either<Failure, TripEntity>> getTripHistory({
    required String vehicleId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      // First get the vehicle to get the tracker ID
      final vehicleLocation =
          await mapDataSource.getVehicleLocation(vehicleId);

      // Get trip points
      final points = await mapDataSource.getTripPoints(
        trackerId: vehicleLocation.trackerId,
        startDate: startDate,
        endDate: endDate,
      );

      final trip = TripModel.fromPoints(
        vehicleId: vehicleId,
        trackerId: vehicleLocation.trackerId,
        points: points,
      );

      return Right(trip);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TripPointEntity>>> getDayTripPoints({
    required String vehicleId,
    required DateTime date,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      // First get the vehicle to get the tracker ID
      final vehicleLocation =
          await mapDataSource.getVehicleLocation(vehicleId);

      // Set date range to full day
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Get trip points
      final points = await mapDataSource.getTripPoints(
        trackerId: vehicleLocation.trackerId,
        startDate: startDate,
        endDate: endDate,
      );

      return Right(points);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
