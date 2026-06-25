import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

/// Abstract repository for authentication operations
abstract class AuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sign out the current user
  Future<Either<Failure, void>> signOut();

  /// Get the currently authenticated user
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordReset({required String email});

  /// Stream of authentication state changes
  Stream<UserEntity?> authStateChanges();

  /// Update user profile
  Future<Either<Failure, UserEntity>> updateUserProfile({
    String? displayName,
    String? photoUrl,
  });

  /// Update user settings
  Future<Either<Failure, UserEntity>> updateUserSettings({
    required UserSettings settings,
  });
}
