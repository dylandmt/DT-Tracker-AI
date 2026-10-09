import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/domain/usecases/get_vehicles.dart';
import '../../domain/entities/statistics.dart';
import '../../domain/usecases/statistics_usecases.dart';

part 'statistics_event.dart';
part 'statistics_state.dart';

class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  StatisticsBloc({required this.getVehicles, required this.getStatistics})
    : super(const StatisticsState()) {
    on<StatisticsRequested>(_onRequested);
    on<StatisticsVehicleChanged>(_onVehicleChanged);
    on<StatisticsRangeChanged>(_onRangeChanged);
  }
  final GetVehicles getVehicles;
  final GetVehicleStatistics getStatistics;
  int _request = 0;

  Future<void> _onRequested(
    StatisticsRequested event,
    Emitter<StatisticsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: StatisticsStatus.loading,
        from: event.from,
        to: event.to,
        clearFailure: true,
      ),
    );
    final vehiclesResult = await getVehicles(const NoParams());
    await vehiclesResult.fold(
      (failure) async => emit(
        state.copyWith(status: StatisticsStatus.error, failure: failure),
      ),
      (vehicles) async {
        if (vehicles.isEmpty) {
          emit(
            state.copyWith(status: StatisticsStatus.empty, vehicles: vehicles),
          );
          return;
        }
        final vehicle = vehicles.first;
        emit(state.copyWith(vehicles: vehicles, selectedVehicle: vehicle));
        await _load(vehicle, event.from, event.to, emit);
      },
    );
  }

  Future<void> _onVehicleChanged(
    StatisticsVehicleChanged event,
    Emitter<StatisticsState> emit,
  ) async {
    final vehicle = state.vehicles.firstWhere(
      (item) => item.id == event.vehicleId,
    );
    final from = state.from;
    final to = state.to;
    if (from == null || to == null) return;
    emit(
      state.copyWith(
        selectedVehicle: vehicle,
        status: StatisticsStatus.loading,
        clearStatistics: true,
        clearFailure: true,
      ),
    );
    await _load(vehicle, from, to, emit);
  }

  Future<void> _onRangeChanged(
    StatisticsRangeChanged event,
    Emitter<StatisticsState> emit,
  ) async {
    final vehicle = state.selectedVehicle;
    if (vehicle == null) return;
    emit(
      state.copyWith(
        from: event.from,
        to: event.to,
        status: StatisticsStatus.loading,
        clearStatistics: true,
        clearFailure: true,
      ),
    );
    await _load(vehicle, event.from, event.to, emit);
  }

  Future<void> _load(
    VehicleEntity vehicle,
    DateTime from,
    DateTime to,
    Emitter<StatisticsState> emit,
  ) async {
    if (!vehicle.hasTracker) {
      emit(state.copyWith(status: StatisticsStatus.empty));
      return;
    }
    final request = ++_request;
    final result = await getStatistics(
      StatisticsParams(vehicleId: vehicle.id, from: from, to: to),
    );
    if (request != _request) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: StatisticsStatus.error, failure: failure),
      ),
      (statistics) => emit(
        state.copyWith(status: StatisticsStatus.loaded, statistics: statistics),
      ),
    );
  }
}
