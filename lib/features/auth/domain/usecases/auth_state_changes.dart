import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for listening to authentication state changes
class AuthStateChanges {
  final AuthRepository repository;

  AuthStateChanges(this.repository);

  Stream<UserEntity?> call(NoParams params) {
    return repository.authStateChanges();
  }
}
