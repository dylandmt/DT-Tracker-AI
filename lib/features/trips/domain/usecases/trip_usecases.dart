import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

class StartTrip implements UseCase<TripEntity, StartTripParams> {
  final TripRepository repository;
  StartTrip(this.repository);
  @override
  Future<Either<Failure, TripEntity>> call(StartTripParams params) => repository
      .startTrip(vehicleId: params.vehicleId, trackerId: params.trackerId);
}

class StartTripParams extends Equatable {
  final String vehicleId;
  final String trackerId;
  const StartTripParams({required this.vehicleId, required this.trackerId});
  @override
  List<Object?> get props => [vehicleId, trackerId];
}

class GetActiveTrip implements UseCase<TripEntity?, NoParams> {
  final TripRepository repository;
  GetActiveTrip(this.repository);
  @override
  Future<Either<Failure, TripEntity?>> call(NoParams params) =>
      repository.getActiveTrip();
}

class GetTrips implements UseCase<List<TripEntity>, NoParams> {
  final TripRepository repository;
  GetTrips(this.repository);
  @override
  Future<Either<Failure, List<TripEntity>>> call(NoParams params) =>
      repository.getTrips();
}

class GetTrip implements UseCase<TripEntity, IdParams> {
  final TripRepository repository;
  GetTrip(this.repository);
  @override
  Future<Either<Failure, TripEntity>> call(IdParams params) =>
      repository.getTrip(params.id);
}

class EndTrip implements UseCase<TripEntity, IdParams> {
  final TripRepository repository;
  EndTrip(this.repository);
  @override
  Future<Either<Failure, TripEntity>> call(IdParams params) =>
      repository.endTrip(params.id);
}
