import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/vehicle.dart';

/// Repository interface for vehicle operations
abstract class VehicleRepository {
  /// Get all vehicles for the current user
  ///
  /// Returns a list of [VehicleEntity] on success or [Failure] on error
  Future<Either<Failure, List<VehicleEntity>>> getVehicles();

  /// Get a single vehicle by ID
  ///
  /// Returns [VehicleEntity] on success or [Failure] on error
  Future<Either<Failure, VehicleEntity>> getVehicleById(String id);

  /// Stream of vehicles for real-time updates
  ///
  /// Returns a stream that emits [List<VehicleEntity>] on changes
  Stream<Either<Failure, List<VehicleEntity>>> watchVehicles();

  /// Create a new vehicle
  ///
  /// Returns the created [VehicleEntity] on success or [Failure] on error
  Future<Either<Failure, VehicleEntity>> createVehicle({
    required String name,
    required String plateNumber,
    String? brand,
    String? model,
    int? year,
    String? color,
  });

  /// Update an existing vehicle
  ///
  /// Returns the updated [VehicleEntity] on success or [Failure] on error
  Future<Either<Failure, VehicleEntity>> updateVehicle({
    required String id,
    String? name,
    String? plateNumber,
    String? brand,
    String? model,
    int? year,
    String? color,
  });

  /// Delete a vehicle
  ///
  /// This also unlinks any associated tracker
  /// Returns void on success or [Failure] on error
  Future<Either<Failure, void>> deleteVehicle(String id);

  /// Upload an image for a vehicle
  ///
  /// [vehicleId] - The vehicle to add the image to
  /// [filePath] - Local path to the image file
  ///
  /// Returns the uploaded image URL on success or [Failure] on error
  Future<Either<Failure, String>> uploadVehicleImage({
    required String vehicleId,
    required String filePath,
  });

  /// Delete an image from a vehicle
  ///
  /// [vehicleId] - The vehicle to remove the image from
  /// [imageUrl] - The URL of the image to delete
  ///
  /// Returns void on success or [Failure] on error
  Future<Either<Failure, void>> deleteVehicleImage({
    required String vehicleId,
    required String imageUrl,
  });

  /// Link a tracker to a vehicle
  ///
  /// [vehicleId] - The vehicle to link the tracker to
  /// [trackerId] - The IMEI of the tracker to link
  ///
  /// Returns the updated [VehicleEntity] on success or [Failure] on error
  Future<Either<Failure, VehicleEntity>> linkTracker({
    required String vehicleId,
    required String trackerId,
  });

  /// Unlink a tracker from a vehicle
  ///
  /// [vehicleId] - The vehicle to unlink the tracker from
  ///
  /// Returns the updated [VehicleEntity] on success or [Failure] on error
  Future<Either<Failure, VehicleEntity>> unlinkTracker(String vehicleId);
}
