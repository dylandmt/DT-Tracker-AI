import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/tracker_info.dart';
import '../../domain/repositories/tracker_repository.dart';
import '../datasources/tracker_remote_datasource.dart';

/// Implementation of [TrackerRepository]
class TrackerRepositoryImpl implements TrackerRepository {
  final TrackerRemoteDataSource trackerDataSource;
  final NetworkInfo networkInfo;

  TrackerRepositoryImpl({
    required this.trackerDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, TrackerInfoEntity>> getTrackerInfo(String imei) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final tracker = await trackerDataSource.getTrackerInfo(imei);

      if (tracker == null) {
        return const Left(NotFoundFailure(message: 'Tracker not found'));
      }

      return Right(tracker);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> trackerExists(String imei) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final exists = await trackerDataSource.trackerExists(imei);
      return Right(exists);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isTrackerAvailable(String imei) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final available = await trackerDataSource.isTrackerAvailable(imei);
      return Right(available);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> linkTrackerToUser({
    required String imei,
    required String userId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await trackerDataSource.setTrackerOwner(imei, userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unlinkTrackerFromUser(String imei) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await trackerDataSource.setTrackerOwner(imei, null);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TrackerLiveEntity>> getTrackerLive(String imei) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final live = await trackerDataSource.getTrackerLive(imei);
      return Right(live);
    } on ServerException catch (e) {
      if (e.message.contains('not found')) {
        return Left(NotFoundFailure(message: e.message));
      }
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, TrackerLiveEntity>> watchTrackerLive(String imei) {
    return trackerDataSource.watchTrackerLive(imei).map((live) {
      return Right<Failure, TrackerLiveEntity>(live);
    }).handleError((error) {
      if (error is ServerException) {
        if (error.message.contains('not found')) {
          return Left<Failure, TrackerLiveEntity>(
            NotFoundFailure(message: error.message),
          );
        }
        return Left<Failure, TrackerLiveEntity>(
          ServerFailure(message: error.message),
        );
      }
      return Left<Failure, TrackerLiveEntity>(
        UnknownFailure(message: error.toString()),
      );
    });
  }

  @override
  Future<Either<Failure, TrackerStatusEntity>> getTrackerStatus(
    String imei,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final status = await trackerDataSource.getTrackerStatus(imei);
      return Right(status);
    } on ServerException catch (e) {
      if (e.message.contains('not found')) {
        return Left(NotFoundFailure(message: e.message));
      }
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, TrackerStatusEntity>> watchTrackerStatus(String imei) {
    return trackerDataSource.watchTrackerStatus(imei).map((status) {
      return Right<Failure, TrackerStatusEntity>(status);
    }).handleError((error) {
      if (error is ServerException) {
        if (error.message.contains('not found')) {
          return Left<Failure, TrackerStatusEntity>(
            NotFoundFailure(message: error.message),
          );
        }
        return Left<Failure, TrackerStatusEntity>(
          ServerFailure(message: error.message),
        );
      }
      return Left<Failure, TrackerStatusEntity>(
        UnknownFailure(message: error.toString()),
      );
    });
  }
}
