import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/statistics.dart';

abstract class StatisticsRepository {
  Future<Either<Failure, VehicleStatistics>> getStatistics({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  });

  Future<Either<Failure, DailyStatistics>> getDailyStatistics({
    required String vehicleId,
    required DateTime date,
  });
}
