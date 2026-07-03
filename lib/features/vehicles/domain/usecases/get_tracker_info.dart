import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/tracker_info.dart';
import '../repositories/tracker_repository.dart';

/// Parameters for getting tracker info by IMEI
class ImeiParams extends Equatable {
  final String imei;

  const ImeiParams({required this.imei});

  @override
  List<Object?> get props => [imei];
}

/// Use case to get tracker info by IMEI
class GetTrackerInfo implements UseCase<TrackerInfoEntity, ImeiParams> {
  final TrackerRepository repository;

  GetTrackerInfo(this.repository);

  @override
  Future<Either<Failure, TrackerInfoEntity>> call(ImeiParams params) async {
    return await repository.getTrackerInfo(params.imei);
  }
}

/// Use case to check if a tracker is available for linking
class IsTrackerAvailable implements UseCase<bool, ImeiParams> {
  final TrackerRepository repository;

  IsTrackerAvailable(this.repository);

  @override
  Future<Either<Failure, bool>> call(ImeiParams params) async {
    return await repository.isTrackerAvailable(params.imei);
  }
}

/// Use case to get tracker live data
class GetTrackerLive implements UseCase<TrackerLiveEntity, ImeiParams> {
  final TrackerRepository repository;

  GetTrackerLive(this.repository);

  @override
  Future<Either<Failure, TrackerLiveEntity>> call(ImeiParams params) async {
    return await repository.getTrackerLive(params.imei);
  }
}

/// Use case to watch tracker live data for real-time updates
class WatchTrackerLive implements StreamUseCase<TrackerLiveEntity, ImeiParams> {
  final TrackerRepository repository;

  WatchTrackerLive(this.repository);

  @override
  Stream<Either<Failure, TrackerLiveEntity>> call(ImeiParams params) {
    return repository.watchTrackerLive(params.imei);
  }
}

/// Use case to get tracker status
class GetTrackerStatus implements UseCase<TrackerStatusEntity, ImeiParams> {
  final TrackerRepository repository;

  GetTrackerStatus(this.repository);

  @override
  Future<Either<Failure, TrackerStatusEntity>> call(ImeiParams params) async {
    return await repository.getTrackerStatus(params.imei);
  }
}

/// Use case to watch tracker status for real-time updates
class WatchTrackerStatus implements StreamUseCase<TrackerStatusEntity, ImeiParams> {
  final TrackerRepository repository;

  WatchTrackerStatus(this.repository);

  @override
  Stream<Either<Failure, TrackerStatusEntity>> call(ImeiParams params) {
    return repository.watchTrackerStatus(params.imei);
  }
}
