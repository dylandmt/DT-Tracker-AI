import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateUserProfileParams extends Equatable {
  final String displayName;
  final String? photoUrl;

  const UpdateUserProfileParams({required this.displayName, this.photoUrl});

  @override
  List<Object?> get props => [displayName, photoUrl];
}

class UpdateUserProfile
    implements UseCase<UserEntity, UpdateUserProfileParams> {
  final AuthRepository repository;

  UpdateUserProfile(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(UpdateUserProfileParams params) {
    return repository.updateUserProfile(
      displayName: params.displayName,
      photoUrl: params.photoUrl,
    );
  }
}
