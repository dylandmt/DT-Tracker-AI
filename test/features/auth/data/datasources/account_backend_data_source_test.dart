import 'dart:convert';
import 'dart:io';

import 'package:dt_tracker_ai/core/errors/exceptions.dart';
import 'package:dt_tracker_ai/features/auth/data/datasources/account_backend_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late _MockFirebaseAuth auth;
  late _MockUser user;
  HttpServer? server;

  Future<AccountBackendDataSourceImpl> createDataSource() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return AccountBackendDataSourceImpl(
      firebaseAuth: auth,
      baseUrl: 'http://${server!.address.address}:${server!.port}',
    );
  }

  setUp(() {
    auth = _MockFirebaseAuth();
    user = _MockUser();
  });

  tearDown(() async {
    await server?.close(force: true);
  });

  test('throws AuthException without a user and makes no request', () async {
    when(() => auth.currentUser).thenReturn(null);
    final dataSource = await createDataSource();
    var receivedRequest = false;
    server!.listen((_) => receivedRequest = true);

    await expectLater(
      dataSource.deleteAccount(),
      throwsA(isA<AuthException>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(receivedRequest, isFalse);
  });

  test('throws AuthException when the Firebase token is empty', () async {
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.getIdToken(true)).thenAnswer((_) async => '');
    final dataSource = await createDataSource();

    await expectLater(
      dataSource.deleteAccount(),
      throwsA(isA<AuthException>()),
    );
  });

  test('sends the authenticated DELETE request and accepts 204', () async {
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.getIdToken(true)).thenAnswer((_) async => 'firebase-token');
    final dataSource = await createDataSource();

    server!.listen((request) async {
      expect(request.method, 'DELETE');
      expect(request.uri.path, '/users/me');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer firebase-token',
      );
      expect(request.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(
        await utf8.decoder.bind(request).join(),
        '{"confirmation":"DELETE"}',
      );
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
    });

    await expectLater(dataSource.deleteAccount(), completes);
  });

  test(
    'preserves backend message and status code for non-2xx responses',
    () async {
      when(() => auth.currentUser).thenReturn(user);
      when(
        () => user.getIdToken(true),
      ).thenAnswer((_) async => 'firebase-token');
      final dataSource = await createDataSource();

      server!.listen((request) async {
        request.response
          ..statusCode = HttpStatus.conflict
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'message': 'Deletion already in progress'}));
        await request.response.close();
      });

      await expectLater(
        dataSource.deleteAccount(),
        throwsA(
          isA<ServerException>()
              .having(
                (error) => error.statusCode,
                'statusCode',
                HttpStatus.conflict,
              )
              .having(
                (error) => error.message,
                'message',
                'Deletion already in progress',
              ),
        ),
      );
    },
  );

  test('wraps network errors in ServerException', () async {
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.getIdToken(true)).thenAnswer((_) async => 'firebase-token');
    final dataSource = AccountBackendDataSourceImpl(
      firebaseAuth: auth,
      baseUrl: 'http://127.0.0.1:1',
    );

    await expectLater(
      dataSource.deleteAccount(),
      throwsA(isA<ServerException>()),
    );
  });
}
