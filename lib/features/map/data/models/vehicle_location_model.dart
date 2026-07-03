import '../../domain/entities/vehicle_location.dart';

/// Model for VehicleLocationEntity with serialization
class VehicleLocationModel extends VehicleLocationEntity {
  const VehicleLocationModel({
    required super.vehicleId,
    required super.vehicleName,
    required super.plateNumber,
    super.color,
    super.imageUrl,
    required super.trackerId,
    required super.latitude,
    required super.longitude,
    required super.speed,
    required super.battery,
    required super.isOnline,
    required super.lastUpdate,
  });

  /// Create from vehicle data and tracker live data
  factory VehicleLocationModel.fromVehicleAndTracker({
    required String vehicleId,
    required String vehicleName,
    required String plateNumber,
    String? color,
    String? imageUrl,
    required String trackerId,
    required Map<dynamic, dynamic> trackerLiveData,
  }) {
    return VehicleLocationModel(
      vehicleId: vehicleId,
      vehicleName: vehicleName,
      plateNumber: plateNumber,
      color: color,
      imageUrl: imageUrl,
      trackerId: trackerId,
      latitude: (trackerLiveData['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (trackerLiveData['lng'] as num?)?.toDouble() ?? 0.0,
      speed: (trackerLiveData['speed'] as num?)?.toDouble() ?? 0.0,
      battery: (trackerLiveData['battery'] as num?)?.toInt() ?? 0,
      isOnline: trackerLiveData['online'] as bool? ?? false,
      lastUpdate: trackerLiveData['datetime'] != null
          ? DateTime.parse(trackerLiveData['datetime'] as String)
          : DateTime.now(),
    );
  }

  /// Update location data while preserving vehicle info
  VehicleLocationModel updateWithTrackerData(
    Map<dynamic, dynamic> trackerLiveData,
  ) {
    return VehicleLocationModel(
      vehicleId: vehicleId,
      vehicleName: vehicleName,
      plateNumber: plateNumber,
      color: color,
      imageUrl: imageUrl,
      trackerId: trackerId,
      latitude: (trackerLiveData['lat'] as num?)?.toDouble() ?? latitude,
      longitude: (trackerLiveData['lng'] as num?)?.toDouble() ?? longitude,
      speed: (trackerLiveData['speed'] as num?)?.toDouble() ?? speed,
      battery: (trackerLiveData['battery'] as num?)?.toInt() ?? battery,
      isOnline: trackerLiveData['online'] as bool? ?? isOnline,
      lastUpdate: trackerLiveData['datetime'] != null
          ? DateTime.parse(trackerLiveData['datetime'] as String)
          : lastUpdate,
    );
  }

  /// Create from entity
  factory VehicleLocationModel.fromEntity(VehicleLocationEntity entity) {
    return VehicleLocationModel(
      vehicleId: entity.vehicleId,
      vehicleName: entity.vehicleName,
      plateNumber: entity.plateNumber,
      color: entity.color,
      imageUrl: entity.imageUrl,
      trackerId: entity.trackerId,
      latitude: entity.latitude,
      longitude: entity.longitude,
      speed: entity.speed,
      battery: entity.battery,
      isOnline: entity.isOnline,
      lastUpdate: entity.lastUpdate,
    );
  }
}
