import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/geofence.dart';
import '../../domain/usecases/geofence_usecases.dart';

part 'geofence_event.dart';
part 'geofence_state.dart';

class GeofenceBloc extends Bloc<GeofenceEvent, GeofenceState> {
  final GetGeofences getGeofences;
  final GetGeofenceById getGeofenceById;
  final WatchGeofences watchGeofences;
  final CreateGeofence createGeofence;
  final UpdateGeofence updateGeofence;
  final DeleteGeofence deleteGeofence;
  StreamSubscription? _subscription;

  GeofenceBloc({
    required this.getGeofences,
    required this.getGeofenceById,
    required this.watchGeofences,
    required this.createGeofence,
    required this.updateGeofence,
    required this.deleteGeofence,
  }) : super(GeofenceState.initial()) {
    on<LoadGeofences>(_load);
    on<WatchGeofencesRequested>(_watch);
    on<GeofencesUpdated>(_updated);
    on<LoadGeofenceForEdit>(_loadForEdit);
    on<SubmitGeofence>(_submit);
    on<DeleteGeofenceRequested>(_delete);
    on<ClearGeofenceError>(_clearError);
  }

  Future<void> _load(LoadGeofences event, Emitter<GeofenceState> emit) async {
    emit(state.copyWith(status: GeofenceStatus.loading));
    final result = await getGeofences(const NoParams());
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GeofenceStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (geofences) => emit(
        state.copyWith(status: GeofenceStatus.loaded, geofences: geofences),
      ),
    );
  }

  void _watch(WatchGeofencesRequested event, Emitter<GeofenceState> emit) {
    _subscription?.cancel();
    emit(state.copyWith(status: GeofenceStatus.loading));
    _subscription = watchGeofences(const NoParams()).listen(
      (result) {
        result.fold(
          (failure) => add(GeofencesUpdated(error: failure.message)),
          (geofences) => add(GeofencesUpdated(geofences: geofences)),
        );
      },
      onError: (Object error) => add(GeofencesUpdated(error: error.toString())),
    );
  }

  void _updated(GeofencesUpdated event, Emitter<GeofenceState> emit) => emit(
    event.error == null
        ? state.copyWith(
            status: GeofenceStatus.loaded,
            geofences: event.geofences!,
          )
        : state.copyWith(
            status: GeofenceStatus.error,
            errorMessage: event.error,
          ),
  );

  Future<void> _loadForEdit(
    LoadGeofenceForEdit event,
    Emitter<GeofenceState> emit,
  ) async {
    emit(state.copyWith(status: GeofenceStatus.loading));
    final result = await getGeofenceById(IdParams(id: event.id));
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GeofenceStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (geofence) => emit(
        state.copyWith(
          status: GeofenceStatus.editing,
          editingGeofence: geofence,
        ),
      ),
    );
  }

  Future<void> _submit(
    SubmitGeofence event,
    Emitter<GeofenceState> emit,
  ) async {
    emit(state.copyWith(status: GeofenceStatus.submitting));
    final result = event.id == null
        ? await createGeofence(event.params)
        : await updateGeofence(event.params);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GeofenceStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(status: GeofenceStatus.success)),
    );
  }

  Future<void> _delete(
    DeleteGeofenceRequested event,
    Emitter<GeofenceState> emit,
  ) async {
    emit(state.copyWith(status: GeofenceStatus.deleting));
    final result = await deleteGeofence(IdParams(id: event.id));
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GeofenceStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: GeofenceStatus.deleted,
          geofences: state.geofences
              .where((geofence) => geofence.id != event.id)
              .toList(),
        ),
      ),
    );
  }

  void _clearError(ClearGeofenceError event, Emitter<GeofenceState> emit) =>
      emit(state.copyWith(status: GeofenceStatus.loaded, errorMessage: null));

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
