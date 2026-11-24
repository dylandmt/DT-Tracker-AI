import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/statistics.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../datasources/statistics_remote_datasource.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  StatisticsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });
  final StatisticsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, VehicleStatistics>> getStatistics({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  }) => _guard(
    () async => _vehicle(
      await remoteDataSource.getStatistics(
        vehicleId: vehicleId,
        from: from,
        to: to,
      ),
    ),
  );

  @override
  Future<Either<Failure, DailyStatistics>> getDailyStatistics({
    required String vehicleId,
    required DateTime date,
  }) => _guard(
    () async => _daily(
      (await remoteDataSource.getDailyStatistics(
            vehicleId: vehicleId,
            date: date,
          ))['statistics']
          as Map<String, dynamic>,
    ),
  );

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await action());
    } on AuthException catch (error) {
      return Left(AuthFailure(message: error.message));
    } on ServerException catch (error) {
      return Left(switch (error.statusCode) {
        400 => ValidationFailure(message: error.message),
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

  VehicleStatistics _vehicle(Map<String, dynamic> response) {
    final data = response['statistics'] as Map<String, dynamic>;
    return VehicleStatistics(
      vehicleId: data['vehicleId'] as String,
      from: DateTime.parse(data['from'] as String),
      to: DateTime.parse(data['to'] as String),
      summary: _summary(data['summary'] as Map<String, dynamic>),
      days: (data['days'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(_daily)
          .toList(),
    );
  }

  DailyStatistics _daily(Map<String, dynamic> data) {
    final summary = data['summary'] as Map<String, dynamic>? ?? data;
    return DailyStatistics(
      date: DateTime.parse(data['date'] as String),
      summary: _summary(summary),
      speedSeries: (summary['speedSeries'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => SpeedSample(
              timestamp: DateTime.parse(item['timestamp'] as String),
              speedKmh: (item['speedKmh'] as num?)?.toDouble() ?? 0,
            ),
          )
          .toList(),
    );
  }

  StatisticsSummary _summary(Map<String, dynamic> data) => StatisticsSummary(
    distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0,
    averageDailyDistanceKm:
        (data['averageDailyDistanceKm'] as num?)?.toDouble() ?? 0,
    averageSpeedKmh: (data['averageSpeedKmh'] as num?)?.toDouble() ?? 0,
    maxSpeedKmh: (data['maxSpeedKmh'] as num?)?.toDouble() ?? 0,
    movingMinutes: (data['movingMinutes'] as num?)?.toDouble() ?? 0,
    pointCount: (data['pointCount'] as num?)?.toInt() ?? 0,
  );
}
