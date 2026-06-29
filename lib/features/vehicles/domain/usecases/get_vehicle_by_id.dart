import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/vehicle.dart';
import '../repositories/vehicle_repository.dart';

/// Use case to get a single vehicle by ID
class GetVehicleById implements UseCase<VehicleEntity, IdParams> {
  final VehicleRepository repository;

  GetVehicleById(this.repository);

  @override
  Future<Either<Failure, VehicleEntity>> call(IdParams params) async {
    return await repository.getVehicleById(params.id);
  }
}
