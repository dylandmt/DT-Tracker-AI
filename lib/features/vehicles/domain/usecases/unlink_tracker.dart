import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/vehicle.dart';
import '../repositories/vehicle_repository.dart';

/// Use case to unlink a tracker from a vehicle
class UnlinkTracker implements UseCase<VehicleEntity, IdParams> {
  final VehicleRepository repository;

  UnlinkTracker(this.repository);

  @override
  Future<Either<Failure, VehicleEntity>> call(IdParams params) async {
    return await repository.unlinkTracker(params.id);
  }
}
