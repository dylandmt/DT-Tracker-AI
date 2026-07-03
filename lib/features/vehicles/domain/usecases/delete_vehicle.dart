import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/vehicle_repository.dart';

/// Use case to delete a vehicle
///
/// This also unlinks any associated tracker
class DeleteVehicle implements UseCase<void, IdParams> {
  final VehicleRepository repository;

  DeleteVehicle(this.repository);

  @override
  Future<Either<Failure, void>> call(IdParams params) async {
    return await repository.deleteVehicle(params.id);
  }
}
