import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Use case for sending password reset email
class SendPasswordReset implements UseCase<void, PasswordResetParams> {
  final AuthRepository repository;

  SendPasswordReset(this.repository);

  @override
  Future<Either<Failure, void>> call(PasswordResetParams params) async {
    return await repository.sendPasswordReset(email: params.email);
  }
}

/// Parameters for password reset
class PasswordResetParams extends Equatable {
  final String email;

  const PasswordResetParams({required this.email});

  @override
  List<Object?> get props => [email];
}
