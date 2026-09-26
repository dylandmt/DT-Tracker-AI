import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dt_tracker_ai/core/errors/exceptions.dart';
import 'package:dt_tracker_ai/core/errors/failures.dart';
import 'package:dt_tracker_ai/core/network/network_info.dart';
import 'package:dt_tracker_ai/core/onboarding/onboarding_controller.dart';
import 'package:dt_tracker_ai/features/auth/data/datasources/account_backend_data_source.dart';
import 'package:dt_tracker_ai/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:dt_tracker_ai/features/auth/data/datasources/profile_image_data_source.dart';
import 'package:dt_tracker_ai/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:dt_tracker_ai/features/auth/data/repositories/auth_repository_impl.dart';

class _MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class _MockUserRemoteDataSource extends Mock implements UserRemoteDataSource {}

class _MockProfileImageDataSource extends Mock
    implements ProfileImageDataSource {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

class _MockAccountBackendDataSource extends Mock
    implements AccountBackendDataSource {}

class _MockPreferences extends Mock implements SharedPreferences {}

class _MockOnboardingController extends Mock implements OnboardingController {}

class _MockUser extends Mock implements User {}

void main() {
  late _MockAuthRemoteDataSource authRemote;
  late _MockAccountBackendDataSource backend;
  late _MockPreferences preferences;
  late _MockOnboardingController onboarding;
  late AuthRepositoryImpl repository;

  setUp(() {
    authRemote = _MockAuthRemoteDataSource();
    backend = _MockAccountBackendDataSource();
    preferences = _MockPreferences();
    onboarding = _MockOnboardingController();
    final user = _MockUser();
    when(() => user.uid).thenReturn('uid-123');
    when(() => authRemote.getCurrentUser()).thenReturn(user);
    when(() => backend.deleteAccount()).thenAnswer((_) async {});
    when(() => onboarding.reset(any())).thenAnswer((_) async {});
    when(() => preferences.remove(any())).thenAnswer((_) async => true);
    when(() => authRemote.signOut()).thenAnswer((_) async {});

    final network = _MockNetworkInfo();
    when(() => network.isConnected).thenAnswer((_) async => true);
    repository = AuthRepositoryImpl(
      authRemoteDataSource: authRemote,
      userRemoteDataSource: _MockUserRemoteDataSource(),
      profileImageDataSource: _MockProfileImageDataSource(),
      networkInfo: network,
      accountBackendDataSource: backend,
      preferences: preferences,
      onboardingController: onboarding,
    );
  });

  test('backend failure preserves local session and returns Left', () async {
    when(
      () => backend.deleteAccount(),
    ).thenThrow(const ServerException(message: 'backend failed'));

    final result = await repository.deleteAccount();

    expect(
      result,
      const Left<Failure, void>(ServerFailure(message: 'backend failed')),
    );
    verifyNever(() => onboarding.reset(any()));
    verifyNever(() => preferences.remove(any()));
    verifyNever(() => authRemote.signOut());
  });

  test('backend success cleans local state and signs out', () async {
    final result = await repository.deleteAccount();

    expect(result, const Right<Failure, void>(null));
    verify(() => onboarding.reset('uid-123')).called(1);
    verify(() => preferences.remove('push_device_id')).called(1);
    verify(() => authRemote.signOut()).called(1);
  });

  test(
    'onboarding cleanup failure still removes push state and signs out',
    () async {
      when(
        () => onboarding.reset(any()),
      ).thenThrow(Exception('onboarding failed'));

      final result = await repository.deleteAccount();

      expect(result, const Right<Failure, void>(null));
      verify(() => preferences.remove('push_device_id')).called(1);
      verify(() => authRemote.signOut()).called(1);
    },
  );

  test('push cleanup failure still signs out and returns Right', () async {
    when(
      () => preferences.remove(any()),
    ).thenThrow(Exception('preferences failed'));

    final result = await repository.deleteAccount();

    expect(result, const Right<Failure, void>(null));
    verify(() => authRemote.signOut()).called(1);
  });

  test(
    'sign out failure does not turn a deleted backend account into Left',
    () async {
      when(() => authRemote.signOut()).thenThrow(Exception('sign out failed'));

      final result = await repository.deleteAccount();

      expect(result, const Right<Failure, void>(null));
    },
  );
}
