import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/tracker_event.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_datasource.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource dataSource;
  final FirebaseAuth firebaseAuth;
  final NetworkInfo networkInfo;

  EventRepositoryImpl({
    required this.dataSource,
    required this.firebaseAuth,
    required this.networkInfo,
  });

  String get _userId {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User not authenticated');
    }
    return user.uid;
  }

  @override
  Stream<Either<Failure, List<TrackerEventEntity>>> watchEvents() {
    try {
      return dataSource
          .watchEvents(_userId)
          .map((events) => Right<Failure, List<TrackerEventEntity>>(events))
          .handleError(
            (Object error) => Left<Failure, List<TrackerEventEntity>>(
              ServerFailure(message: error.toString()),
            ),
          );
    } on AuthException catch (error) {
      return Stream.value(Left(AuthFailure(message: error.message)));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String eventId) =>
      _update(eventId: eventId, isRead: true, status: 'read');

  @override
  Future<Either<Failure, void>> archive(String eventId) =>
      _update(eventId: eventId, isRead: true, status: 'archived');

  Future<Either<Failure, void>> _update({
    required String eventId,
    required bool isRead,
    required String status,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await dataSource.updateStatus(
        userId: _userId,
        eventId: eventId,
        isRead: isRead,
        status: status,
      );
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(message: error.message));
    } on AuthException catch (error) {
      return Left(AuthFailure(message: error.message));
    } catch (error) {
      return Left(UnknownFailure(message: error.toString()));
    }
  }
}
