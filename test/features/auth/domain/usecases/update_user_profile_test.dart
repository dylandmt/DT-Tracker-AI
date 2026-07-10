import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dt_tracker_ai/core/errors/failures.dart';
import 'package:dt_tracker_ai/features/auth/domain/entities/user.dart';
import 'package:dt_tracker_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/update_user_profile.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late UpdateUserProfile useCase;

  final user = UserEntity(
    id: 'user-id',
    email: 'user@example.com',
    displayName: 'Updated User',
    photoUrl: 'https://example.com/profile.jpg',
    createdAt: DateTime(2026),
    settings: const UserSettings(),
  );

  setUp(() {
    repository = MockAuthRepository();
    useCase = UpdateUserProfile(repository);
  });

  test(
    'forwards display name and profile photo URL to the repository',
    () async {
      when(
        () => repository.updateUserProfile(
          displayName: 'Updated User',
          photoUrl: 'https://example.com/profile.jpg',
        ),
      ).thenAnswer((_) async => Right<Failure, UserEntity>(user));

      final result = await useCase(
        const UpdateUserProfileParams(
          displayName: 'Updated User',
          photoUrl: 'https://example.com/profile.jpg',
        ),
      );

      expect(result, Right<Failure, UserEntity>(user));
      verify(
        () => repository.updateUserProfile(
          displayName: 'Updated User',
          photoUrl: 'https://example.com/profile.jpg',
        ),
      ).called(1);
    },
  );
}
