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

  const SignInRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Event to sign up with email and password
class SignUpRequested extends AuthEvent {
  final String email;
  final String password;

  final String firstName;
  final String lastName;
  final String? secondLastName;

  final UserGender gender;
  final DateTime birthDate;

  const SignUpRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.secondLastName,
    required this.gender,
    required this.birthDate,
  });

  @override
  List<Object?> get props => [
    email,
    password,
    firstName,
    lastName,
    secondLastName,
    gender,
    birthDate,
  ];
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

/// Update the user profile and optionally replace the profile image.
class ProfileUpdateRequested extends AuthEvent {
  final String? firstName;
  final String? lastName;
  final String? secondLastName;

  final UserGender? gender;
  final DateTime? birthDate;

  final String? imagePath;

  const ProfileUpdateRequested({
    this.firstName,
    this.lastName,
    this.secondLastName,
    this.gender,
    this.birthDate,
    this.imagePath,
  });

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    secondLastName,
    gender,
    birthDate,
    imagePath,
  ];
}

class GeofenceAlertPreferenceChanged extends AuthEvent {
  final bool enabled;

  const GeofenceAlertPreferenceChanged(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class EmailNotificationPreferenceChanged extends AuthEvent {
  final bool enabled;

  const EmailNotificationPreferenceChanged(this.enabled);

  @override
  List<Object?> get props => [enabled];
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
