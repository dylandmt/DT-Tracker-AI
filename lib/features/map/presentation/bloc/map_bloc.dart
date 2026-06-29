import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/trip_point.dart';
import '../../domain/entities/vehicle_location.dart';
import '../../domain/usecases/get_trip_history.dart';
import '../../domain/usecases/get_vehicle_locations.dart';

part 'map_event.dart';
part 'map_state.dart';

/// BLoC for managing map state with real-time vehicle locations
class MapBloc extends Bloc<MapEvent, MapState> {
  final GetVehicleLocations getVehicleLocations;
  final WatchVehicleLocations watchVehicleLocations;
  final GetTripHistory getTripHistory;
  final GetDayTripPoints getDayTripPoints;

  StreamSubscription? _locationsSubscription;

  MapBloc({
    required this.getVehicleLocations,
    required this.watchVehicleLocations,
    required this.getTripHistory,
    required this.getDayTripPoints,
  }) : super(const MapState()) {
    on<StartWatchingLocations>(_onStartWatchingLocations);
    on<StopWatchingLocations>(_onStopWatchingLocations);
    on<LocationsUpdated>(_onLocationsUpdated);
    on<LocationsError>(_onLocationsError);
    on<SelectVehicle>(_onSelectVehicle);
    on<ClearVehicleSelection>(_onClearVehicleSelection);
    on<LoadTripHistory>(_onLoadTripHistory);
    on<ClearTripHistory>(_onClearTripHistory);
    on<StartTripPlayback>(_onStartTripPlayback);
    on<PauseTripPlayback>(_onPauseTripPlayback);
    on<StopTripPlayback>(_onStopTripPlayback);
    on<UpdatePlaybackPosition>(_onUpdatePlaybackPosition);
    on<ClearMapError>(_onClearMapError);
    on<ToggleTrafficLayer>(_onToggleTrafficLayer);
    on<ChangeMapType>(_onChangeMapType);
  }

  Future<void> _onStartWatchingLocations(
    StartWatchingLocations event,
    Emitter<MapState> emit,
  ) async {
    emit(state.copyWith(status: MapStatus.loading));

    await _locationsSubscription?.cancel();

    _locationsSubscription = watchVehicleLocations(NoParams()).listen(
      (either) {
        either.fold(
          (failure) => add(LocationsError(failure.message)),
          (locations) => add(LocationsUpdated(locations)),
        );
      },
      onError: (error) {
        add(LocationsError(error.toString()));
      },
    );
  }

  Future<void> _onStopWatchingLocations(
    StopWatchingLocations event,
    Emitter<MapState> emit,
  ) async {
    await _locationsSubscription?.cancel();
    _locationsSubscription = null;
  }

  void _onLocationsUpdated(
    LocationsUpdated event,
    Emitter<MapState> emit,
  ) {
    // Update selected vehicle if it exists in the new locations
    VehicleLocationEntity? updatedSelectedVehicle;
    if (state.selectedVehicle != null) {
      updatedSelectedVehicle = event.locations.firstWhere(
        (v) => v.vehicleId == state.selectedVehicle!.vehicleId,
        orElse: () => state.selectedVehicle!,
      );
    }

    emit(state.copyWith(
      status: MapStatus.loaded,
      vehicleLocations: event.locations,
      selectedVehicle: updatedSelectedVehicle,
      errorMessage: null,
    ));
  }

  void _onLocationsError(
    LocationsError event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(
      status: MapStatus.error,
      errorMessage: event.message,
    ));
  }

  void _onSelectVehicle(
    SelectVehicle event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(
      selectedVehicle: event.vehicle,
      // Clear any trip data when selecting a new vehicle
      tripHistory: null,
      tripPoints: const [],
      playbackStatus: PlaybackStatus.idle,
      playbackPosition: 0,
    ));
  }

  void _onClearVehicleSelection(
    ClearVehicleSelection event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(
      clearSelectedVehicle: true,
      tripHistory: null,
      tripPoints: const [],
      playbackStatus: PlaybackStatus.idle,
      playbackPosition: 0,
    ));
  }

  Future<void> _onLoadTripHistory(
    LoadTripHistory event,
    Emitter<MapState> emit,
  ) async {
    if (state.selectedVehicle == null) return;

    emit(state.copyWith(tripStatus: TripStatus.loading));

    final result = await getTripHistory(TripHistoryParams(
      vehicleId: state.selectedVehicle!.vehicleId,
      startDate: event.startDate,
      endDate: event.endDate,
    ));

    result.fold(
      (failure) {
        emit(state.copyWith(
          tripStatus: TripStatus.error,
          errorMessage: failure.message,
        ));
      },
      (trip) {
        emit(state.copyWith(
          tripStatus: TripStatus.loaded,
          tripHistory: trip,
          tripPoints: trip.points,
          playbackPosition: 0,
        ));
      },
    );
  }

  void _onClearTripHistory(
    ClearTripHistory event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(
      tripHistory: null,
      tripPoints: const [],
      tripStatus: TripStatus.initial,
      playbackStatus: PlaybackStatus.idle,
      playbackPosition: 0,
    ));
  }

  void _onStartTripPlayback(
    StartTripPlayback event,
    Emitter<MapState> emit,
  ) {
    if (state.tripPoints.isEmpty) return;
    emit(state.copyWith(playbackStatus: PlaybackStatus.playing));
  }

  void _onPauseTripPlayback(
    PauseTripPlayback event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(playbackStatus: PlaybackStatus.paused));
  }

  void _onStopTripPlayback(
    StopTripPlayback event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(
      playbackStatus: PlaybackStatus.idle,
      playbackPosition: 0,
    ));
  }

  void _onUpdatePlaybackPosition(
    UpdatePlaybackPosition event,
    Emitter<MapState> emit,
  ) {
    final maxPosition = state.tripPoints.length - 1;
    final newPosition = event.position.clamp(0, maxPosition);

    // Auto-stop when reaching the end
    final playbackStatus = newPosition >= maxPosition
        ? PlaybackStatus.idle
        : state.playbackStatus;

    emit(state.copyWith(
      playbackPosition: newPosition,
      playbackStatus: playbackStatus,
    ));
  }

  void _onClearMapError(
    ClearMapError event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(
      status: state.vehicleLocations.isEmpty
          ? MapStatus.initial
          : MapStatus.loaded,
      errorMessage: null,
    ));
  }

  void _onToggleTrafficLayer(
    ToggleTrafficLayer event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(showTraffic: !state.showTraffic));
  }

  void _onChangeMapType(
    ChangeMapType event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(mapType: event.mapType));
  }

  @override
  Future<void> close() {
    _locationsSubscription?.cancel();
    return super.close();
  }
}
