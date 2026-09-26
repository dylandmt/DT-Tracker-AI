import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dt_tracker_ai/core/errors/failures.dart';
import 'package:dt_tracker_ai/core/usecases/usecase.dart';
import 'package:dt_tracker_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/delete_account.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('delegates account deletion to the repository', () async {
    final repository = MockAuthRepository();
    final useCase = DeleteAccount(repository);
    when(
      () => repository.deleteAccount(),
    ).thenAnswer((_) async => const Right<Failure, void>(null));

    final result = await useCase(const NoParams());

    expect(result, const Right<Failure, void>(null));
    verify(() => repository.deleteAccount()).called(1);
  });
}
