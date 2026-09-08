import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/profile_image_data_source.dart';
import '../datasources/user_remote_data_source.dart';
import '../models/user_model.dart';

/// Implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource authRemoteDataSource;
  final UserRemoteDataSource userRemoteDataSource;
  final ProfileImageDataSource profileImageDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.authRemoteDataSource,
    required this.userRemoteDataSource,
    required this.profileImageDataSource,
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

      UserModel? userModel = await userRemoteDataSource.getUser(
        firebaseUser.uid,
      );

      if (userModel == null) {
        userModel = UserModel.newUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? email,
          legacyDisplayName: firebaseUser.displayName,
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
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final firebaseUser = await authRemoteDataSource.signInWithGoogle();

      UserModel? userModel = await userRemoteDataSource.getUser(
        firebaseUser.uid,
      );

      if (userModel == null) {
        userModel = UserModel.newUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          legacyDisplayName: firebaseUser.displayName,
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
    required String firstName,
    required String lastName,
    String? secondLastName,
    required UserGender gender,
    required DateTime birthDate,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final firebaseUser = await authRemoteDataSource.signUpWithEmail(
        email: email,
        password: password,
      );

      final displayName = [
        firstName.trim(),
        lastName.trim(),
        secondLastName?.trim(),
      ].whereType<String>().where((value) => value.isNotEmpty).join(' ');

      if (displayName.isNotEmpty) {
        await authRemoteDataSource.updateDisplayName(displayName);
      }

      final userModel = UserModel.newUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? email,
        firstName: firstName,
        lastName: lastName,
        secondLastName: secondLastName,
        gender: gender,
        birthDate: birthDate,
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
          legacyDisplayName: firebaseUser.displayName,
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
  Future<Either<Failure, void>> sendPasswordReset({
    required String email,
  }) async {
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
    return authRemoteDataSource.authStateChanges().asyncMap((
      firebaseUser,
    ) async {
      if (firebaseUser == null) {
        return null;
      }

      try {
        final userModel = await userRemoteDataSource.getUser(firebaseUser.uid);

        if (userModel == null) {
          final newUser = UserModel.newUser(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            legacyDisplayName: firebaseUser.displayName,
          );

          await userRemoteDataSource.createUser(newUser);

          return newUser;
        }

        return userModel;
      } catch (_) {
        return UserModel.newUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          legacyDisplayName: firebaseUser.displayName,
        );
      }
    });
  }

  @override
  Future<Either<Failure, UserEntity>> updateUserProfile({
    String? firstName,
    String? lastName,
    String? secondLastName,
    UserGender? gender,
    DateTime? birthDate,
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

      var userModel = await userRemoteDataSource.getUser(firebaseUser.uid);

      if (userModel == null) {
        return const Left(NotFoundFailure(message: 'User not found'));
      }

      final updatedFirstName = firstName?.trim() ?? userModel.firstName;

      final updatedLastName = lastName?.trim() ?? userModel.lastName;

      final updatedSecondLastName =
          secondLastName?.trim() ?? userModel.secondLastName;

      final updatedGender = gender ?? userModel.gender;

      final updatedBirthDate = birthDate ?? userModel.birthDate;

      final displayName =
          [updatedFirstName, updatedLastName, updatedSecondLastName]
              .whereType<String>()
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .join(' ');

      if (displayName.isNotEmpty && displayName != userModel.displayName) {
        await authRemoteDataSource.updateDisplayName(displayName);
      }

      if (photoUrl != null && photoUrl != userModel.photoUrl) {
        await authRemoteDataSource.updatePhotoUrl(photoUrl);
      }

      userModel = UserModel(
        id: userModel.id,
        email: userModel.email,
        firstName: updatedFirstName,
        lastName: updatedLastName,
        secondLastName: updatedSecondLastName,
        gender: updatedGender,
        birthDate: updatedBirthDate,
        displayName: displayName.isNotEmpty
            ? displayName
            : userModel.displayName,
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
  Future<Either<Failure, String>> uploadProfileImage({
    required String filePath,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final firebaseUser = authRemoteDataSource.getCurrentUser();

      if (firebaseUser == null) {
        return const Left(AuthFailure(message: 'No user is signed in'));
      }

      final imageUrl = await profileImageDataSource.uploadImage(
        userId: firebaseUser.uid,
        filePath: filePath,
      );

      return Right(imageUrl);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProfileImage({
    required String imageUrl,
  }) async {
    try {
      await profileImageDataSource.deleteImage(imageUrl);

      return const Right(null);
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

        // Preserve all profile fields.
        firstName: userModel.firstName,
        lastName: userModel.lastName,
        secondLastName: userModel.secondLastName,
        gender: userModel.gender,
        birthDate: userModel.birthDate,

        displayName: userModel.displayName,
        photoUrl: userModel.photoUrl,
        createdAt: userModel.createdAt,

        // Only settings change here.
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
