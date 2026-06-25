import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Remote data source for Firestore user document operations
abstract class UserRemoteDataSource {
  /// Create a new user document in Firestore
  Future<void> createUser(UserModel user);

  /// Get user document by ID
  Future<UserModel?> getUser(String userId);

  /// Update user document
  Future<void> updateUser(UserModel user);

  /// Delete user document
  Future<void> deleteUser(String userId);

  /// Stream of user document changes
  Stream<UserModel?> userStream(String userId);
}

/// Implementation of UserRemoteDataSource using Firestore
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore firestore;

  UserRemoteDataSourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      firestore.collection(FirebaseConstants.usersCollection);

  @override
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toJson());
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to create user');
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      return UserModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to get user');
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).update(user.toJson());
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to update user');
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to delete user');
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Stream<UserModel?> userStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return UserModel.fromFirestore(doc);
    });
  }
}
