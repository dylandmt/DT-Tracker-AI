import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/vehicle.dart';
import '../repositories/vehicle_repository.dart';

/// Parameters for updating a vehicle
class UpdateVehicleParams extends Equatable {
  final String id;
  final String? name;
  final String? plateNumber;
  final String? brand;
  final String? model;
  final int? year;
  final String? color;

  const UpdateVehicleParams({
    required this.id,
    this.name,
    this.plateNumber,
    this.brand,
    this.model,
    this.year,
    this.color,
  });

  @override
  List<Object?> get props => [id, name, plateNumber, brand, model, year, color];
}

/// Use case to update an existing vehicle
class UpdateVehicle implements UseCase<VehicleEntity, UpdateVehicleParams> {
  final VehicleRepository repository;

  UpdateVehicle(this.repository);

  @override
  Future<Either<Failure, VehicleEntity>> call(UpdateVehicleParams params) async {
    return await repository.updateVehicle(
      id: params.id,
      name: params.name,
      plateNumber: params.plateNumber,
      brand: params.brand,
      model: params.model,
      year: params.year,
      color: params.color,
    );
  }
}
