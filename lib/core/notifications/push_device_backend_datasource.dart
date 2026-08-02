import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../../config/environment/environment.dart';
import '../errors/exceptions.dart';

/// Registers an installation token through the authenticated backend API.
class PushDeviceBackendDataSource {
  final FirebaseAuth _auth;
  final String _baseUrl;

  PushDeviceBackendDataSource({
    required FirebaseAuth firebaseAuth,
    String? baseUrl,
  }) : _auth = firebaseAuth,
       _baseUrl = baseUrl ?? EnvironmentConfig.apiBaseUrl;

  Future<void> registerPushToken({
    required String deviceId,
    required String pushToken,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User not authenticated');
    }

    final idToken = await user.getIdToken();
    final client = HttpClient();
    try {
      final request = await client.putUrl(
        Uri.parse('$_baseUrl/users/me/devices/$deviceId/push-token'),
      );
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      request.add(
        utf8.encode(
          jsonEncode({'pushToken': pushToken, 'platform': 'android'}),
        ),
      );

      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ServerException(
          message: 'Push token registration failed',
          statusCode: response.statusCode,
        );
      }
    } on ServerException {
      rethrow;
    } catch (error) {
      throw ServerException(message: 'Push token registration failed: $error');
    } finally {
      client.close();
    }
  }
}
