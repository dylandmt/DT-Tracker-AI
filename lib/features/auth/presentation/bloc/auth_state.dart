part of 'auth_bloc.dart';

/// Enum for auth status
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
  passwordResetSent,
}

/// Auth state class
class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  /// Initial state
  factory AuthState.initial() {
    return const AuthState(status: AuthStatus.initial);
  }

  /// Loading state
  factory AuthState.loading() {
    return const AuthState(status: AuthStatus.loading);
  }

  /// Authenticated state
  factory AuthState.authenticated(UserEntity user) {
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
    );
  }

  /// Unauthenticated state
  factory AuthState.unauthenticated() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Error state
  factory AuthState.error(String message) {
    return AuthState(
      status: AuthStatus.error,
      errorMessage: message,
    );
  }

  /// Password reset sent state
  factory AuthState.passwordResetSent() {
    return const AuthState(status: AuthStatus.passwordResetSent);
  }

  /// Create a copy with modified fields
  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  /// Check if currently loading
  bool get isLoading => status == AuthStatus.loading;

  /// Check if authenticated
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Check if unauthenticated
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;

  /// Check if there's an error
  bool get hasError => status == AuthStatus.error;

  @override
  List<Object?> get props => [status, user, errorMessage];
}
