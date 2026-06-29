import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/trip_point_model.dart';
import '../models/vehicle_location_model.dart';

/// Abstract interface for map remote data source
abstract class MapRemoteDataSource {
  /// Get all vehicle locations for the current user
  Future<List<VehicleLocationModel>> getVehicleLocations();

  /// Stream of all vehicle locations for real-time updates
  Stream<List<VehicleLocationModel>> watchVehicleLocations();

  /// Get single vehicle location by vehicle ID
  Future<VehicleLocationModel> getVehicleLocation(String vehicleId);

  /// Stream of single vehicle location
  Stream<VehicleLocationModel> watchVehicleLocation(String vehicleId);

  /// Get trip history points for a date range
  Future<List<TripPointModel>> getTripPoints({
    required String trackerId,
    required DateTime startDate,
    required DateTime endDate,
  });
}

/// Implementation of [MapRemoteDataSource]
class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseDatabase database;
  final FirebaseAuth firebaseAuth;

  MapRemoteDataSourceImpl({
    required this.firestore,
    required this.database,
    required this.firebaseAuth,
  });

  String get _userId {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User not authenticated');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _vehiclesCollection {
    return firestore.collection('users').doc(_userId).collection('vehicles');
  }

  DatabaseReference _trackerLiveRef(String imei) {
    return database.ref('trackers_live/$imei');
  }

  DatabaseReference _trackerHistoryRef(String imei) {
    return database.ref('trackers_history/$imei');
  }

  @override
  Future<List<VehicleLocationModel>> getVehicleLocations() async {
    try {
      // Get all vehicles with trackers
      final vehiclesSnapshot = await _vehiclesCollection
          .where('trackerId', isNull: false)
          .get();

      if (vehiclesSnapshot.docs.isEmpty) {
        return [];
      }

      final locations = <VehicleLocationModel>[];

      // For each vehicle, get the tracker live data
      for (final vehicleDoc in vehiclesSnapshot.docs) {
        final vehicleData = vehicleDoc.data();
        final trackerId = vehicleData['trackerId'] as String?;

        if (trackerId == null || trackerId.isEmpty) continue;

        try {
          final trackerSnapshot = await _trackerLiveRef(trackerId).get();

          if (trackerSnapshot.exists && trackerSnapshot.value != null) {
            final trackerData =
                trackerSnapshot.value as Map<dynamic, dynamic>;

            locations.add(VehicleLocationModel.fromVehicleAndTracker(
              vehicleId: vehicleDoc.id,
              vehicleName: vehicleData['name'] as String? ?? 'Unknown',
              plateNumber: vehicleData['plateNumber'] as String? ?? '',
              color: vehicleData['color'] as String?,
              imageUrl: (vehicleData['imageUrls'] as List?)?.isNotEmpty == true
                  ? (vehicleData['imageUrls'] as List).first as String?
                  : null,
              trackerId: trackerId,
              trackerLiveData: trackerData,
            ));
          }
        } catch (e) {
          // Skip this tracker if there's an error
          continue;
        }
      }

      return locations;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(message: 'Failed to get vehicle locations: $e');
    }
  }

  @override
  Stream<List<VehicleLocationModel>> watchVehicleLocations() {
    final controller = StreamController<List<VehicleLocationModel>>();
    final subscriptions = <StreamSubscription>[];
    Map<String, VehicleLocationModel> vehicleLocations = {};
    Map<String, Map<String, dynamic>> vehicleInfoCache = {};

    // First, get all vehicles with trackers
    _vehiclesCollection
        .where('trackerId', isNull: false)
        .snapshots()
        .listen(
      (vehiclesSnapshot) {
        // Cancel old tracker subscriptions
        for (final sub in subscriptions) {
          sub.cancel();
        }
        subscriptions.clear();
        vehicleLocations.clear();
        vehicleInfoCache.clear();

        if (vehiclesSnapshot.docs.isEmpty) {
          controller.add([]);
          return;
        }

        // Cache vehicle info and subscribe to each tracker
        for (final vehicleDoc in vehiclesSnapshot.docs) {
          final vehicleData = vehicleDoc.data();
          final trackerId = vehicleData['trackerId'] as String?;

          if (trackerId == null || trackerId.isEmpty) continue;

          // Cache vehicle info
          vehicleInfoCache[trackerId] = {
            'vehicleId': vehicleDoc.id,
            'vehicleName': vehicleData['name'] as String? ?? 'Unknown',
            'plateNumber': vehicleData['plateNumber'] as String? ?? '',
            'color': vehicleData['color'] as String?,
            'imageUrl':
                (vehicleData['imageUrls'] as List?)?.isNotEmpty == true
                    ? (vehicleData['imageUrls'] as List).first as String?
                    : null,
            'trackerId': trackerId,
          };

          // Subscribe to tracker live data
          final subscription = _trackerLiveRef(trackerId).onValue.listen(
            (event) {
              if (event.snapshot.exists && event.snapshot.value != null) {
                final trackerData =
                    event.snapshot.value as Map<dynamic, dynamic>;
                final vehicleInfo = vehicleInfoCache[trackerId];

                if (vehicleInfo != null) {
                  final location = VehicleLocationModel.fromVehicleAndTracker(
                    vehicleId: vehicleInfo['vehicleId'] as String,
                    vehicleName: vehicleInfo['vehicleName'] as String,
                    plateNumber: vehicleInfo['plateNumber'] as String,
                    color: vehicleInfo['color'] as String?,
                    imageUrl: vehicleInfo['imageUrl'] as String?,
                    trackerId: trackerId,
                    trackerLiveData: trackerData,
                  );

                  vehicleLocations[vehicleInfo['vehicleId'] as String] =
                      location;
                  controller.add(vehicleLocations.values.toList());
                }
              }
            },
            onError: (error) {
              // Remove from locations on error
              final vehicleInfo = vehicleInfoCache[trackerId];
              if (vehicleInfo != null) {
                vehicleLocations.remove(vehicleInfo['vehicleId'] as String);
                controller.add(vehicleLocations.values.toList());
              }
            },
          );

          subscriptions.add(subscription);
        }
      },
      onError: (error) {
        controller.addError(
          ServerException(message: 'Failed to watch vehicles: $error'),
        );
      },
    );

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  @override
  Future<VehicleLocationModel> getVehicleLocation(String vehicleId) async {
    try {
      // Get vehicle data
      final vehicleDoc = await _vehiclesCollection.doc(vehicleId).get();

      if (!vehicleDoc.exists) {
        throw const ServerException(message: 'Vehicle not found');
      }

      final vehicleData = vehicleDoc.data()!;
      final trackerId = vehicleData['trackerId'] as String?;

      if (trackerId == null || trackerId.isEmpty) {
        throw const ServerException(message: 'Vehicle has no linked tracker');
      }

      // Get tracker live data
      final trackerSnapshot = await _trackerLiveRef(trackerId).get();

      if (!trackerSnapshot.exists || trackerSnapshot.value == null) {
        throw const ServerException(message: 'Tracker data not found');
      }

      final trackerData = trackerSnapshot.value as Map<dynamic, dynamic>;

      return VehicleLocationModel.fromVehicleAndTracker(
        vehicleId: vehicleDoc.id,
        vehicleName: vehicleData['name'] as String? ?? 'Unknown',
        plateNumber: vehicleData['plateNumber'] as String? ?? '',
        color: vehicleData['color'] as String?,
        imageUrl: (vehicleData['imageUrls'] as List?)?.isNotEmpty == true
            ? (vehicleData['imageUrls'] as List).first as String?
            : null,
        trackerId: trackerId,
        trackerLiveData: trackerData,
      );
    } catch (e) {
      if (e is ServerException || e is AuthException) rethrow;
      throw ServerException(message: 'Failed to get vehicle location: $e');
    }
  }

  @override
  Stream<VehicleLocationModel> watchVehicleLocation(String vehicleId) {
    final controller = StreamController<VehicleLocationModel>();
    StreamSubscription? trackerSubscription;
    Map<String, dynamic>? vehicleInfo;

    // First get and watch vehicle data
    _vehiclesCollection.doc(vehicleId).snapshots().listen(
      (vehicleDoc) {
        if (!vehicleDoc.exists) {
          controller.addError(
            const ServerException(message: 'Vehicle not found'),
          );
          return;
        }

        final vehicleData = vehicleDoc.data()!;
        final trackerId = vehicleData['trackerId'] as String?;

        if (trackerId == null || trackerId.isEmpty) {
          controller.addError(
            const ServerException(message: 'Vehicle has no linked tracker'),
          );
          return;
        }

        // Update vehicle info
        vehicleInfo = {
          'vehicleId': vehicleDoc.id,
          'vehicleName': vehicleData['name'] as String? ?? 'Unknown',
          'plateNumber': vehicleData['plateNumber'] as String? ?? '',
          'color': vehicleData['color'] as String?,
          'imageUrl': (vehicleData['imageUrls'] as List?)?.isNotEmpty == true
              ? (vehicleData['imageUrls'] as List).first as String?
              : null,
          'trackerId': trackerId,
        };

        // Cancel old subscription if tracker changed
        trackerSubscription?.cancel();

        // Subscribe to new tracker
        trackerSubscription = _trackerLiveRef(trackerId).onValue.listen(
          (event) {
            if (event.snapshot.exists &&
                event.snapshot.value != null &&
                vehicleInfo != null) {
              final trackerData =
                  event.snapshot.value as Map<dynamic, dynamic>;

              controller.add(VehicleLocationModel.fromVehicleAndTracker(
                vehicleId: vehicleInfo!['vehicleId'] as String,
                vehicleName: vehicleInfo!['vehicleName'] as String,
                plateNumber: vehicleInfo!['plateNumber'] as String,
                color: vehicleInfo!['color'] as String?,
                imageUrl: vehicleInfo!['imageUrl'] as String?,
                trackerId: trackerId,
                trackerLiveData: trackerData,
              ));
            }
          },
          onError: (error) {
            controller.addError(
              ServerException(message: 'Failed to get tracker data: $error'),
            );
          },
        );
      },
      onError: (error) {
        controller.addError(
          ServerException(message: 'Failed to watch vehicle: $error'),
        );
      },
    );

    controller.onCancel = () {
      trackerSubscription?.cancel();
    };

    return controller.stream;
  }

  @override
  Future<List<TripPointModel>> getTripPoints({
    required String trackerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Query history data within date range
      // RTDB structure: trackers_history/{imei}/{timestamp}
      final startTs = startDate.millisecondsSinceEpoch;
      final endTs = endDate.millisecondsSinceEpoch;

      final snapshot = await _trackerHistoryRef(trackerId)
          .orderByChild('ts')
          .startAt(startTs)
          .endAt(endTs)
          .get();

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final points = <TripPointModel>[];

      for (final entry in data.entries) {
        if (entry.value is Map) {
          points.add(TripPointModel.fromRtdb(entry.value as Map));
        }
      }

      // Sort by timestamp
      points.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return points;
    } catch (e) {
      throw ServerException(message: 'Failed to get trip history: $e');
    }
  }
}
