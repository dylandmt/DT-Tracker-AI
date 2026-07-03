import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/vehicle.dart';
import '../repositories/vehicle_repository.dart';

/// Parameters for linking a tracker to a vehicle
class LinkTrackerParams extends Equatable {
  final String vehicleId;
  final String trackerId;

  const LinkTrackerParams({
    required this.vehicleId,
    required this.trackerId,
  });

  @override
  List<Object?> get props => [vehicleId, trackerId];
}

/// Use case to link a tracker to a vehicle
class LinkTracker implements UseCase<VehicleEntity, LinkTrackerParams> {
  final VehicleRepository repository;

  LinkTracker(this.repository);

  @override
  Future<Either<Failure, VehicleEntity>> call(LinkTrackerParams params) async {
    return await repository.linkTracker(
      vehicleId: params.vehicleId,
      trackerId: params.trackerId,
    );
  }
}
