import 'package:equatable/equatable.dart';

class StatisticsSummary extends Equatable {
  const StatisticsSummary({
    required this.distanceKm,
    required this.averageDailyDistanceKm,
    required this.averageSpeedKmh,
    required this.maxSpeedKmh,
    required this.movingMinutes,
    this.pointCount = 0,
  });

  final double distanceKm;
  final double averageDailyDistanceKm;
  final double averageSpeedKmh;
  final double maxSpeedKmh;
  final double movingMinutes;
  final int pointCount;

  @override
  List<Object> get props => [
    distanceKm,
    averageDailyDistanceKm,
    averageSpeedKmh,
    maxSpeedKmh,
    movingMinutes,
    pointCount,
  ];
}

class DailyStatistics extends Equatable {
  const DailyStatistics({
    required this.date,
    required this.summary,
    this.speedSeries = const [],
  });

  final DateTime date;
  final StatisticsSummary summary;
  final List<SpeedSample> speedSeries;

  @override
  List<Object> get props => [date, summary, speedSeries];
}

class SpeedSample extends Equatable {
  const SpeedSample({required this.timestamp, required this.speedKmh});

  final DateTime timestamp;
  final double speedKmh;

  @override
  List<Object> get props => [timestamp, speedKmh];
}

class VehicleStatistics extends Equatable {
  const VehicleStatistics({
    required this.vehicleId,
    required this.from,
    required this.to,
    required this.summary,
    required this.days,
  });

  final String vehicleId;
  final DateTime from;
  final DateTime to;
  final StatisticsSummary summary;
  final List<DailyStatistics> days;

  @override
  List<Object> get props => [vehicleId, from, to, summary, days];
}
