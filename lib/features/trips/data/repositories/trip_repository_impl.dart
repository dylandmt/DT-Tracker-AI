import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_remote_datasource.dart';

class TripRepositoryImpl implements TripRepository {
  final TripRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TripRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, TripEntity>> startTrip({
    required String vehicleId,
    required String trackerId,
  }) => _guard(
    () =>
        remoteDataSource.startTrip(vehicleId: vehicleId, trackerId: trackerId),
  );

  @override
  Future<Either<Failure, TripEntity?>> getActiveTrip() =>
      _guard(remoteDataSource.getActiveTrip);

  @override
  Future<Either<Failure, List<TripEntity>>> getTrips() =>
      _guard(remoteDataSource.getTrips);

  @override
  Future<Either<Failure, TripEntity>> getTrip(String tripId) =>
      _guard(() => remoteDataSource.getTrip(tripId));

  @override
  Future<Either<Failure, TripEntity>> endTrip(String tripId) =>
      _guard(() => remoteDataSource.endTrip(tripId));

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      return Right(await action());
    } on AuthException catch (error) {
      return Left(AuthFailure(message: error.message, code: error.code));
    } on ServerException catch (error) {
      if (error.errorCode == 'active_trip_exists') {
        return Left(ActiveTripExistsFailure(message: error.message));
      }
      return Left(switch (error.statusCode) {
        400 => ValidationFailure(message: error.message),
        401 => AuthFailure(message: error.message),
        403 => ForbiddenFailure(message: error.message),
        404 => NotFoundFailure(message: error.message),
        409 => ConflictFailure(message: error.message),
        _ => ServerFailure(
          message: error.message,
          statusCode: error.statusCode,
        ),
      });
    } catch (error) {
      return Left(UnknownFailure(message: error.toString()));
    }
  }
}
