import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
    final platform = Platform.isIOS ? 'ios' : 'android';
    final uri = Uri.parse('$_baseUrl/users/me/devices/$deviceId/push-token');

    final client = HttpClient();

    try {
      if (kDebugMode) {
        debugPrint('[PUSH] Registering push device');
        debugPrint('[PUSH] uri=$uri');
        debugPrint('[PUSH] deviceId=$deviceId');
        debugPrint('[PUSH] platform=$platform');
        debugPrint('[PUSH] tokenLength=${pushToken.length}');
      }

      final request = await client.putUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      request.add(
        utf8.encode(jsonEncode({'pushToken': pushToken, 'platform': platform})),
      );

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (kDebugMode) {
        debugPrint('[PUSH] registration status=${response.statusCode}');
        debugPrint('[PUSH] registration body=$responseBody');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ServerException(
          message: responseBody.isEmpty
              ? 'Push token registration failed'
              : 'Push token registration failed: $responseBody',
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
