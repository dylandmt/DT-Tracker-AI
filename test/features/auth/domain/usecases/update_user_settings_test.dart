import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dt_tracker_ai/core/errors/failures.dart';
import 'package:dt_tracker_ai/features/auth/domain/entities/user.dart';
import 'package:dt_tracker_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/update_user_settings.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('forwards the geofence alert preference to the repository', () async {
    final repository = MockAuthRepository();
    final useCase = UpdateUserSettings(repository);
    const settings = UserSettings(geofenceAlertEnabled: false);
    final user = UserEntity(
      id: 'user-id',
      email: 'user@example.com',
      createdAt: DateTime(2026),
      settings: settings,
    );
    when(
      () => repository.updateUserSettings(settings: settings),
    ).thenAnswer((_) async => Right<Failure, UserEntity>(user));

    final result = await useCase(
      const UpdateUserSettingsParams(settings: settings),
    );

    expect(result, Right<Failure, UserEntity>(user));
    verify(() => repository.updateUserSettings(settings: settings)).called(1);
  });
}
