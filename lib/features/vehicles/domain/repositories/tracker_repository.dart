import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/tracker_info.dart';

/// Repository interface for tracker operations
abstract class TrackerRepository {
  /// Get tracker info by IMEI
  ///
  /// Returns [TrackerInfoEntity] on success or [Failure] on error
  Future<Either<Failure, TrackerInfoEntity>> getTrackerInfo(String imei);

  /// Check if a tracker exists in the database
  ///
  /// Returns true if the tracker exists, false otherwise
  Future<Either<Failure, bool>> trackerExists(String imei);

  /// Check if a tracker is available for linking (exists and not owned)
  ///
  /// Returns true if available, false if owned or doesn't exist
  Future<Either<Failure, bool>> isTrackerAvailable(String imei);

  /// Link a tracker to a user (set ownerId in RTDB)
  ///
  /// [imei] - The tracker IMEI
  /// [userId] - The user's Firebase Auth UID
  ///
  /// Returns void on success or [Failure] on error
  Future<Either<Failure, void>> linkTrackerToUser({
    required String imei,
    required String userId,
  });

  /// Unlink a tracker from a user (clear ownerId in RTDB)
  ///
  /// [imei] - The tracker IMEI to unlink
  ///
  /// Returns void on success or [Failure] on error
  Future<Either<Failure, void>> unlinkTrackerFromUser(String imei);

  /// Get live tracker data
  ///
  /// Returns [TrackerLiveEntity] on success or [Failure] on error
  Future<Either<Failure, TrackerLiveEntity>> getTrackerLive(String imei);

  /// Stream of live tracker data for real-time updates
  ///
  /// Returns a stream that emits [TrackerLiveEntity] on changes
  Stream<Either<Failure, TrackerLiveEntity>> watchTrackerLive(String imei);

  /// Get tracker status
  ///
  /// Returns [TrackerStatusEntity] on success or [Failure] on error
  Future<Either<Failure, TrackerStatusEntity>> getTrackerStatus(String imei);

  /// Stream of tracker status for real-time updates
  ///
  /// Returns a stream that emits [TrackerStatusEntity] on changes
  Stream<Either<Failure, TrackerStatusEntity>> watchTrackerStatus(String imei);
}
