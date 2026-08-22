import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing up with email and password.
class SignUpWithEmail implements UseCase<UserEntity, SignUpParams> {
  final AuthRepository repository;

  SignUpWithEmail(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) async {
    return await repository.signUpWithEmail(
      email: params.email,
      password: params.password,
      firstName: params.firstName,
      lastName: params.lastName,
      secondLastName: params.secondLastName,
      gender: params.gender,
      birthDate: params.birthDate,
    );
  }
}

/// Parameters for sign up.
class SignUpParams extends Equatable {
  final String email;
  final String password;

  final String firstName;
  final String lastName;
  final String? secondLastName;

  final UserGender gender;
  final DateTime birthDate;

  const SignUpParams({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.secondLastName,
    required this.gender,
    required this.birthDate,
  });

  @override
  List<Object?> get props => [
    email,
    password,
    firstName,
    lastName,
    secondLastName,
    gender,
    birthDate,
  ];
}
