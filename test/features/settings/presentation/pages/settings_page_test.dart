import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dt_tracker_ai/core/localization/locale_controller.dart';
import 'package:dt_tracker_ai/core/theme/theme_controller.dart';
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
import 'package:dt_tracker_ai/features/settings/presentation/pages/settings_page.dart';
import 'package:dt_tracker_ai/injection_container.dart';
import 'package:dt_tracker_ai/l10n/app_localizations.dart';

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

class _TestAuthBloc extends AuthBloc {
  _TestAuthBloc(AuthState initialState)
    : super(
        signInWithEmail: _MockSignInWithEmail(),
        signInWithGoogle: _MockSignInWithGoogle(),
        signUpWithEmail: _MockSignUpWithEmail(),
        signOut: _MockSignOut(),
        deleteAccount: _MockDeleteAccount(),
        getCurrentUser: _MockGetCurrentUser(),
        sendPasswordReset: _MockSendPasswordReset(),
        authStateChanges: _MockAuthStateChanges(),
        updateUserProfile: _MockUpdateUserProfile(),
        uploadProfileImage: _MockUploadProfileImage(),
        deleteProfileImage: _MockDeleteProfileImage(),
        updateUserSettings: _MockUpdateUserSettings(),
      ) {
    emit(initialState);
  }

  final events = <AuthEvent>[];

  @override
  void add(AuthEvent event) {
    events.add(event);
  }

  void emitState(AuthState state) => emit(state);
}

void main() {
  late _TestAuthBloc bloc;

  final user = UserEntity(
    id: 'uid-123',
    email: 'user@example.com',
    createdAt: DateTime(2026),
    settings: const UserSettings(),
  );

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    sl.registerSingleton<LocaleController>(LocaleController(preferences));
    sl.registerSingleton<ThemeController>(ThemeController(preferences));

    bloc = _TestAuthBloc(AuthState.initial());
  });

  tearDown(() async {
    await bloc.close();
    await sl.reset();
  });

  Future<void> pumpSettings(WidgetTester tester, AuthState initialState) async {
    bloc.emitState(initialState);
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (_, _) => BlocProvider<AuthBloc>.value(
            value: bloc,
            child: const SettingsPage(),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Login page')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pump();
    if (!initialState.accountDeletionInProgress) {
      await tester.pumpAndSettle();
    }
  }

  Finder deleteAccountTile() => find.widgetWithText(ListTile, 'Delete account');

  testWidgets('shows account deletion for an authenticated user', (
    tester,
  ) async {
    await pumpSettings(tester, AuthState.authenticated(user));

    expect(deleteAccountTile(), findsOneWidget);
  });

  testWidgets('opens confirmation and cancel does not send an event', (
    tester,
  ) async {
    await pumpSettings(tester, AuthState.authenticated(user));

    await tester.tap(deleteAccountTile());
    await tester.pumpAndSettle();
    expect(find.text('Delete account?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete account?'), findsNothing);
    expect(bloc.events, isEmpty);
  });

  testWidgets('confirming deletion sends exactly one account deletion event', (
    tester,
  ) async {
    await pumpSettings(tester, AuthState.authenticated(user));

    await tester.tap(deleteAccountTile());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
    await tester.pumpAndSettle();

    expect(bloc.events, hasLength(1));
    expect(bloc.events.single, isA<AccountDeletionRequested>());
  });

  testWidgets('disables account deletion while auth is loading', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      AuthState(status: AuthStatus.loading, user: user),
    );

    await tester.tap(deleteAccountTile());
    await tester.pumpAndSettle();
    expect(find.text('Delete account?'), findsNothing);
    expect(bloc.events, isEmpty);
  });

  testWidgets('blocks all settings interaction during account deletion', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      AuthState(
        status: AuthStatus.loading,
        user: user,
        accountDeletionInProgress: true,
      ),
    );

    expect(find.byType(ModalBarrier), findsAtLeastNWidgets(1));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Deleting account...'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(ListTile, 'Profile'),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(bloc.events, isEmpty);
  });

  testWidgets('error preserves settings and user without navigating to login', (
    tester,
  ) async {
    await pumpSettings(tester, AuthState.authenticated(user));

    bloc.emitState(AuthState.error('Deletion failed', user: user));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.text('Deletion failed'), findsOneWidget);
    expect(find.text('Login page'), findsNothing);
  });

  testWidgets('unauthenticated state navigates to login', (tester) async {
    await pumpSettings(tester, AuthState.authenticated(user));

    bloc.emitState(AuthState.unauthenticated());
    await tester.pumpAndSettle();

    expect(find.text('Login page'), findsOneWidget);
  });
}
