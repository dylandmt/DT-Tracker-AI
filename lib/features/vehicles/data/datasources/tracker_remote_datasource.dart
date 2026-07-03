import 'package:firebase_database/firebase_database.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/tracker_info_model.dart';

/// Abstract interface for tracker remote data source
abstract class TrackerRemoteDataSource {
  /// Get tracker info by IMEI
  Future<TrackerInfoModel?> getTrackerInfo(String imei);

  /// Check if a tracker exists
  Future<bool> trackerExists(String imei);

  /// Check if a tracker is available (exists and not owned)
  Future<bool> isTrackerAvailable(String imei);

  /// Set the tracker owner
  Future<void> setTrackerOwner(String imei, String? ownerId);

  /// Get tracker live data
  Future<TrackerLiveModel> getTrackerLive(String imei);

  /// Stream of tracker live data
  Stream<TrackerLiveModel> watchTrackerLive(String imei);

  /// Get tracker status
  Future<TrackerStatusModel> getTrackerStatus(String imei);

  /// Stream of tracker status
  Stream<TrackerStatusModel> watchTrackerStatus(String imei);
}

/// Implementation of [TrackerRemoteDataSource] using Firebase Realtime Database
class TrackerRemoteDataSourceImpl implements TrackerRemoteDataSource {
  final FirebaseDatabase database;

  TrackerRemoteDataSourceImpl({required this.database});

  /// Reference to trackers_info node
  DatabaseReference _trackersInfoRef(String imei) {
    return database.ref('trackers_info/$imei');
  }

  /// Reference to trackers_live node
  DatabaseReference _trackersLiveRef(String imei) {
    return database.ref('trackers_live/$imei');
  }

  /// Reference to trackers_status node
  DatabaseReference _trackersStatusRef(String imei) {
    return database.ref('trackers_status/$imei');
  }

  @override
  Future<TrackerInfoModel?> getTrackerInfo(String imei) async {
    try {
      final snapshot = await _trackersInfoRef(imei).get();

      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return TrackerInfoModel.fromRtdb(data, imei);
    } catch (e) {
      throw ServerException(message: 'Failed to get tracker info: $e');
    }
  }

  @override
  Future<bool> trackerExists(String imei) async {
    try {
      final snapshot = await _trackersInfoRef(imei).get();
      return snapshot.exists;
    } catch (e) {
      throw ServerException(message: 'Failed to check tracker: $e');
    }
  }

  @override
  Future<bool> isTrackerAvailable(String imei) async {
    try {
      final snapshot = await _trackersInfoRef(imei).get();

      if (!snapshot.exists) {
        return false; // Tracker doesn't exist
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final ownerId = data['ownerId'] as String?;

      return ownerId == null; // Available if no owner
    } catch (e) {
      throw ServerException(message: 'Failed to check tracker availability: $e');
    }
  }

  @override
  Future<void> setTrackerOwner(String imei, String? ownerId) async {
    try {
      await _trackersInfoRef(imei).update({
        'ownerId': ownerId,
        'linkedAt': ownerId != null ? DateTime.now().toIso8601String() : null,
      });
    } catch (e) {
      throw ServerException(message: 'Failed to set tracker owner: $e');
    }
  }

  @override
  Future<TrackerLiveModel> getTrackerLive(String imei) async {
    try {
      final snapshot = await _trackersLiveRef(imei).get();

      if (!snapshot.exists || snapshot.value == null) {
        throw ServerException(message: 'Tracker live data not found');
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return TrackerLiveModel.fromRtdb(data, imei);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to get tracker live data: $e');
    }
  }

  @override
  Stream<TrackerLiveModel> watchTrackerLive(String imei) {
    return _trackersLiveRef(imei).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        throw ServerException(message: 'Tracker live data not found');
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return TrackerLiveModel.fromRtdb(data, imei);
    });
  }

  @override
  Future<TrackerStatusModel> getTrackerStatus(String imei) async {
    try {
      final snapshot = await _trackersStatusRef(imei).get();

      if (!snapshot.exists || snapshot.value == null) {
        throw ServerException(message: 'Tracker status not found');
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return TrackerStatusModel.fromRtdb(data, imei);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to get tracker status: $e');
    }
  }

  @override
  Stream<TrackerStatusModel> watchTrackerStatus(String imei) {
    return _trackersStatusRef(imei).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        throw ServerException(message: 'Tracker status not found');
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return TrackerStatusModel.fromRtdb(data, imei);
    });
  }
}
