import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../datasources/tracker_remote_datasource.dart';
import '../datasources/vehicle_image_datasource.dart';
import '../datasources/vehicle_remote_datasource.dart';
import '../models/vehicle_model.dart';

/// Implementation of [VehicleRepository]
class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleRemoteDataSource vehicleDataSource;
  final VehicleImageDataSource imageDataSource;
  final TrackerRemoteDataSource trackerDataSource;
  final FirebaseAuth firebaseAuth;
  final NetworkInfo networkInfo;
  final Uuid _uuid = const Uuid();

  VehicleRepositoryImpl({
    required this.vehicleDataSource,
    required this.imageDataSource,
    required this.trackerDataSource,
    required this.firebaseAuth,
    required this.networkInfo,
  });

  /// Get current user ID
  String get _userId {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User not authenticated');
    }
    return user.uid;
  }

  @override
  Future<Either<Failure, List<VehicleEntity>>> getVehicles() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final vehicles = await vehicleDataSource.getVehicles(_userId);
      return Right(vehicles);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, VehicleEntity>> getVehicleById(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final vehicle = await vehicleDataSource.getVehicleById(_userId, id);
      return Right(vehicle);
    } on ServerException catch (e) {
      if (e.message.contains('not found')) {
        return Left(NotFoundFailure(message: e.message));
      }
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<VehicleEntity>>> watchVehicles() {
    try {
      return vehicleDataSource.watchVehicles(_userId).map((vehicles) {
        return Right<Failure, List<VehicleEntity>>(vehicles);
      }).handleError((error) {
        return Left<Failure, List<VehicleEntity>>(
          ServerFailure(message: error.toString()),
        );
      });
    } on AuthException catch (e) {
      return Stream.value(Left(AuthFailure(message: e.message)));
    } catch (e) {
      return Stream.value(Left(UnknownFailure(message: e.toString())));
    }
  }

  @override
  Future<Either<Failure, VehicleEntity>> createVehicle({
    required String name,
    required String plateNumber,
    String? brand,
    String? model,
    int? year,
    String? color,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final vehicleModel = VehicleModel.create(
        id: _uuid.v4(),
        name: name,
        plateNumber: plateNumber,
        brand: brand,
        model: model,
        year: year,
        color: color,
      );

      final created = await vehicleDataSource.createVehicle(_userId, vehicleModel);
      return Right(created);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, VehicleEntity>> updateVehicle({
    required String id,
    String? name,
    String? plateNumber,
    String? brand,
    String? model,
    int? year,
    String? color,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      // Get existing vehicle
      final existing = await vehicleDataSource.getVehicleById(_userId, id);

      // Create updated model
      final updated = existing.copyWith(
        name: name ?? existing.name,
        plateNumber: plateNumber ?? existing.plateNumber,
        brand: brand ?? existing.brand,
        model: model ?? existing.model,
        year: year ?? existing.year,
        color: color ?? existing.color,
        updatedAt: DateTime.now(),
      );

      final result = await vehicleDataSource.updateVehicle(_userId, updated);
      return Right(result);
    } on ServerException catch (e) {
      if (e.message.contains('not found')) {
        return Left(NotFoundFailure(message: e.message));
      }
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteVehicle(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      // Get vehicle to check for tracker
      final vehicle = await vehicleDataSource.getVehicleById(_userId, id);

      // Unlink tracker if linked
      if (vehicle.trackerId != null) {
        await trackerDataSource.setTrackerOwner(vehicle.trackerId!, null);
      }

      // Delete all images from storage
      for (final imageUrl in vehicle.imageUrls) {
        try {
          await imageDataSource.deleteImage(imageUrl);
        } catch (_) {
          // Continue even if image deletion fails
        }
      }

      // Delete vehicle
      await vehicleDataSource.deleteVehicle(_userId, id);
      return const Right(null);
    } on ServerException catch (e) {
      if (e.message.contains('not found')) {
        return Left(NotFoundFailure(message: e.message));
      }
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadVehicleImage({
    required String vehicleId,
    required String filePath,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      // Check if vehicle exists and has room for more images
      final vehicle = await vehicleDataSource.getVehicleById(_userId, vehicleId);
      if (!vehicle.canAddMoreImages) {
        return const Left(ValidationFailure(
          message: 'Maximum number of images (5) reached',
        ));
      }

      // Upload image
      final imageUrl = await imageDataSource.uploadImage(
        userId: _userId,
        vehicleId: vehicleId,
        filePath: filePath,
      );

      // Add image URL to vehicle
      await vehicleDataSource.addImageUrl(_userId, vehicleId, imageUrl);

      return Right(imageUrl);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteVehicleImage({
    required String vehicleId,
    required String imageUrl,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      // Delete from storage
      await imageDataSource.deleteImage(imageUrl);

      // Remove from vehicle
      await vehicleDataSource.removeImageUrl(_userId, vehicleId, imageUrl);

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, VehicleEntity>> linkTracker({
    required String vehicleId,
    required String trackerId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      // Check if tracker is available
      final isAvailable = await trackerDataSource.isTrackerAvailable(trackerId);
      if (!isAvailable) {
        return const Left(ValidationFailure(
          message: 'Tracker is not available or does not exist',
        ));
      }

      // Link tracker to user in RTDB
      await trackerDataSource.setTrackerOwner(trackerId, _userId);

      // Update vehicle with tracker ID
      await vehicleDataSource.setTrackerId(_userId, vehicleId, trackerId);

      // Get updated vehicle
      final vehicle = await vehicleDataSource.getVehicleById(_userId, vehicleId);
      return Right(vehicle);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, VehicleEntity>> unlinkTracker(String vehicleId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      // Get vehicle to get tracker ID
      final vehicle = await vehicleDataSource.getVehicleById(_userId, vehicleId);

      if (vehicle.trackerId != null) {
        // Unlink tracker from user in RTDB
        await trackerDataSource.setTrackerOwner(vehicle.trackerId!, null);
      }

      // Remove tracker from vehicle
      await vehicleDataSource.setTrackerId(_userId, vehicleId, null);

      // Get updated vehicle
      final updatedVehicle =
          await vehicleDataSource.getVehicleById(_userId, vehicleId);
      return Right(updatedVehicle);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
