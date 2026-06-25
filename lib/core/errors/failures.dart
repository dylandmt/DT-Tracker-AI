import 'package:equatable/equatable.dart';

/// Base failure class for error handling with Either
abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Server-side failures
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    super.message = 'Server error occurred. Please try again.',
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

/// Local cache failures
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Cache error occurred. Please try again.',
  });
}

/// Network connectivity failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
  });
}

/// Authentication failures
class AuthFailure extends Failure {
  final String? code;

  const AuthFailure({
    super.message = 'Authentication failed. Please try again.',
    this.code,
  });

  @override
  List<Object?> get props => [message, code];

  /// Factory to create AuthFailure from Firebase error codes
  factory AuthFailure.fromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return const AuthFailure(
          message: 'The email address is invalid.',
          code: 'invalid-email',
        );
      case 'user-disabled':
        return const AuthFailure(
          message: 'This account has been disabled.',
          code: 'user-disabled',
        );
      case 'user-not-found':
        return const AuthFailure(
          message: 'No account found with this email.',
          code: 'user-not-found',
        );
      case 'wrong-password':
        return const AuthFailure(
          message: 'Incorrect password. Please try again.',
          code: 'wrong-password',
        );
      case 'email-already-in-use':
        return const AuthFailure(
          message: 'An account already exists with this email.',
          code: 'email-already-in-use',
        );
      case 'weak-password':
        return const AuthFailure(
          message: 'Password is too weak. Use at least 6 characters.',
          code: 'weak-password',
        );
      case 'operation-not-allowed':
        return const AuthFailure(
          message: 'This operation is not allowed.',
          code: 'operation-not-allowed',
        );
      case 'too-many-requests':
        return const AuthFailure(
          message: 'Too many attempts. Please try again later.',
          code: 'too-many-requests',
        );
      case 'invalid-credential':
        return const AuthFailure(
          message: 'Invalid credentials. Please check and try again.',
          code: 'invalid-credential',
        );
      default:
        return AuthFailure(
          message: 'Authentication failed: $code',
          code: code,
        );
    }
  }
}

/// Location-related failures
class LocationFailure extends Failure {
  const LocationFailure({
    super.message = 'Failed to get location. Please try again.',
  });
}

/// Permission-related failures
class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'Permission denied. Please grant the required permissions.',
  });
}

/// Validation failures
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    super.message = 'Validation failed. Please check your input.',
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, fieldErrors];
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'The requested resource was not found.',
  });
}

/// Unknown/unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred. Please try again.',
  });
}
