part of 'statistics_bloc.dart';

enum StatisticsStatus { initial, loading, loaded, empty, error }

class StatisticsState extends Equatable {
  const StatisticsState({
    this.status = StatisticsStatus.initial,
    this.vehicles = const [],
    this.selectedVehicle,
    this.from,
    this.to,
    this.statistics,
    this.failure,
  });
  final StatisticsStatus status;
  final List<VehicleEntity> vehicles;
  final VehicleEntity? selectedVehicle;
  final DateTime? from;
  final DateTime? to;
  final VehicleStatistics? statistics;
  final Failure? failure;
  StatisticsState copyWith({
    StatisticsStatus? status,
    List<VehicleEntity>? vehicles,
    VehicleEntity? selectedVehicle,
    DateTime? from,
    DateTime? to,
    VehicleStatistics? statistics,
    Failure? failure,
    bool clearStatistics = false,
    bool clearFailure = false,
  }) => StatisticsState(
    status: status ?? this.status,
    vehicles: vehicles ?? this.vehicles,
    selectedVehicle: selectedVehicle ?? this.selectedVehicle,
    from: from ?? this.from,
    to: to ?? this.to,
    statistics: clearStatistics ? null : statistics ?? this.statistics,
    failure: clearFailure ? null : failure ?? this.failure,
  );
  @override
  List<Object?> get props => [
    status,
    vehicles,
    selectedVehicle,
    from,
    to,
    statistics,
    failure,
  ];
}
