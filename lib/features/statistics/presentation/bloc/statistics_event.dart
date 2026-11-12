part of 'statistics_bloc.dart';

abstract class StatisticsEvent extends Equatable {
  const StatisticsEvent();
  @override
  List<Object?> get props => [];
}

class StatisticsRequested extends StatisticsEvent {
  const StatisticsRequested({
    required this.vehicle,
    required this.from,
    required this.to,
  });
  final VehicleEntity? vehicle;
  final DateTime from;
  final DateTime to;
  @override
  List<Object?> get props => [vehicle, from, to];
}

class StatisticsVehicleChanged extends StatisticsEvent {
  const StatisticsVehicleChanged(this.vehicleId);
  final String vehicleId;
  @override
  List<Object> get props => [vehicleId];
}

class StatisticsRangeChanged extends StatisticsEvent {
  const StatisticsRangeChanged({required this.from, required this.to});
  final DateTime from;
  final DateTime to;
  @override
  List<Object> get props => [from, to];
}
