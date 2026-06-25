import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/user_remote_data_source.dart';
import '../models/user_model.dart';

/// Implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource authRemoteDataSource;
  final UserRemoteDataSource userRemoteDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.authRemoteDataSource,
    required this.userRemoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final firebaseUser = await authRemoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );

      UserModel? userModel = await userRemoteDataSource.getUser(firebaseUser.uid);

      if (userModel == null) {
        userModel = UserModel.newUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? email,
          displayName: firebaseUser.displayName,
        );
        await userRemoteDataSource.createUser(userModel);
      }

      return Right(userModel);
    } on AuthException catch (e) {
      return Left(AuthFailure.fromCode(e.code ?? 'unknown'));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final firebaseUser = await authRemoteDataSource.signUpWithEmail(
        email: email,
        password: password,
      );

      if (displayName != null && displayName.isNotEmpty) {
        await authRemoteDataSource.updateDisplayName(displayName);
      }

      final userModel = UserModel.newUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? email,
        displayName: displayName,
      );
      await userRemoteDataSource.createUser(userModel);

      return Right(userModel);
    } on AuthException catch (e) {
      return Left(AuthFailure.fromCode(e.code ?? 'unknown'));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await authRemoteDataSource.signOut();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final firebaseUser = authRemoteDataSource.getCurrentUser();

      if (firebaseUser == null) {
        return const Right(null);
      }

      final userModel = await userRemoteDataSource.getUser(firebaseUser.uid);

      if (userModel == null) {
        final newUser = UserModel.newUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
        );
        await userRemoteDataSource.createUser(newUser);
        return Right(newUser);
      }

      return Right(userModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordReset({required String email}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await authRemoteDataSource.sendPasswordReset(email: email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure.fromCode(e.code ?? 'unknown'));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<UserEntity?> authStateChanges() {
    return authRemoteDataSource.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }

      try {
        final userModel = await userRemoteDataSource.getUser(firebaseUser.uid);

        if (userModel == null) {
          final newUser = UserModel.newUser(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            displayName: firebaseUser.displayName,
          );
          await userRemoteDataSource.createUser(newUser);
          return newUser;
        }

        return userModel;
      } catch (e) {
        return UserModel.newUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
        );
      }
    });
  }

  @override
  Future<Either<Failure, UserEntity>> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final firebaseUser = authRemoteDataSource.getCurrentUser();
      if (firebaseUser == null) {
        return const Left(AuthFailure(message: 'No user is signed in'));
      }

      if (displayName != null) {
        await authRemoteDataSource.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await authRemoteDataSource.updatePhotoUrl(photoUrl);
      }

      var userModel = await userRemoteDataSource.getUser(firebaseUser.uid);
      if (userModel == null) {
        return const Left(NotFoundFailure(message: 'User not found'));
      }

      userModel = UserModel(
        id: userModel.id,
        email: userModel.email,
        displayName: displayName ?? userModel.displayName,
        photoUrl: photoUrl ?? userModel.photoUrl,
        createdAt: userModel.createdAt,
        settings: userModel.settings,
      );
      await userRemoteDataSource.updateUser(userModel);

      return Right(userModel);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUserSettings({
    required UserSettings settings,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final firebaseUser = authRemoteDataSource.getCurrentUser();
      if (firebaseUser == null) {
        return const Left(AuthFailure(message: 'No user is signed in'));
      }

      var userModel = await userRemoteDataSource.getUser(firebaseUser.uid);
      if (userModel == null) {
        return const Left(NotFoundFailure(message: 'User not found'));
      }

      userModel = UserModel(
        id: userModel.id,
        email: userModel.email,
        displayName: userModel.displayName,
        photoUrl: userModel.photoUrl,
        createdAt: userModel.createdAt,
        settings: settings,
      );
      await userRemoteDataSource.updateUser(userModel);

      return Right(userModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
