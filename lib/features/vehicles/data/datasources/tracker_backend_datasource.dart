import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../config/environment/environment.dart';
import '../models/tracker_info_model.dart';

/// Minimal backend data source that calls secure server endpoints
/// Uses Firebase ID token for Authorization header
class TrackerBackendDataSource {
  final FirebaseAuth _auth;
  final String _baseUrl;

  TrackerBackendDataSource({
    required FirebaseAuth firebaseAuth,
    String? baseUrl,
  })  : _auth = firebaseAuth,
        _baseUrl = baseUrl ?? EnvironmentConfig.apiBaseUrl;

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User not authenticated');
    }

    final idToken = await user.getIdToken();

    final client = HttpClient();
    HttpClientRequest request;
    try {
      final url = Uri.parse('$_baseUrl$path');
      request = await client.postUrl(url);
    } catch (e) {
      client.close(force: true);
      throw ServerException(message: 'Failed to create request: $e');
    }

    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');

    if (body != null) {
      request.add(utf8.encode(jsonEncode(body)));
    }

    try {
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody.isEmpty) return <String, dynamic>{};
        final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
        return decoded;
      }

      // Try parse error payload
      try {
        final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
        final msg = decoded['message'] as String? ?? decoded['error']?.toString() ?? 'HTTP ${response.statusCode}';
        throw ServerException(message: msg);
      } catch (_) {
        throw ServerException(message: 'HTTP ${response.statusCode}: $responseBody');
      }
    } finally {
      client.close();
    }
  }

  /// Validate tracker availability and info
  /// Returns (TrackerInfoModel?, isAvailable)
  Future<(TrackerInfoModel?, bool)> validateImei(String imei) async {
    try {
      final res = await _post('/trackers/validate', body: {'imei': imei});
      final trackerJson = res['tracker'];
      final info = trackerJson is Map<String, dynamic>
          ? TrackerInfoModel.fromJson(trackerJson)
          : null;
      final isAvailable = res['isAvailable'] == true;
      return (info, isAvailable);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to validate tracker: $e');
    }
  }

  /// Link tracker to vehicle
  Future<void> linkTracker({required String vehicleId, required String imei}) async {
    try {
      await _post('/vehicles/$vehicleId/link', body: {'imei': imei});
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to link tracker: $e');
    }
  }

  /// Unlink tracker from vehicle
  Future<void> unlinkTracker({required String vehicleId}) async {
    try {
      await _post('/vehicles/$vehicleId/unlink');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to unlink tracker: $e');
    }
  }
}
