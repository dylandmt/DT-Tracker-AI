part of 'auth_bloc.dart';

/// Base class for all auth events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check current auth status
class CheckAuthStatus extends AuthEvent {}

/// Event to sign in with email and password
class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Event to sign up with email and password
class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;

  const SignUpRequested({
    required this.email,
    required this.password,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Event to sign out
class SignOutRequested extends AuthEvent {}

/// Event to send password reset email
class PasswordResetRequested extends AuthEvent {
  final String email;

  const PasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Event when auth state changes (from stream)
class AuthStateChanged extends AuthEvent {
  final UserEntity? user;

  const AuthStateChanged({this.user});

  @override
  List<Object?> get props => [user];
}

/// Event to clear any error message
class ClearAuthError extends AuthEvent {}
