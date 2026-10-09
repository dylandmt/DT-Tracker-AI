import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../../config/environment/environment.dart';
import '../../../../core/errors/exceptions.dart';

abstract class StatisticsRemoteDataSource {
  Future<Map<String, dynamic>> getStatistics({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  });
  Future<Map<String, dynamic>> getDailyStatistics({
    required String vehicleId,
    required DateTime date,
  });
}

class StatisticsRemoteDataSourceImpl implements StatisticsRemoteDataSource {
  StatisticsRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    String? baseUrl,
  }) : _auth = firebaseAuth,
       _baseUrl = baseUrl ?? EnvironmentConfig.apiBaseUrl;
  final FirebaseAuth _auth;
  final String _baseUrl;

  String _day(DateTime value) =>
      value.toUtc().toIso8601String().substring(0, 10);

  @override
  Future<Map<String, dynamic>> getStatistics({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  }) => _get(
    '/statistics/vehicles/$vehicleId?startDate=${_day(from)}&endDate=${_day(to)}',
  );

  @override
  Future<Map<String, dynamic>> getDailyStatistics({
    required String vehicleId,
    required DateTime date,
  }) => _get('/statistics/vehicles/$vehicleId/days/${_day(date)}');

  Future<Map<String, dynamic>> _get(String path) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User not authenticated');
    }
    final token = await user.getIdToken();
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('$_baseUrl$path'));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
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
      );
    } on ServerException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (error) {
      throw ServerException(message: 'Statistics request failed: $error');
    } finally {
      client.close(force: true);
    }
  }
}
