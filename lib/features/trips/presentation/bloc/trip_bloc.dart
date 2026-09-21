import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/domain/usecases/get_vehicles.dart';
import '../../domain/entities/trip.dart';
import '../../domain/usecases/trip_usecases.dart';

part 'trip_event.dart';
part 'trip_state.dart';

class TripBloc extends Bloc<TripEvent, TripState> {
  final GetActiveTrip getActiveTrip;
  final GetTrips getTrips;
  final GetTrip getTrip;
  final StartTrip startTrip;
  final EndTrip endTrip;
  final GetVehicles getVehicles;

  TripBloc({
    required this.getActiveTrip,
    required this.getTrips,
    required this.getTrip,
    required this.startTrip,
    required this.endTrip,
    required this.getVehicles,
  }) : super(const TripState()) {
    on<TripsRequested>(_onTripsRequested);
    on<TripStarted>(_onTripStarted);
    on<TripEnded>(_onTripEnded);
    on<TripDetailRequested>(_onTripDetailRequested);
  }

  Future<void> _onTripsRequested(
    TripsRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearFailure: true));
    final activeFuture = getActiveTrip(const NoParams());
    final historyFuture = getTrips(const NoParams());
    final vehiclesFuture = getVehicles(const NoParams());
    final active = await activeFuture;
    final history = await historyFuture;
    final vehicles = await vehiclesFuture;
    Failure? failure;
    active.fold((value) => failure ??= value, (_) {});
    history.fold((value) => failure ??= value, (_) {});
    vehicles.fold((value) => failure ??= value, (_) {});
    emit(
      state.copyWith(
        isLoading: false,
        activeTrip: active.fold((_) => state.activeTrip, (value) => value),
        trips: history.fold((_) => state.trips, (value) => value),
        vehicles: vehicles.fold((_) => state.vehicles, (value) => value),
        failure: failure,
      ),
    );
  }

  Future<void> _onTripStarted(
    TripStarted event,
    Emitter<TripState> emit,
  ) async {
    emit(state.copyWith(isStarting: true, clearFailure: true));
    final result = await startTrip(
      StartTripParams(
        vehicleId: event.vehicle.id,
        trackerId: event.vehicle.trackerId!,
      ),
    );
    result.fold(
      (failure) => emit(state.copyWith(isStarting: false, failure: failure)),
      (trip) => emit(
        state.copyWith(
          isStarting: false,
          activeTrip: trip,
          trips: [
            trip,
            ...state.trips.where((item) => item.tripId != trip.tripId),
          ],
        ),
      ),
    );
  }

  Future<void> _onTripEnded(TripEnded event, Emitter<TripState> emit) async {
    emit(state.copyWith(isEnding: true, clearFailure: true));
    final result = await endTrip(IdParams(id: event.tripId));
    result.fold(
      (failure) => emit(state.copyWith(isEnding: false, failure: failure)),
      (trip) => emit(
        state.copyWith(
          isEnding: false,
          clearActiveTrip: true,
          selectedTrip: trip,
          trips: [
            trip,
            ...state.trips.where((item) => item.tripId != trip.tripId),
          ],
        ),
      ),
    );
  }

  Future<void> _onTripDetailRequested(
    TripDetailRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(state.copyWith(isLoadingDetail: true, clearFailure: true));
    final result = await getTrip(IdParams(id: event.tripId));
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoadingDetail: false, failure: failure)),
      (trip) =>
          emit(state.copyWith(isLoadingDetail: false, selectedTrip: trip)),
    );
  }
}
