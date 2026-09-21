import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/vehicle.dart';
import '../repositories/vehicle_repository.dart';

/// Use case to unlink a tracker from a vehicle
class UnlinkTracker implements UseCase<VehicleEntity, UnlinkTrackerParams> {
  final VehicleRepository repository;

  UnlinkTracker(this.repository);

  @override
  Future<Either<Failure, VehicleEntity>> call(
    UnlinkTrackerParams params,
  ) async {
    return await repository.unlinkTracker(params.vehicleId, pin: params.pin);
  }
}

class UnlinkTrackerParams extends Equatable {
  const UnlinkTrackerParams({required this.vehicleId, this.pin});

  final String vehicleId;
  final String? pin;

  @override
  List<Object?> get props => [vehicleId, pin];
}
