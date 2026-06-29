import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/vehicle.dart';
import '../repositories/vehicle_repository.dart';

/// Use case to get all vehicles for the current user
class GetVehicles implements UseCase<List<VehicleEntity>, NoParams> {
  final VehicleRepository repository;

  GetVehicles(this.repository);

  @override
  Future<Either<Failure, List<VehicleEntity>>> call(NoParams params) async {
    return await repository.getVehicles();
  }
}
