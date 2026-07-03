import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/trip_point.dart';
import '../repositories/map_repository.dart';

/// Parameters for getting trip history
class TripHistoryParams extends Equatable {
  final String vehicleId;
  final DateTime startDate;
  final DateTime endDate;

  const TripHistoryParams({
    required this.vehicleId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [vehicleId, startDate, endDate];
}

/// Use case to get trip history for a vehicle within a date range
class GetTripHistory implements UseCase<TripEntity, TripHistoryParams> {
  final MapRepository repository;

  GetTripHistory(this.repository);

  @override
  Future<Either<Failure, TripEntity>> call(TripHistoryParams params) async {
    return await repository.getTripHistory(
      vehicleId: params.vehicleId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

/// Parameters for getting day trip points
class DayTripParams extends Equatable {
  final String vehicleId;
  final DateTime date;

  const DayTripParams({
    required this.vehicleId,
    required this.date,
  });

  @override
  List<Object?> get props => [vehicleId, date];
}

/// Use case to get trip points for a specific day
class GetDayTripPoints
    implements UseCase<List<TripPointEntity>, DayTripParams> {
  final MapRepository repository;

  GetDayTripPoints(this.repository);

  @override
  Future<Either<Failure, List<TripPointEntity>>> call(
    DayTripParams params,
  ) async {
    return await repository.getDayTripPoints(
      vehicleId: params.vehicleId,
      date: params.date,
    );
  }
}
