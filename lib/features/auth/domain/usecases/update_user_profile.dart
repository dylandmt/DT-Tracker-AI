import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateUserProfileParams extends Equatable {
  final String? firstName;
  final String? lastName;
  final String? secondLastName;
  final UserGender? gender;
  final DateTime? birthDate;
  final String? photoUrl;

  const UpdateUserProfileParams({
    this.firstName,
    this.lastName,
    this.secondLastName,
    this.gender,
    this.birthDate,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    secondLastName,
    gender,
    birthDate,
    photoUrl,
  ];
}

class UpdateUserProfile
    implements UseCase<UserEntity, UpdateUserProfileParams> {
  final AuthRepository repository;

  UpdateUserProfile(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(UpdateUserProfileParams params) {
    return repository.updateUserProfile(
      firstName: params.firstName,
      lastName: params.lastName,
      secondLastName: params.secondLastName,
      gender: params.gender,
      birthDate: params.birthDate,
      photoUrl: params.photoUrl,
    );
  }
}
