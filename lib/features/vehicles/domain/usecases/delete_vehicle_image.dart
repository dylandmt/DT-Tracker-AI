import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/vehicle_repository.dart';

/// Parameters for deleting a vehicle image
class DeleteImageParams extends Equatable {
  final String vehicleId;
  final String imageUrl;

  const DeleteImageParams({
    required this.vehicleId,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [vehicleId, imageUrl];
}

/// Use case to delete an image from a vehicle
class DeleteVehicleImage implements UseCase<void, DeleteImageParams> {
  final VehicleRepository repository;

  DeleteVehicleImage(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteImageParams params) async {
    return await repository.deleteVehicleImage(
      vehicleId: params.vehicleId,
      imageUrl: params.imageUrl,
    );
  }
}
