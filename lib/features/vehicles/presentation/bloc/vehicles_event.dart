part of 'vehicles_bloc.dart';

/// Events for the VehiclesBloc
sealed class VehiclesEvent extends Equatable {
  const VehiclesEvent();

  @override
  List<Object?> get props => [];
}

/// Load vehicles once
class LoadVehicles extends VehiclesEvent {
  const LoadVehicles();
}

/// Start watching vehicles for real-time updates
class StartWatchingVehicles extends VehiclesEvent {
  const StartWatchingVehicles();
}

/// Stop watching vehicles
class StopWatchingVehicles extends VehiclesEvent {
  const StopWatchingVehicles();
}

/// Internal event: vehicles updated from stream
class VehiclesUpdated extends VehiclesEvent {
  final List<VehicleEntity> vehicles;
  final String? error;

  const VehiclesUpdated({
    required this.vehicles,
    this.error,
  });

  @override
  List<Object?> get props => [vehicles, error];
}

/// Delete a vehicle
class DeleteVehicleRequested extends VehiclesEvent {
  final String vehicleId;

  const DeleteVehicleRequested({required this.vehicleId});

  @override
  List<Object?> get props => [vehicleId];
}

/// Refresh vehicles list
class RefreshVehicles extends VehiclesEvent {
  const RefreshVehicles();
}

/// Clear error state
class ClearVehiclesError extends VehiclesEvent {
  const ClearVehiclesError();
}
