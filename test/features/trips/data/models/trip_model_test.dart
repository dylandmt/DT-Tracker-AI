import 'package:dt_tracker_ai/features/trips/data/models/trip_model.dart';
import 'package:dt_tracker_ai/features/trips/domain/entities/trip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const activeTripJson = {
    'tripId': 'trip-1',
    'uid': 'user-1',
    'vehicleId': 'vehicle-1',
    'trackerId': '864643060618008',
    'status': 'active',
    'startedAt': '2026-08-26T10:00:00.000Z',
    'endedAt': null,
    'startLocation': null,
    'endLocation': null,
    'startOdometerKm': null,
    'endOdometerKm': null,
    'distanceKm': 0,
    'durationSeconds': 0,
    'pointCount': 0,
    'maxSpeedKmh': 0,
    'averageSpeedKmh': 0,
    'createdAt': '2026-08-26T10:00:00.000Z',
    'updatedAt': '2026-08-26T10:00:00.000Z',
  };

  test('parses an active trip with nullable summary fields', () {
    final trip = TripModel.fromJson(activeTripJson);

    expect(trip.status, TripStatus.active);
    expect(trip.endedAt, isNull);
    expect(trip.startLocation, isNull);
    expect(trip.distanceKm, 0);
  });

  test('coerces numeric metrics and parses locations', () {
    final trip = TripModel.fromJson({
      ...activeTripJson,
      'status': 'completed',
      'endedAt': '2026-08-26T10:30:00.000Z',
      'startLocation': {'lat': 20, 'lng': -96.8},
      'endLocation': {'lat': 20.1, 'lng': -96.9},
      'distanceKm': 12,
      'maxSpeedKmh': 90,
      'averageSpeedKmh': 45,
    });

    expect(trip.status, TripStatus.completed);
    expect(trip.distanceKm, 12.0);
    expect(
      trip.startLocation,
      const TripLocation(latitude: 20, longitude: -96.8),
    );
    expect(
      trip.endLocation,
      const TripLocation(latitude: 20.1, longitude: -96.9),
    );
  });
}
