import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/vehicle_location.dart';
import '../repositories/map_repository.dart';

/// Use case to get a single vehicle location by vehicle ID
class GetVehicleLocation
    implements UseCase<VehicleLocationEntity, IdParams> {
  final MapRepository repository;

  GetVehicleLocation(this.repository);

  @override
  Future<Either<Failure, VehicleLocationEntity>> call(IdParams params) async {
    return await repository.getVehicleLocation(params.id);
  }
}

/// Use case to watch a single vehicle location in real-time
class WatchVehicleLocation
    implements StreamUseCase<VehicleLocationEntity, IdParams> {
  final MapRepository repository;

  WatchVehicleLocation(this.repository);

  @override
  Stream<Either<Failure, VehicleLocationEntity>> call(IdParams params) {
    return repository.watchVehicleLocation(params.id);
  }
}
