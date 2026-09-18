import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../../config/environment/environment.dart';
import '../../../../core/errors/exceptions.dart';

/// Authenticated HTTP access to the social and location sharing API.
class SocialBackendDataSource {
  final FirebaseAuth _auth;
  final String _baseUrl;

  SocialBackendDataSource({required FirebaseAuth firebaseAuth, String? baseUrl})
    : _auth = firebaseAuth,
      _baseUrl = baseUrl ?? EnvironmentConfig.apiBaseUrl;

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User not authenticated');
    }

    final client = HttpClient();
    try {
      final request = await client.openUrl(method, Uri.parse('$_baseUrl$path'));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${await user.getIdToken()}',
      );
      if (body != null) request.add(utf8.encode(jsonEncode(body)));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody.isEmpty) return <String, dynamic>{};
        final decoded = jsonDecode(responseBody);
        if (decoded is Map<String, dynamic>) return decoded;
        throw const ServerException(message: 'Unexpected server response');
      }

      String message = 'HTTP ${response.statusCode}';
      try {
        final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
        message =
            decoded['message']?.toString() ??
            decoded['error']?.toString() ??
            message;
      } catch (_) {
        if (responseBody.isNotEmpty) message = '$message: $responseBody';
      }
      throw ServerException(message: message);
    } on ServerException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (error) {
      throw ServerException(message: 'Social request failed: $error');
    } finally {
      client.close(force: true);
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) =>
      _list('POST', '/users/search', body: {'query': query}, key: 'users');

  Future<void> sendFriendRequest(String targetUid) =>
      _request('POST', '/friends/requests', body: {'targetUid': targetUid});
  Future<List<Map<String, dynamic>>> incomingRequests() =>
      _list('GET', '/friends/requests/incoming', key: 'requests');
  Future<List<Map<String, dynamic>>> outgoingRequests() =>
      _list('GET', '/friends/requests/outgoing', key: 'requests');
  Future<void> acceptRequest(String requestId) =>
      _request('POST', '/friends/requests/$requestId/accept');
  Future<void> rejectRequest(String requestId) =>
      _request('POST', '/friends/requests/$requestId/reject');
  Future<void> cancelRequest(String requestId) =>
      _request('DELETE', '/friends/requests/$requestId');
  Future<List<Map<String, dynamic>>> friends() =>
      _list('GET', '/friends', key: 'friends');
  Future<void> removeFriend(String friendUid) =>
      _request('DELETE', '/friends/$friendUid');

  Future<void> blockUser(String targetUid) =>
      _request('POST', '/users/me/blocks', body: {'targetUid': targetUid});
  Future<List<Map<String, dynamic>>> blocks() =>
      _list('GET', '/users/me/blocks', key: 'blocks');
  Future<void> unblockUser(String targetUid) =>
      _request('DELETE', '/users/me/blocks/$targetUid');

  Future<Map<String, dynamic>> upsertLocationShare({
    required String friendUid,
    required List<String> vehicleIds,
    String duration = '15m',
  }) => _request(
    'PUT',
    '/location-shares/friends/$friendUid',
    body: {'vehicleIds': vehicleIds, 'duration': duration},
  );
  Future<List<Map<String, dynamic>>> outgoingLocationShares() =>
      _list('GET', '/location-shares/outgoing', key: 'shares');
  Future<List<Map<String, dynamic>>> incomingLocationShares() =>
      _list('GET', '/location-shares/incoming', key: 'shares');
  Future<Map<String, dynamic>> sharedLocations(String shareId) =>
      _request('GET', '/location-shares/$shareId/locations');
  Future<void> revokeLocationShare(String shareId) =>
      _request('DELETE', '/location-shares/$shareId');

  Future<List<Map<String, dynamic>>> _list(
    String method,
    String path, {
    required String key,
    Map<String, dynamic>? body,
  }) async {
    final response = await _request(method, path, body: body);
    final values = response[key];
    if (values is! List) return const [];
    return values
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .toList();
  }
}
