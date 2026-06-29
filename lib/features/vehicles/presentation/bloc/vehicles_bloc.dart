import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/delete_vehicle.dart';
import '../../domain/usecases/get_vehicles.dart';
import '../../domain/usecases/watch_vehicles.dart';

part 'vehicles_event.dart';
part 'vehicles_state.dart';

/// BLoC for managing the vehicles list
class VehiclesBloc extends Bloc<VehiclesEvent, VehiclesState> {
  final GetVehicles getVehicles;
  final WatchVehicles watchVehicles;
  final DeleteVehicle deleteVehicle;

  StreamSubscription? _vehiclesSubscription;

  VehiclesBloc({
    required this.getVehicles,
    required this.watchVehicles,
    required this.deleteVehicle,
  }) : super(VehiclesState.initial()) {
    on<LoadVehicles>(_onLoadVehicles);
    on<StartWatchingVehicles>(_onStartWatchingVehicles);
    on<StopWatchingVehicles>(_onStopWatchingVehicles);
    on<VehiclesUpdated>(_onVehiclesUpdated);
    on<DeleteVehicleRequested>(_onDeleteVehicleRequested);
    on<RefreshVehicles>(_onRefreshVehicles);
    on<ClearVehiclesError>(_onClearVehiclesError);
  }

  Future<void> _onLoadVehicles(
    LoadVehicles event,
    Emitter<VehiclesState> emit,
  ) async {
    emit(state.copyWith(status: VehiclesStatus.loading));

    final result = await getVehicles(const NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: VehiclesStatus.error,
        errorMessage: failure.message,
      )),
      (vehicles) => emit(state.copyWith(
        status: VehiclesStatus.loaded,
        vehicles: vehicles,
      )),
    );
  }

  void _onStartWatchingVehicles(
    StartWatchingVehicles event,
    Emitter<VehiclesState> emit,
  ) {
    _vehiclesSubscription?.cancel();

    emit(state.copyWith(status: VehiclesStatus.loading));

    _vehiclesSubscription = watchVehicles(const NoParams()).listen(
      (result) {
        result.fold(
          (failure) => add(VehiclesUpdated(
            vehicles: state.vehicles,
            error: failure.message,
          )),
          (vehicles) => add(VehiclesUpdated(vehicles: vehicles)),
        );
      },
      onError: (error) {
        add(VehiclesUpdated(
          vehicles: state.vehicles,
          error: error.toString(),
        ));
      },
    );
  }

  void _onStopWatchingVehicles(
    StopWatchingVehicles event,
    Emitter<VehiclesState> emit,
  ) {
    _vehiclesSubscription?.cancel();
    _vehiclesSubscription = null;
  }

  void _onVehiclesUpdated(
    VehiclesUpdated event,
    Emitter<VehiclesState> emit,
  ) {
    if (event.error != null) {
      emit(state.copyWith(
        status: VehiclesStatus.error,
        errorMessage: event.error,
      ));
    } else {
      emit(state.copyWith(
        status: VehiclesStatus.loaded,
        vehicles: event.vehicles,
      ));
    }
  }

  Future<void> _onDeleteVehicleRequested(
    DeleteVehicleRequested event,
    Emitter<VehiclesState> emit,
  ) async {
    emit(state.copyWith(status: VehiclesStatus.deleting));

    final result = await deleteVehicle(IdParams(id: event.vehicleId));

    result.fold(
      (failure) => emit(state.copyWith(
        status: VehiclesStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        // Remove vehicle from local list
        final updatedVehicles = state.vehicles
            .where((v) => v.id != event.vehicleId)
            .toList();
        emit(state.copyWith(
          status: VehiclesStatus.deleted,
          vehicles: updatedVehicles,
        ));
      },
    );
  }

  Future<void> _onRefreshVehicles(
    RefreshVehicles event,
    Emitter<VehiclesState> emit,
  ) async {
    final result = await getVehicles(const NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: VehiclesStatus.error,
        errorMessage: failure.message,
      )),
      (vehicles) => emit(state.copyWith(
        status: VehiclesStatus.loaded,
        vehicles: vehicles,
      )),
    );
  }

  void _onClearVehiclesError(
    ClearVehiclesError event,
    Emitter<VehiclesState> emit,
  ) {
    emit(state.copyWith(
      status: VehiclesStatus.loaded,
      errorMessage: null,
    ));
  }

  @override
  Future<void> close() {
    _vehiclesSubscription?.cancel();
    return super.close();
  }
}
