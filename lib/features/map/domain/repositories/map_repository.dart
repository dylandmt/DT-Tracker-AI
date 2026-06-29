import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/trip_point.dart';
import '../entities/vehicle_location.dart';

/// Repository interface for map-related operations
abstract class MapRepository {
  /// Get all vehicles with their current locations
  ///
  /// Returns a list of [VehicleLocationEntity] for vehicles that have linked trackers
  Future<Either<Failure, List<VehicleLocationEntity>>> getVehicleLocations();

  /// Stream of all vehicle locations for real-time updates
  ///
  /// Returns a stream that emits updated [VehicleLocationEntity] list whenever
  /// any vehicle's tracker data changes
  Stream<Either<Failure, List<VehicleLocationEntity>>> watchVehicleLocations();

  /// Get single vehicle location by vehicle ID
  ///
  /// Returns [VehicleLocationEntity] on success or [Failure] on error
  Future<Either<Failure, VehicleLocationEntity>> getVehicleLocation(
    String vehicleId,
  );

  /// Stream of single vehicle location for real-time updates
  ///
  /// Returns a stream that emits [VehicleLocationEntity] on changes
  Stream<Either<Failure, VehicleLocationEntity>> watchVehicleLocation(
    String vehicleId,
  );

  /// Get trip history for a vehicle within a date range
  ///
  /// [vehicleId] - The vehicle ID
  /// [startDate] - Start of the date range
  /// [endDate] - End of the date range
  ///
  /// Returns [TripEntity] with all points in the range
  Future<Either<Failure, TripEntity>> getTripHistory({
    required String vehicleId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get trip points for a specific day
  ///
  /// [vehicleId] - The vehicle ID
  /// [date] - The date to get trip points for
  ///
  /// Returns list of [TripPointEntity] for that day
  Future<Either<Failure, List<TripPointEntity>>> getDayTripPoints({
    required String vehicleId,
    required DateTime date,
  });
}
