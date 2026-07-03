import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/vehicle.dart';
import '../repositories/vehicle_repository.dart';

/// Parameters for creating a vehicle
class CreateVehicleParams extends Equatable {
  final String name;
  final String plateNumber;
  final String? brand;
  final String? model;
  final int? year;
  final String? color;

  const CreateVehicleParams({
    required this.name,
    required this.plateNumber,
    this.brand,
    this.model,
    this.year,
    this.color,
  });

  @override
  List<Object?> get props => [name, plateNumber, brand, model, year, color];
}

/// Use case to create a new vehicle
class CreateVehicle implements UseCase<VehicleEntity, CreateVehicleParams> {
  final VehicleRepository repository;

  CreateVehicle(this.repository);

  @override
  Future<Either<Failure, VehicleEntity>> call(CreateVehicleParams params) async {
    return await repository.createVehicle(
      name: params.name,
      plateNumber: params.plateNumber,
      brand: params.brand,
      model: params.model,
      year: params.year,
      color: params.color,
    );
  }
}
