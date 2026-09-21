import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/trip.dart';

abstract class TripRepository {
  Future<Either<Failure, TripEntity>> startTrip({
    required String vehicleId,
    required String trackerId,
  });
  Future<Either<Failure, TripEntity?>> getActiveTrip();
  Future<Either<Failure, List<TripEntity>>> getTrips();
  Future<Either<Failure, TripEntity>> getTrip(String tripId);
  Future<Either<Failure, TripEntity>> endTrip(String tripId);
}
