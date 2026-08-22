import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/auth_state_changes.dart';
import '../../domain/usecases/delete_profile_image.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/send_password_reset.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up_with_email.dart';
import '../../domain/usecases/update_user_profile.dart';
import '../../domain/usecases/update_user_settings.dart';
import '../../domain/usecases/upload_profile_image.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC for handling authentication logic
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithEmail signInWithEmail;
  final SignUpWithEmail signUpWithEmail;
  final SignOut signOut;
  final GetCurrentUser getCurrentUser;
  final SendPasswordReset sendPasswordReset;
  final AuthStateChanges authStateChanges;
  final UpdateUserProfile updateUserProfile;
  final UploadProfileImage uploadProfileImage;
  final DeleteProfileImage deleteProfileImage;
  final UpdateUserSettings updateUserSettings;

  StreamSubscription<UserEntity?>? _authStateSubscription;

  AuthBloc({
    required this.signInWithEmail,
    required this.signUpWithEmail,
    required this.signOut,
    required this.getCurrentUser,
    required this.sendPasswordReset,
    required this.authStateChanges,
    required this.updateUserProfile,
    required this.uploadProfileImage,
    required this.deleteProfileImage,
    required this.updateUserSettings,
  }) : super(AuthState.initial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<GeofenceAlertPreferenceChanged>(_onGeofenceAlertPreferenceChanged);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<ClearAuthError>(_onClearAuthError);
  }

  Future<void> _onGeofenceAlertPreferenceChanged(
    GeofenceAlertPreferenceChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = state.user;
    if (user == null) {
      emit(AuthState.error('No user is signed in'));
      return;
    }
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    final result = await updateUserSettings(
      UpdateUserSettingsParams(
        settings: user.settings.copyWith(geofenceAlertEnabled: event.enabled),
      ),
    );
    result.fold(
      (failure) => emit(AuthState.error(failure.message, user: user)),
      (updatedUser) => emit(AuthState.authenticated(updatedUser)),
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    final result = await getCurrentUser(const NoParams());

    result.fold(
      (failure) {
        emit(AuthState.unauthenticated());
      },
      (user) {
        if (user != null) {
          emit(AuthState.authenticated(user));
          _startListeningToAuthChanges();
        } else {
          emit(AuthState.unauthenticated());
        }
      },
    );
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    final result = await signInWithEmail(
      SignInParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) {
        emit(AuthState.error(failure.message));
      },
      (user) {
        emit(AuthState.authenticated(user));
        _startListeningToAuthChanges();
      },
    );
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    final result = await signUpWithEmail(
      SignUpParams(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
        secondLastName: event.secondLastName,
        gender: event.gender,
        birthDate: event.birthDate,
      ),
    );

    result.fold(
      (failure) {
        emit(AuthState.error(failure.message));
      },
      (user) {
        emit(AuthState.authenticated(user));
        _startListeningToAuthChanges();
      },
    );
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    final result = await signOut(const NoParams());

    result.fold(
      (failure) {
        emit(AuthState.error(failure.message));
      },
      (_) {
        _stopListeningToAuthChanges();
        emit(AuthState.unauthenticated());
      },
    );
  }

  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    final result = await sendPasswordReset(
      PasswordResetParams(email: event.email),
    );

    result.fold(
      (failure) {
        emit(AuthState.error(failure.message));
      },
      (_) {
        emit(AuthState.passwordResetSent());
      },
    );
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state.user;
    if (currentUser == null) {
      emit(AuthState.error('No user is signed in'));
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    var photoUrl = currentUser.photoUrl;
    if (event.imagePath != null) {
      final uploadResult = await uploadProfileImage(
        UploadProfileImageParams(filePath: event.imagePath!),
      );
      final uploadFailure = uploadResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (uploadFailure != null) {
        emit(AuthState.error(uploadFailure.message, user: currentUser));
        return;
      }
      photoUrl = uploadResult.getOrElse(() => photoUrl!);
    }

    final updateResult = await updateUserProfile(
      UpdateUserProfileParams(
        firstName: event.firstName,
        lastName: event.lastName,
        secondLastName: event.secondLastName,
        gender: event.gender,
        birthDate: event.birthDate,
        photoUrl: event.imagePath != null ? photoUrl : null,
      ),
    );

    await updateResult.fold(
      (failure) async {
        if (event.imagePath != null && photoUrl != currentUser.photoUrl) {
          await deleteProfileImage(
            DeleteProfileImageParams(imageUrl: photoUrl!),
          );
        }
        emit(AuthState.error(failure.message, user: currentUser));
      },
      (updatedUser) async {
        if (currentUser.photoUrl != null &&
            currentUser.photoUrl != updatedUser.photoUrl) {
          await deleteProfileImage(
            DeleteProfileImageParams(imageUrl: currentUser.photoUrl!),
          );
        }
        emit(AuthState.profileUpdated(updatedUser));
      },
    );
  }

  void _onAuthStateChanged(AuthStateChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(AuthState.authenticated(event.user!));
    } else {
      emit(AuthState.unauthenticated());
    }
  }

  void _onClearAuthError(ClearAuthError event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        status: state.user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        errorMessage: null,
      ),
    );
  }

  void _startListeningToAuthChanges() {
    _authStateSubscription?.cancel();
    _authStateSubscription = authStateChanges(
      const NoParams(),
    ).listen((user) => add(AuthStateChanged(user: user)));
  }

  void _stopListeningToAuthChanges() {
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
  }

  @override
  Future<void> close() {
    _stopListeningToAuthChanges();
    return super.close();
  }
}
