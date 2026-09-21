import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dt_tracker_ai/core/errors/failures.dart';
import 'package:dt_tracker_ai/features/auth/domain/entities/user.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/auth_state_changes.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/delete_profile_image.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/get_current_user.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/send_password_reset.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/sign_out.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/update_user_profile.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/update_user_settings.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/upload_profile_image.dart';
import 'package:dt_tracker_ai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dt_tracker_ai/features/auth/domain/usecases/sign_in_with_google.dart';

class MockSignInWithEmail extends Mock implements SignInWithEmail {}

class MockSignInWithGoogle extends Mock implements SignInWithGoogle {}

class MockSignUpWithEmail extends Mock implements SignUpWithEmail {}

class MockSignOut extends Mock implements SignOut {}

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockSendPasswordReset extends Mock implements SendPasswordReset {}

class MockAuthStateChanges extends Mock implements AuthStateChanges {}

class MockUpdateUserProfile extends Mock implements UpdateUserProfile {}

class MockUploadProfileImage extends Mock implements UploadProfileImage {}

class MockDeleteProfileImage extends Mock implements DeleteProfileImage {}

class MockUpdateUserSettings extends Mock implements UpdateUserSettings {}

void main() {
  late MockUpdateUserSettings updateUserSettings;

  final user = UserEntity(
    id: 'user-id',
    email: 'user@example.com',
    createdAt: DateTime(2026),
    settings: const UserSettings(
      speedAlertEnabled: false,
      speedLimitKmh: 95,
      geofenceAlertEnabled: false,
      pushNotificationsEnabled: false,
      emailNotificationsEnabled: false,
    ),
  );
  final updatedUser = UserEntity(
    id: user.id,
    email: user.email,
    createdAt: user.createdAt,
    settings: user.settings.copyWith(emailNotificationsEnabled: true),
  );

  setUpAll(() {
    registerFallbackValue(
      const UpdateUserSettingsParams(settings: UserSettings()),
    );
  });

  setUp(() {
    updateUserSettings = MockUpdateUserSettings();
    when(
      () => updateUserSettings(any()),
    ).thenAnswer((_) async => Right<Failure, UserEntity>(updatedUser));
  });

  AuthBloc buildBloc() => AuthBloc(
    signInWithEmail: MockSignInWithEmail(),
    signInWithGoogle: MockSignInWithGoogle(),
    signUpWithEmail: MockSignUpWithEmail(),
    signOut: MockSignOut(),
    getCurrentUser: MockGetCurrentUser(),
    sendPasswordReset: MockSendPasswordReset(),
    authStateChanges: MockAuthStateChanges(),
    updateUserProfile: MockUpdateUserProfile(),
    uploadProfileImage: MockUploadProfileImage(),
    deleteProfileImage: MockDeleteProfileImage(),
    updateUserSettings: updateUserSettings,
  );

  blocTest<AuthBloc, AuthState>(
    'changes only the email notification preference',
    build: buildBloc,
    act: (bloc) {
      bloc.add(AuthStateChanged(user: user));
      bloc.add(const EmailNotificationPreferenceChanged(true));
    },
    expect: () => [
      AuthState.authenticated(user),
      AuthState(status: AuthStatus.loading, user: user),
      AuthState.authenticated(updatedUser),
    ],
    verify: (_) {
      final params =
          verify(() => updateUserSettings(captureAny())).captured.single
              as UpdateUserSettingsParams;
      expect(params.settings.speedAlertEnabled, isFalse);
      expect(params.settings.speedLimitKmh, 95);
      expect(params.settings.geofenceAlertEnabled, isFalse);
      expect(params.settings.pushNotificationsEnabled, isFalse);
      expect(params.settings.emailNotificationsEnabled, isTrue);
    },
  );
}
