import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../../config/environment/environment.dart';
import '../errors/exceptions.dart';

/// Manages the server-backed unlink PIN.
class TrackerSecurityService {
  TrackerSecurityService({required FirebaseAuth firebaseAuth, String? baseUrl})
    : _firebaseAuth = firebaseAuth,
      _baseUrl = baseUrl ?? EnvironmentConfig.apiBaseUrl;

  final FirebaseAuth _firebaseAuth;
  final String _baseUrl;

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User not authenticated');
    }

    final client = HttpClient();
    try {
      final request = await client.openUrl(method, Uri.parse('$_baseUrl$path'));
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${await user.getIdToken()}',
      );
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      if (body != null) request.add(utf8.encode(jsonEncode(body)));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(responseBody) as Map<String, dynamic>;
      }

      final decoded = responseBody.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(responseBody) as Map<String, dynamic>;
      throw ServerException(
        message:
            decoded['message']?.toString() ?? 'HTTP ${response.statusCode}',
        statusCode: response.statusCode,
        errorCode: decoded['error']?.toString(),
      );
    } on ServerException {
      rethrow;
    } catch (error) {
      throw ServerException(message: 'Security PIN request failed: $error');
    } finally {
      client.close();
    }
  }

  Future<bool> hasPin() async {
    final response = await _request('GET', '/users/me/security-pin');
    final securityPin = response['securityPin'];
    return securityPin is Map<String, dynamic> &&
        securityPin['configured'] == true;
  }

  Future<void> savePin(String pin, {String? currentPin}) async {
    await _request(
      'PUT',
      '/users/me/security-pin',
      body: {'pin': pin, if (currentPin != null) 'currentPin': currentPin},
    );
  }

  Future<bool> verifyPin(String pin) async {
    try {
      await _request(
        'POST',
        '/users/me/security-pin/verify',
        body: {'pin': pin},
      );
      return true;
    } on ServerException catch (error) {
      if (error.errorCode == 'security_pin_invalid') return false;
      rethrow;
    }
  }

  Future<void> revokePin(String currentPin) async {
    await _request(
      'DELETE',
      '/users/me/security-pin',
      body: {'currentPin': currentPin},
    );
  }
}
