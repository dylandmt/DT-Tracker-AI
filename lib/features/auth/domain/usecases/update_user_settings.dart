import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateUserSettingsParams extends Equatable {
  final UserSettings settings;

  const UpdateUserSettingsParams({required this.settings});

  @override
  List<Object?> get props => [settings];
}

class UpdateUserSettings
    implements UseCase<UserEntity, UpdateUserSettingsParams> {
  final AuthRepository repository;

  UpdateUserSettings(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(UpdateUserSettingsParams params) =>
      repository.updateUserSettings(settings: params.settings);
}
