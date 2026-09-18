import 'dart:convert';
import 'dart:io';

import 'package:dt_tracker_ai/features/social/data/datasources/social_backend_datasource.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late HttpServer server;
  late _MockFirebaseAuth auth;
  late _MockUser user;

  setUp(() async {
    auth = _MockFirebaseAuth();
    user = _MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.getIdToken()).thenAnswer((_) async => 'token');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  });

  tearDown(() => server.close(force: true));

  test('unwraps shared locations returned under result', () async {
    server.listen((request) async {
      expect(request.uri.path, '/location-shares/share-1/locations');
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'ok': true,
            'result': {
              'share': {'shareId': 'share-1'},
              'locations': [
                {'vehicleId': 'vehicle-1', 'lat': 19.4, 'lng': -99.1},
              ],
            },
          }),
        );
      await request.response.close();
    });

    final dataSource = SocialBackendDataSource(
      firebaseAuth: auth,
      baseUrl: 'http://${server.address.address}:${server.port}',
    );

    final result = await dataSource.sharedLocations('share-1');

    expect(result['share'], {'shareId': 'share-1'});
    expect(result['locations'], [
      {'vehicleId': 'vehicle-1', 'lat': 19.4, 'lng': -99.1},
    ]);
  });
}
