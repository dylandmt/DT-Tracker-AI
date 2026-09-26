import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../../config/environment/environment.dart';
import '../../../../core/errors/exceptions.dart';

abstract class AccountBackendDataSource {
  Future<void> deleteAccount();
}

class AccountBackendDataSourceImpl implements AccountBackendDataSource {
  AccountBackendDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    String? baseUrl,
  }) : _auth = firebaseAuth,
       _baseUrl = baseUrl ?? EnvironmentConfig.apiBaseUrl;

  final FirebaseAuth _auth;
  final String _baseUrl;

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User not authenticated');
    }

    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw const AuthException(
        message: 'Unable to authenticate account deletion',
      );
    }

    final client = HttpClient();
    try {
      final request = await client.deleteUrl(Uri.parse('$_baseUrl/users/me'));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.add(utf8.encode(jsonEncode({'confirmation': 'DELETE'})));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) return;

      String message = 'HTTP ${response.statusCode}';
      try {
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        message =
            decoded['message']?.toString() ??
            decoded['error']?.toString() ??
            message;
      } catch (_) {
        if (body.isNotEmpty) message = '$message: $body';
      }
      throw ServerException(message: message, statusCode: response.statusCode);
    } on ServerException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (error) {
      throw ServerException(message: 'Account deletion request failed: $error');
    } finally {
      client.close(force: true);
    }
  }
}
