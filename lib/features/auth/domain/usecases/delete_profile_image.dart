import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class DeleteProfileImageParams extends Equatable {
  final String imageUrl;

  const DeleteProfileImageParams({required this.imageUrl});

  @override
  List<Object?> get props => [imageUrl];
}

class DeleteProfileImage implements UseCase<void, DeleteProfileImageParams> {
  final AuthRepository repository;

  DeleteProfileImage(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteProfileImageParams params) {
    return repository.deleteProfileImage(imageUrl: params.imageUrl);
  }
}
