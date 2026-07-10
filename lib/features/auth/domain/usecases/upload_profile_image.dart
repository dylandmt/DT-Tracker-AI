import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class UploadProfileImageParams extends Equatable {
  final String filePath;

  const UploadProfileImageParams({required this.filePath});

  @override
  List<Object?> get props => [filePath];
}

class UploadProfileImage implements UseCase<String, UploadProfileImageParams> {
  final AuthRepository repository;

  UploadProfileImage(this.repository);

  @override
  Future<Either<Failure, String>> call(UploadProfileImageParams params) {
    return repository.uploadProfileImage(filePath: params.filePath);
  }
}
