import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/vehicle_model.dart';

/// Abstract interface for vehicle remote data source
abstract class VehicleRemoteDataSource {
  /// Get all vehicles for a user
  Future<List<VehicleModel>> getVehicles(String userId);

  /// Get a single vehicle by ID
  Future<VehicleModel> getVehicleById(String userId, String vehicleId);

  /// Stream of vehicles for real-time updates
  Stream<List<VehicleModel>> watchVehicles(String userId);

  /// Create a new vehicle
  Future<VehicleModel> createVehicle(String userId, VehicleModel vehicle);

  /// Update an existing vehicle
  Future<VehicleModel> updateVehicle(String userId, VehicleModel vehicle);

  /// Delete a vehicle
  Future<void> deleteVehicle(String userId, String vehicleId);

  /// Add an image URL to a vehicle
  Future<void> addImageUrl(String userId, String vehicleId, String imageUrl);

  /// Remove an image URL from a vehicle
  Future<void> removeImageUrl(String userId, String vehicleId, String imageUrl);

  /// Set the tracker ID for a vehicle
  Future<void> setTrackerId(
    String userId,
    String vehicleId,
    String? trackerId,
  );
}

/// Implementation of [VehicleRemoteDataSource] using Firestore
class VehicleRemoteDataSourceImpl implements VehicleRemoteDataSource {
  final FirebaseFirestore firestore;

  VehicleRemoteDataSourceImpl({required this.firestore});

  /// Get the vehicles collection reference for a user
  CollectionReference<Map<String, dynamic>> _vehiclesRef(String userId) {
    return firestore.collection('users').doc(userId).collection('vehicles');
  }

  @override
  Future<List<VehicleModel>> getVehicles(String userId) async {
    try {
      final snapshot = await _vehiclesRef(userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get vehicles: $e');
    }
  }

  @override
  Future<VehicleModel> getVehicleById(String userId, String vehicleId) async {
    try {
      final doc = await _vehiclesRef(userId).doc(vehicleId).get();

      if (!doc.exists) {
        throw ServerException(message: 'Vehicle not found');
      }

      return VehicleModel.fromFirestore(doc);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to get vehicle: $e');
    }
  }

  @override
  Stream<List<VehicleModel>> watchVehicles(String userId) {
    return _vehiclesRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => VehicleModel.fromFirestore(doc)).toList());
  }

  @override
  Future<VehicleModel> createVehicle(String userId, VehicleModel vehicle) async {
    try {
      final docRef = _vehiclesRef(userId).doc(vehicle.id);
      await docRef.set(vehicle.toJson());

      final doc = await docRef.get();
      return VehicleModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException(message: 'Failed to create vehicle: $e');
    }
  }

  @override
  Future<VehicleModel> updateVehicle(String userId, VehicleModel vehicle) async {
    try {
      final docRef = _vehiclesRef(userId).doc(vehicle.id);
      await docRef.update(vehicle.toUpdateJson());

      final doc = await docRef.get();
      return VehicleModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException(message: 'Failed to update vehicle: $e');
    }
  }

  @override
  Future<void> deleteVehicle(String userId, String vehicleId) async {
    try {
      await _vehiclesRef(userId).doc(vehicleId).delete();
    } catch (e) {
      throw ServerException(message: 'Failed to delete vehicle: $e');
    }
  }

  @override
  Future<void> addImageUrl(
    String userId,
    String vehicleId,
    String imageUrl,
  ) async {
    try {
      await _vehiclesRef(userId).doc(vehicleId).update({
        'imageUrls': FieldValue.arrayUnion([imageUrl]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw ServerException(message: 'Failed to add image: $e');
    }
  }

  @override
  Future<void> removeImageUrl(
    String userId,
    String vehicleId,
    String imageUrl,
  ) async {
    try {
      await _vehiclesRef(userId).doc(vehicleId).update({
        'imageUrls': FieldValue.arrayRemove([imageUrl]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw ServerException(message: 'Failed to remove image: $e');
    }
  }

  @override
  Future<void> setTrackerId(
    String userId,
    String vehicleId,
    String? trackerId,
  ) async {
    try {
      await _vehiclesRef(userId).doc(vehicleId).update({
        'trackerId': trackerId,
        'trackerLinkedAt':
            trackerId != null ? Timestamp.fromDate(DateTime.now()) : null,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw ServerException(message: 'Failed to update tracker: $e');
    }
  }
}
