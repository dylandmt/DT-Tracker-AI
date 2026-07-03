import '../../domain/entities/trip_point.dart';

/// Model for TripPointEntity with RTDB serialization
class TripPointModel extends TripPointEntity {
  const TripPointModel({
    required super.timestamp,
    required super.latitude,
    required super.longitude,
    required super.speed,
    required super.battery,
  });

  /// Create from RTDB history data
  factory TripPointModel.fromRtdb(Map<dynamic, dynamic> data) {
    return TripPointModel(
      timestamp: data['datetime'] != null
          ? DateTime.parse(data['datetime'] as String)
          : DateTime.fromMillisecondsSinceEpoch(
              (data['ts'] as num?)?.toInt() ?? 0,
            ),
      latitude: (data['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['lng'] as num?)?.toDouble() ?? 0.0,
      speed: (data['speed'] as num?)?.toDouble() ?? 0.0,
      battery: (data['battery'] as num?)?.toInt() ?? 0,
    );
  }

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'battery': battery,
    };
  }

  /// Create from JSON (for caching)
  factory TripPointModel.fromJson(Map<String, dynamic> json) {
    return TripPointModel(
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      battery: (json['battery'] as num).toInt(),
    );
  }
}

/// Model for TripEntity with serialization
class TripModel extends TripEntity {
  const TripModel({
    required super.vehicleId,
    required super.trackerId,
    required super.startTime,
    required super.endTime,
    required super.points,
  });

  /// Create from list of trip point models
  factory TripModel.fromPoints({
    required String vehicleId,
    required String trackerId,
    required List<TripPointModel> points,
  }) {
    if (points.isEmpty) {
      return TripModel(
        vehicleId: vehicleId,
        trackerId: trackerId,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        points: const [],
      );
    }

    // Sort by timestamp
    final sortedPoints = List<TripPointModel>.from(points)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return TripModel(
      vehicleId: vehicleId,
      trackerId: trackerId,
      startTime: sortedPoints.first.timestamp,
      endTime: sortedPoints.last.timestamp,
      points: sortedPoints,
    );
  }

  /// Create from entity
  factory TripModel.fromEntity(TripEntity entity) {
    return TripModel(
      vehicleId: entity.vehicleId,
      trackerId: entity.trackerId,
      startTime: entity.startTime,
      endTime: entity.endTime,
      points: entity.points,
    );
  }
}
