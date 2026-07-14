import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/geofence_model.dart';

abstract class GeofenceRemoteDataSource {
  Future<List<GeofenceModel>> getGeofences(String userId);
  Future<GeofenceModel> getGeofenceById(String userId, String id);
  Stream<List<GeofenceModel>> watchGeofences(String userId);
  Future<GeofenceModel> createGeofence(String userId, GeofenceModel geofence);
  Future<GeofenceModel> updateGeofence(String userId, GeofenceModel geofence);
  Future<void> deleteGeofence(String userId, String id);
}

class GeofenceRemoteDataSourceImpl implements GeofenceRemoteDataSource {
  final FirebaseFirestore firestore;

  GeofenceRemoteDataSourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> _reference(String userId) =>
      firestore.collection('users').doc(userId).collection('geofences');

  @override
  Future<List<GeofenceModel>> getGeofences(String userId) async {
    try {
      final snapshot = await _reference(
        userId,
      ).orderBy('createdAt', descending: true).get();
      return snapshot.docs.map(GeofenceModel.fromFirestore).toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get geofences: $e');
    }
  }

  @override
  Future<GeofenceModel> getGeofenceById(String userId, String id) async {
    try {
      final document = await _reference(userId).doc(id).get();
      if (!document.exists) {
        throw const ServerException(message: 'Geofence not found');
      }
      return GeofenceModel.fromFirestore(document);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to get geofence: $e');
    }
  }

  @override
  Stream<List<GeofenceModel>> watchGeofences(String userId) =>
      _reference(userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map(GeofenceModel.fromFirestore).toList(),
          );

  @override
  Future<GeofenceModel> createGeofence(
    String userId,
    GeofenceModel geofence,
  ) async {
    try {
      final reference = _reference(userId).doc(geofence.id);
      await reference.set(geofence.toCreateJson());
      return GeofenceModel.fromFirestore(await reference.get());
    } catch (e) {
      throw ServerException(message: 'Failed to create geofence: $e');
    }
  }

  @override
  Future<GeofenceModel> updateGeofence(
    String userId,
    GeofenceModel geofence,
  ) async {
    try {
      final reference = _reference(userId).doc(geofence.id);
      await reference.update(geofence.toUpdateJson());
      return GeofenceModel.fromFirestore(await reference.get());
    } catch (e) {
      throw ServerException(message: 'Failed to update geofence: $e');
    }
  }

  @override
  Future<void> deleteGeofence(String userId, String id) async {
    try {
      await _reference(userId).doc(id).delete();
    } catch (e) {
      throw ServerException(message: 'Failed to delete geofence: $e');
    }
  }
}
