import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// Represents a single point in a vehicle's trip history
class TripPointEntity extends Equatable {
  /// Timestamp of this point
  final DateTime timestamp;

  /// Latitude
  final double latitude;

  /// Longitude
  final double longitude;

  /// Speed at this point in km/h
  final double speed;

  /// Battery level at this point
  final int battery;

  const TripPointEntity({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.battery,
  });

  /// Get formatted speed string
  String get formattedSpeed => '${speed.toStringAsFixed(1)} km/h';

  /// Get formatted time
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        timestamp,
        latitude,
        longitude,
        speed,
        battery,
      ];
}

/// Represents a trip session with multiple points
class TripEntity extends Equatable {
  /// Vehicle ID
  final String vehicleId;

  /// Tracker IMEI
  final String trackerId;

  /// Start time of the trip
  final DateTime startTime;

  /// End time of the trip
  final DateTime endTime;

  /// List of points in the trip
  final List<TripPointEntity> points;

  const TripEntity({
    required this.vehicleId,
    required this.trackerId,
    required this.startTime,
    required this.endTime,
    required this.points,
  });

  /// Get trip duration
  Duration get duration => endTime.difference(startTime);

  /// Get formatted duration
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Calculate total distance in km (approximate using Haversine)
  double get totalDistanceKm {
    if (points.length < 2) return 0;

    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      total += _calculateDistance(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return total;
  }

  /// Get formatted distance
  String get formattedDistance {
    final km = totalDistanceKm;
    if (km >= 1) {
      return '${km.toStringAsFixed(2)} km';
    }
    return '${(km * 1000).toStringAsFixed(0)} m';
  }

  /// Get average speed in km/h
  double get averageSpeed {
    if (points.isEmpty) return 0;
    final total = points.fold<double>(0, (sum, p) => sum + p.speed);
    return total / points.length;
  }

  /// Get max speed in km/h
  double get maxSpeed {
    if (points.isEmpty) return 0;
    return points.map((p) => p.speed).reduce((a, b) => a > b ? a : b);
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371.0; // Earth's radius in km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }

  double _toRadians(double degrees) => degrees * (3.141592653589793 / 180);

  @override
  List<Object?> get props => [
        vehicleId,
        trackerId,
        startTime,
        endTime,
        points,
      ];
}
