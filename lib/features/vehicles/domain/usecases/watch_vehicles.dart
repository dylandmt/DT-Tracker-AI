import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/vehicle.dart';
import '../repositories/vehicle_repository.dart';

/// Use case to watch vehicles for real-time updates
class WatchVehicles implements StreamUseCase<List<VehicleEntity>, NoParams> {
  final VehicleRepository repository;

  WatchVehicles(this.repository);

  @override
  Stream<Either<Failure, List<VehicleEntity>>> call(NoParams params) {
    return repository.watchVehicles();
  }
}
