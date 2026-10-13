import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../domain/entities/statistics.dart';
import '../../domain/usecases/statistics_usecases.dart';

part 'statistics_event.dart';
part 'statistics_state.dart';

class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  StatisticsBloc({required this.getStatistics})
    : super(const StatisticsState()) {
    on<StatisticsRequested>(_onRequested);
    on<StatisticsVehicleChanged>(_onVehicleChanged);
    on<StatisticsRangeChanged>(_onRangeChanged);
  }
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
    final vehicle = event.vehicle;
    if (vehicle == null) {
      emit(
        state.copyWith(status: StatisticsStatus.empty, clearStatistics: true),
      );
      return;
    }
    emit(state.copyWith(selectedVehicle: vehicle));
    await _load(vehicle, event.from, event.to, emit);
  }

  Future<void> _onVehicleChanged(
    StatisticsVehicleChanged event,
    Emitter<StatisticsState> emit,
  ) async {
    final vehicle = state.vehicles
        .where((item) => item.id == event.vehicleId)
        .firstOrNull;
    if (vehicle == null) return;
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
    final request = ++_request;
    if (!vehicle.hasTracker) {
      emit(
        state.copyWith(status: StatisticsStatus.empty, clearStatistics: true),
      );
      return;
    }
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
