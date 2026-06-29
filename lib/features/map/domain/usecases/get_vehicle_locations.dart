import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/vehicle_location.dart';
import '../repositories/map_repository.dart';

/// Use case to get all vehicle locations
class GetVehicleLocations
    implements UseCase<List<VehicleLocationEntity>, NoParams> {
  final MapRepository repository;

  GetVehicleLocations(this.repository);

  @override
  Future<Either<Failure, List<VehicleLocationEntity>>> call(
    NoParams params,
  ) async {
    return await repository.getVehicleLocations();
  }
}

/// Use case to watch all vehicle locations in real-time
class WatchVehicleLocations
    implements StreamUseCase<List<VehicleLocationEntity>, NoParams> {
  final MapRepository repository;

  WatchVehicleLocations(this.repository);

  @override
  Stream<Either<Failure, List<VehicleLocationEntity>>> call(NoParams params) {
    return repository.watchVehicleLocations();
  }
}
