import 'package:equatable/equatable.dart';

/// Tracker info entity representing GPS tracker device metadata
class TrackerInfoEntity extends Equatable {
  /// Device IMEI number (unique identifier)
  final String imei;

  /// Device model (e.g., SIM7670)
  final String? model;

  /// Cellular provider (e.g., Telcel)
  final String? provider;

  /// User ID who owns this tracker (null if not owned)
  final String? ownerId;

  /// When the tracker was linked to a user
  final DateTime? linkedAt;

  const TrackerInfoEntity({
    required this.imei,
    this.model,
    this.provider,
    this.ownerId,
    this.linkedAt,
  });

  /// Whether the tracker is available for linking (not owned by anyone)
  bool get isAvailable => ownerId == null;

  /// Check if the tracker is owned by a specific user
  bool isOwnedBy(String userId) => ownerId == userId;

  /// Get display name for the tracker
  String get displayName {
    if (model != null) {
      return '$model ($imei)';
    }
    return imei;
  }

  /// Create a copy with modified fields
  TrackerInfoEntity copyWith({
    String? imei,
    String? model,
    String? provider,
    String? ownerId,
    DateTime? linkedAt,
  }) {
    return TrackerInfoEntity(
      imei: imei ?? this.imei,
      model: model ?? this.model,
      provider: provider ?? this.provider,
      ownerId: ownerId ?? this.ownerId,
      linkedAt: linkedAt ?? this.linkedAt,
    );
  }

  @override
  List<Object?> get props => [
        imei,
        model,
        provider,
        ownerId,
        linkedAt,
      ];
}

/// Tracker live data entity representing real-time tracker status
class TrackerLiveEntity extends Equatable {
  /// Device IMEI number
  final String imei;

  /// Battery level (0-100)
  final int battery;

  /// Current latitude
  final double lat;

  /// Current longitude
  final double lng;

  /// Current speed in km/h
  final double speed;

  /// Whether the tracker is online
  final bool online;

  /// Last update datetime
  final DateTime datetime;

  /// Timestamp (milliseconds)
  final int ts;

  const TrackerLiveEntity({
    required this.imei,
    required this.battery,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.online,
    required this.datetime,
    required this.ts,
  });

  /// Get battery status description
  String get batteryStatus {
    if (battery >= 80) return 'Good';
    if (battery >= 50) return 'Medium';
    if (battery >= 20) return 'Low';
    return 'Critical';
  }

  /// Whether the battery is low (below 20%)
  bool get isBatteryLow => battery < 20;

  /// Get speed formatted
  String get formattedSpeed => '${speed.toStringAsFixed(1)} km/h';

  /// Get coordinates as a formatted string
  String get formattedCoordinates =>
      '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';

  @override
  List<Object?> get props => [
        imei,
        battery,
        lat,
        lng,
        speed,
        online,
        datetime,
        ts,
      ];
}

/// Tracker status entity for quick status checks
class TrackerStatusEntity extends Equatable {
  /// Device IMEI number
  final String imei;

  /// Battery level (0-100)
  final int battery;

  /// Whether the tracker is online
  final bool online;

  /// Current speed in km/h
  final double speed;

  /// Last update datetime
  final DateTime lastUpdate;

  const TrackerStatusEntity({
    required this.imei,
    required this.battery,
    required this.online,
    required this.speed,
    required this.lastUpdate,
  });

  /// Get status description
  String get statusDescription {
    if (!online) return 'Offline';
    if (speed > 0) return 'Moving';
    return 'Idle';
  }

  @override
  List<Object?> get props => [
        imei,
        battery,
        online,
        speed,
        lastUpdate,
      ];
}
