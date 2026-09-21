import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../config/environment/environment.dart';
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
  final FirebaseAuth firebaseAuth;

  GeofenceRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseAuth,
  });

  CollectionReference<Map<String, dynamic>> _reference(String userId) =>
      firestore.collection('users').doc(userId).collection('geofences');

  @override
  Future<List<GeofenceModel>> getGeofences(String userId) async {
    if (EnvironmentConfig.current != Environment.dev) {
      final response = await _request('GET', '/geofences');
      return (response['geofences'] as List)
          .map(
            (item) => GeofenceModel.fromApiJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    if (EnvironmentConfig.isDev) {
      final response = await _request('GET', '/geofences');
      return (response['geofences'] as List)
          .map(
            (item) => GeofenceModel.fromApiJson(item as Map<String, dynamic>),
          )
          .toList();
    }
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
    if (EnvironmentConfig.current != Environment.dev) {
      final geofences = await getGeofences(userId);
      return geofences.firstWhere(
        (geofence) => geofence.id == id,
        orElse: () =>
            throw const ServerException(message: 'Geofence not found'),
      );
    }
    if (EnvironmentConfig.isDev) {
      final geofences = await getGeofences(userId);
      return geofences.firstWhere(
        (geofence) => geofence.id == id,
        orElse: () =>
            throw const ServerException(message: 'Geofence not found'),
      );
    }
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
  Stream<List<GeofenceModel>> watchGeofences(String userId) {
    if (EnvironmentConfig.current != Environment.dev) {
      return _watchDevelopmentGeofences(userId);
    }
    if (EnvironmentConfig.isDev) {
      return _watchDevelopmentGeofences(userId);
    }
    return _reference(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(GeofenceModel.fromFirestore).toList(),
        );
  }

  Stream<List<GeofenceModel>> _watchDevelopmentGeofences(String userId) async* {
    yield await getGeofences(userId);
    yield* Stream.periodic(
      const Duration(seconds: 5),
    ).asyncMap((_) => getGeofences(userId));
  }

  @override
  Future<GeofenceModel> createGeofence(
    String userId,
    GeofenceModel geofence,
  ) async {
    if (EnvironmentConfig.current != Environment.dev) {
      final response = await _request(
        'POST',
        '/geofences',
        _apiPayload(geofence),
      );
      return GeofenceModel.fromApiJson(
        response['geofence'] as Map<String, dynamic>,
      );
    }
    if (EnvironmentConfig.isDev) {
      final response = await _request(
        'POST',
        '/geofences',
        _apiPayload(geofence),
      );
      return GeofenceModel.fromApiJson(
        response['geofence'] as Map<String, dynamic>,
      );
    }
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
    if (EnvironmentConfig.current != Environment.dev) {
      final response = await _request(
        'PUT',
        '/geofences/${geofence.id}',
        _apiPayload(geofence),
      );
      return GeofenceModel.fromApiJson(
        response['geofence'] as Map<String, dynamic>,
      );
    }
    if (EnvironmentConfig.isDev) {
      final response = await _request(
        'PUT',
        '/geofences/${geofence.id}',
        _apiPayload(geofence),
      );
      return GeofenceModel.fromApiJson(
        response['geofence'] as Map<String, dynamic>,
      );
    }
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
    if (EnvironmentConfig.current != Environment.dev) {
      await _request('DELETE', '/geofences/$id');
      return;
    }
    if (EnvironmentConfig.isDev) {
      await _request('DELETE', '/geofences/$id');
      return;
    }
    try {
      await _reference(userId).doc(id).delete();
    } catch (e) {
      throw ServerException(message: 'Failed to delete geofence: $e');
    }
  }

  Map<String, dynamic> _apiPayload(GeofenceModel geofence) => {
    'name': geofence.name,
    'center': {'latitude': geofence.latitude, 'longitude': geofence.longitude},
    'radiusMeters': geofence.radiusMeters,
    'vehicleIds': geofence.vehicleIds,
    'triggerOnEnter': geofence.triggerOnEnter,
    'triggerOnExit': geofence.triggerOnExit,
    'isActive': geofence.isActive,
  };

  Future<Map<String, dynamic>> _request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw const ServerException(message: 'User not authenticated');
    }
    final client = HttpClient();
    try {
      final request = await client.openUrl(
        method,
        Uri.parse('${EnvironmentConfig.apiBaseUrl}$path'),
      );
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${await user.getIdToken()}',
      );
      if (body != null) {
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.add(utf8.encode(jsonEncode(body)));
      }
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final decoded = responseBody.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(responseBody) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      throw ServerException(
        message:
            decoded['message']?.toString() ?? 'HTTP ${response.statusCode}',
        statusCode: response.statusCode,
        errorCode: decoded['error']?.toString(),
      );
    } finally {
      client.close();
    }
  }
}
