import 'package:equatable/equatable.dart';

/// Represents a vehicle's location on the map with combined vehicle and tracker data
class VehicleLocationEntity extends Equatable {
  /// Vehicle ID from Firestore
  final String vehicleId;

  /// Vehicle name
  final String vehicleName;

  /// Vehicle plate number
  final String plateNumber;

  /// Vehicle color (for marker customization)
  final String? color;

  /// Primary image URL
  final String? imageUrl;

  /// GPS tracker IMEI
  final String trackerId;

  /// Current latitude
  final double latitude;

  /// Current longitude
  final double longitude;

  /// Current speed in km/h
  final double speed;

  /// Battery level (0-100)
  final int battery;

  /// Whether the tracker is online
  final bool isOnline;

  /// Last update timestamp
  final DateTime lastUpdate;

  const VehicleLocationEntity({
    required this.vehicleId,
    required this.vehicleName,
    required this.plateNumber,
    this.color,
    this.imageUrl,
    required this.trackerId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.battery,
    required this.isOnline,
    required this.lastUpdate,
  });

  /// Check if the vehicle is currently moving
  bool get isMoving => speed > 0 && isOnline;

  /// Check if the vehicle is idle (online but not moving)
  bool get isIdle => speed == 0 && isOnline;

  /// Get vehicle status
  VehicleStatus get status {
    if (!isOnline) return VehicleStatus.offline;
    if (speed > 0) return VehicleStatus.moving;
    return VehicleStatus.idle;
  }

  /// Get formatted speed string
  String get formattedSpeed => '${speed.toStringAsFixed(1)} km/h';

  /// Get formatted coordinates
  String get formattedCoordinates =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  /// Check if battery is low (below 20%)
  bool get isBatteryLow => battery < 20;

  /// Create a copy with updated location data
  VehicleLocationEntity copyWithLocation({
    double? latitude,
    double? longitude,
    double? speed,
    int? battery,
    bool? isOnline,
    DateTime? lastUpdate,
  }) {
    return VehicleLocationEntity(
      vehicleId: vehicleId,
      vehicleName: vehicleName,
      plateNumber: plateNumber,
      color: color,
      imageUrl: imageUrl,
      trackerId: trackerId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      battery: battery ?? this.battery,
      isOnline: isOnline ?? this.isOnline,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  @override
  List<Object?> get props => [
        vehicleId,
        vehicleName,
        plateNumber,
        color,
        imageUrl,
        trackerId,
        latitude,
        longitude,
        speed,
        battery,
        isOnline,
        lastUpdate,
      ];
}

/// Vehicle status enumeration
enum VehicleStatus {
  /// Vehicle is online and moving
  moving,

  /// Vehicle is online but not moving
  idle,

  /// Vehicle tracker is offline
  offline,
}
