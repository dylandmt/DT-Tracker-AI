import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/tracker_event_model.dart';

abstract class EventRemoteDataSource {
  Stream<List<TrackerEventModel>> watchEvents(String userId);
  Future<void> updateStatus({
    required String userId,
    required String eventId,
    required bool isRead,
    required String status,
  });
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final FirebaseFirestore firestore;

  EventRemoteDataSourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> _reference(String userId) =>
      firestore.collection('users').doc(userId).collection('events');

  @override
  Stream<List<TrackerEventModel>> watchEvents(String userId) =>
      _reference(userId)
          .orderBy('occurredAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map(TrackerEventModel.fromFirestore).toList(),
          );

  @override
  Future<void> updateStatus({
    required String userId,
    required String eventId,
    required bool isRead,
    required String status,
  }) async {
    try {
      await _reference(
        userId,
      ).doc(eventId).update({'isRead': isRead, 'status': status});
    } on FirebaseException catch (error) {
      throw ServerException(message: error.message ?? 'Failed to update event');
    } catch (error) {
      throw ServerException(message: 'Failed to update event: $error');
    }
  }
}
