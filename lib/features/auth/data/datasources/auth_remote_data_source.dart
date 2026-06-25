import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/exceptions.dart';

/// Remote data source for Firebase Authentication operations
abstract class AuthRemoteDataSource {
  /// Sign in with email and password
  Future<User> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<User> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Sign out
  Future<void> signOut();

  /// Get current Firebase user
  User? getCurrentUser();

  /// Send password reset email
  Future<void> sendPasswordReset({required String email});

  /// Stream of Firebase auth state changes
  Stream<User?> authStateChanges();

  /// Update user display name
  Future<void> updateDisplayName(String displayName);

  /// Update user photo URL
  Future<void> updatePhotoUrl(String photoUrl);
}

/// Implementation of AuthRemoteDataSource using Firebase Auth
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;

  AuthRemoteDataSourceImpl({required this.firebaseAuth});

  @override
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw const AuthException(message: 'Sign in failed. Please try again.');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: e.message ?? 'Sign in failed', code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<User> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw const AuthException(message: 'Sign up failed. Please try again.');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: e.message ?? 'Sign up failed', code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: e.message ?? 'Sign out failed', code: e.code);
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  @override
  User? getCurrentUser() {
    return firebaseAuth.currentUser;
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Failed to send password reset email',
        code: e.code,
      );
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  @override
  Stream<User?> authStateChanges() {
    return firebaseAuth.authStateChanges();
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException(message: 'No user is currently signed in');
      }
      await user.updateDisplayName(displayName);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Failed to update display name',
        code: e.code,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<void> updatePhotoUrl(String photoUrl) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException(message: 'No user is currently signed in');
      }
      await user.updatePhotoURL(photoUrl);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Failed to update photo URL',
        code: e.code,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(message: e.toString());
    }
  }
}
