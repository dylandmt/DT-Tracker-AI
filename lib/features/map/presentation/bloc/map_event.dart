part of 'map_bloc.dart';

/// Base class for map events
sealed class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

/// Start watching all vehicle locations
class StartWatchingLocations extends MapEvent {
  const StartWatchingLocations();
}

/// Stop watching vehicle locations
class StopWatchingLocations extends MapEvent {
  const StopWatchingLocations();
}

/// Internal event when locations are updated
class LocationsUpdated extends MapEvent {
  final List<VehicleLocationEntity> locations;

  const LocationsUpdated(this.locations);

  @override
  List<Object?> get props => [locations];
}

/// Internal event when there's a locations error
class LocationsError extends MapEvent {
  final String message;

  const LocationsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Select a vehicle to focus on
class SelectVehicle extends MapEvent {
  final VehicleLocationEntity vehicle;

  const SelectVehicle(this.vehicle);

  @override
  List<Object?> get props => [vehicle];
}

/// Clear vehicle selection
class ClearVehicleSelection extends MapEvent {
  const ClearVehicleSelection();
}

/// Load trip history for the selected vehicle
class LoadTripHistory extends MapEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadTripHistory({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Clear trip history data
class ClearTripHistory extends MapEvent {
  const ClearTripHistory();
}

/// Start trip playback
class StartTripPlayback extends MapEvent {
  const StartTripPlayback();
}

/// Pause trip playback
class PauseTripPlayback extends MapEvent {
  const PauseTripPlayback();
}

/// Stop trip playback and reset position
class StopTripPlayback extends MapEvent {
  const StopTripPlayback();
}

/// Update playback position
class UpdatePlaybackPosition extends MapEvent {
  final int position;

  const UpdatePlaybackPosition(this.position);

  @override
  List<Object?> get props => [position];
}

/// Clear map error
class ClearMapError extends MapEvent {
  const ClearMapError();
}

/// Toggle traffic layer
class ToggleTrafficLayer extends MapEvent {
  const ToggleTrafficLayer();
}

/// Change map type
class ChangeMapType extends MapEvent {
  final MapViewType mapType;

  const ChangeMapType(this.mapType);

  @override
  List<Object?> get props => [mapType];
}
