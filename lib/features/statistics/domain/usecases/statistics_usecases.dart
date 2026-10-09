import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/statistics.dart';
import '../repositories/statistics_repository.dart';

class StatisticsParams extends Equatable {
  const StatisticsParams({
    required this.vehicleId,
    required this.from,
    required this.to,
  });
  final String vehicleId;
  final DateTime from;
  final DateTime to;
  @override
  List<Object> get props => [vehicleId, from, to];
}

class DailyStatisticsParams extends Equatable {
  const DailyStatisticsParams({required this.vehicleId, required this.date});
  final String vehicleId;
  final DateTime date;
  @override
  List<Object> get props => [vehicleId, date];
}

class GetVehicleStatistics
    implements UseCase<VehicleStatistics, StatisticsParams> {
  GetVehicleStatistics(this.repository);
  final StatisticsRepository repository;
  @override
  Future<Either<Failure, VehicleStatistics>> call(StatisticsParams params) =>
      repository.getStatistics(
        vehicleId: params.vehicleId,
        from: params.from,
        to: params.to,
      );
}

class GetDailyStatistics
    implements UseCase<DailyStatistics, DailyStatisticsParams> {
  GetDailyStatistics(this.repository);
  final StatisticsRepository repository;
  @override
  Future<Either<Failure, DailyStatistics>> call(DailyStatisticsParams params) =>
      repository.getDailyStatistics(
        vehicleId: params.vehicleId,
        date: params.date,
      );
}
