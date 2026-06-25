import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/auth_state_changes.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/send_password_reset.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up_with_email.dart';

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

  StreamSubscription<UserEntity?>? _authStateSubscription;

  AuthBloc({
    required this.signInWithEmail,
    required this.signUpWithEmail,
    required this.signOut,
    required this.getCurrentUser,
    required this.sendPasswordReset,
    required this.authStateChanges,
  }) : super(AuthState.initial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<ClearAuthError>(_onClearAuthError);
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
        displayName: event.displayName,
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

  void _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      emit(AuthState.authenticated(event.user!));
    } else {
      emit(AuthState.unauthenticated());
    }
  }

  void _onClearAuthError(
    ClearAuthError event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      status: state.user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      errorMessage: null,
    ));
  }

  void _startListeningToAuthChanges() {
    _authStateSubscription?.cancel();
    _authStateSubscription = authStateChanges(const NoParams()).listen(
      (user) => add(AuthStateChanged(user: user)),
    );
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
