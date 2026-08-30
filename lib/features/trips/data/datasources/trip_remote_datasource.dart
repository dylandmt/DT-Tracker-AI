import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../../config/environment/environment.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/trip_model.dart';

abstract class TripRemoteDataSource {
  Future<TripModel> startTrip({
    required String vehicleId,
    required String trackerId,
  });
  Future<TripModel?> getActiveTrip();
  Future<List<TripModel>> getTrips();
  Future<TripModel> getTrip(String tripId);
  Future<TripModel> endTrip(String tripId);
}

class TripRemoteDataSourceImpl implements TripRemoteDataSource {
  final FirebaseAuth _auth;
  final String _baseUrl;

  TripRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    String? baseUrl,
  }) : _auth = firebaseAuth,
       _baseUrl = baseUrl ?? EnvironmentConfig.apiBaseUrl;

  @override
  Future<TripModel> startTrip({
    required String vehicleId,
    required String trackerId,
  }) async {
    final response = await _request(
      'POST',
      '/trips/start',
      body: {'vehicleId': vehicleId, 'trackerId': trackerId},
    );
    return TripModel.fromJson(response['trip'] as Map<String, dynamic>);
  }

  @override
  Future<TripModel?> getActiveTrip() async {
    final response = await _request('GET', '/trips/active');
    final trip = response['trip'];
    return trip is Map<String, dynamic> ? TripModel.fromJson(trip) : null;
  }

  @override
  Future<List<TripModel>> getTrips() async {
    final response = await _request('GET', '/trips');
    final trips = response['trips'] as List<dynamic>? ?? const [];
    return trips
        .whereType<Map<String, dynamic>>()
        .map(TripModel.fromJson)
        .toList();
  }

  @override
  Future<TripModel> getTrip(String tripId) async {
    final response = await _request('GET', '/trips/$tripId');
    return TripModel.fromJson(response['trip'] as Map<String, dynamic>);
  }

  @override
  Future<TripModel> endTrip(String tripId) async {
    final response = await _request(
      'POST',
      '/trips/$tripId/end',
      body: const {},
    );
    return TripModel.fromJson(response['trip'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User not authenticated');
    }

    final token = await user.getIdToken();
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, Uri.parse('$_baseUrl$path'));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.add(utf8.encode(jsonEncode(body)));
      }
      final response = await request.close();
      final raw = await response.transform(utf8.decoder).join();
      final decoded = raw.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      throw ServerException(
        message: decoded['message'] as String? ?? 'HTTP ${response.statusCode}',
        statusCode: response.statusCode,
        errorCode: decoded['error'] as String?,
        requestId: decoded['requestId'] as String?,
      );
    } on ServerException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (error) {
      throw ServerException(message: 'Trip request failed: $error');
    } finally {
      client.close(force: true);
    }
  }
}
