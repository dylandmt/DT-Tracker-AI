import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dt_tracker_ai/core/errors/failures.dart';
import 'package:dt_tracker_ai/core/usecases/usecase.dart';
import 'package:dt_tracker_ai/features/auth/domain/entities/user.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/auth_state_changes.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/delete_account.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/delete_profile_image.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/get_current_user.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/send_password_reset.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/sign_out.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/update_user_profile.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/update_user_settings.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/upload_profile_image.dart';
import 'package:dt_tracker_ai/features/auth/presentation/bloc/auth_bloc.dart';

class _MockSignInWithEmail extends Mock implements SignInWithEmail {}

class _MockSignInWithGoogle extends Mock implements SignInWithGoogle {}

class _MockSignUpWithEmail extends Mock implements SignUpWithEmail {}

class _MockSignOut extends Mock implements SignOut {}

class _MockDeleteAccount extends Mock implements DeleteAccount {}

class _MockGetCurrentUser extends Mock implements GetCurrentUser {}

class _MockSendPasswordReset extends Mock implements SendPasswordReset {}

class _MockAuthStateChanges extends Mock implements AuthStateChanges {}

class _MockUpdateUserProfile extends Mock implements UpdateUserProfile {}

class _MockUploadProfileImage extends Mock implements UploadProfileImage {}

class _MockDeleteProfileImage extends Mock implements DeleteProfileImage {}

class _MockUpdateUserSettings extends Mock implements UpdateUserSettings {}

void main() {
  final user = UserEntity(
    id: 'uid-123',
    email: 'user@example.com',
    createdAt: DateTime(2026),
    settings: const UserSettings(),
  );

  AuthBloc buildBloc(DeleteAccount deleteAccount) => AuthBloc(
    signInWithEmail: _MockSignInWithEmail(),
    signInWithGoogle: _MockSignInWithGoogle(),
    signUpWithEmail: _MockSignUpWithEmail(),
    signOut: _MockSignOut(),
    deleteAccount: deleteAccount,
    getCurrentUser: _MockGetCurrentUser(),
    sendPasswordReset: _MockSendPasswordReset(),
    authStateChanges: _MockAuthStateChanges(),
    updateUserProfile: _MockUpdateUserProfile(),
    uploadProfileImage: _MockUploadProfileImage(),
    deleteProfileImage: _MockDeleteProfileImage(),
    updateUserSettings: _MockUpdateUserSettings(),
  );

  blocTest<AuthBloc, AuthState>(
    'keeps the user when backend account deletion fails',
    build: () {
      final deleteAccount = _MockDeleteAccount();
      when(() => deleteAccount(const NoParams())).thenAnswer(
        (_) async =>
            const Left<Failure, void>(ServerFailure(message: 'backend failed')),
      );
      return buildBloc(deleteAccount);
    },
    act: (bloc) {
      bloc.add(AuthStateChanged(user: user));
      bloc.add(AccountDeletionRequested());
    },
    expect: () => [
      AuthState.authenticated(user),
      AuthState(
        status: AuthStatus.loading,
        user: user,
        accountDeletionInProgress: true,
      ),
      AuthState.error('backend failed', user: user),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits unauthenticated after backend account deletion succeeds',
    build: () {
      final deleteAccount = _MockDeleteAccount();
      when(
        () => deleteAccount(const NoParams()),
      ).thenAnswer((_) async => const Right<Failure, void>(null));
      return buildBloc(deleteAccount);
    },
    act: (bloc) {
      bloc.add(AuthStateChanged(user: user));
      bloc.add(AccountDeletionRequested());
    },
    expect: () => [
      AuthState.authenticated(user),
      AuthState(
        status: AuthStatus.loading,
        user: user,
        accountDeletionInProgress: true,
      ),
      AuthState.unauthenticated(),
    ],
  );
}
