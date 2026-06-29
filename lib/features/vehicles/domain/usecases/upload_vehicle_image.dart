import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/vehicle_repository.dart';

/// Parameters for uploading a vehicle image
class UploadImageParams extends Equatable {
  final String vehicleId;
  final String filePath;

  const UploadImageParams({
    required this.vehicleId,
    required this.filePath,
  });

  @override
  List<Object?> get props => [vehicleId, filePath];
}

/// Use case to upload an image for a vehicle
class UploadVehicleImage implements UseCase<String, UploadImageParams> {
  final VehicleRepository repository;

  UploadVehicleImage(this.repository);

  @override
  Future<Either<Failure, String>> call(UploadImageParams params) async {
    return await repository.uploadVehicleImage(
      vehicleId: params.vehicleId,
      filePath: params.filePath,
    );
  }
}
