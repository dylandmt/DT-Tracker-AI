import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/tracker_info.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/get_tracker_info.dart';
import '../../domain/usecases/link_tracker.dart';
import '../../domain/usecases/unlink_tracker.dart';

part 'tracker_link_event.dart';
part 'tracker_link_state.dart';

/// BLoC for managing tracker linking/unlinking
class TrackerLinkBloc extends Bloc<TrackerLinkEvent, TrackerLinkState> {
  final GetTrackerInfo getTrackerInfo;
  final IsTrackerAvailable isTrackerAvailable;
  final LinkTracker linkTracker;
  final UnlinkTracker unlinkTracker;

  TrackerLinkBloc({
    required this.getTrackerInfo,
    required this.isTrackerAvailable,
    required this.linkTracker,
    required this.unlinkTracker,
  }) : super(TrackerLinkState.initial()) {
    on<ValidateImei>(_onValidateImei);
    on<LinkTrackerToVehicle>(_onLinkTrackerToVehicle);
    on<UnlinkTrackerFromVehicle>(_onUnlinkTrackerFromVehicle);
    on<ResetTrackerLink>(_onResetTrackerLink);
    on<ClearTrackerError>(_onClearTrackerError);
  }

  Future<void> _onValidateImei(
    ValidateImei event,
    Emitter<TrackerLinkState> emit,
  ) async {
    emit(state.copyWith(
      status: TrackerLinkStatus.validating,
      imei: event.imei,
    ));

    // First check if tracker is available
    final availableResult = await isTrackerAvailable(ImeiParams(imei: event.imei));

    final isAvailable = availableResult.fold(
      (failure) {
        emit(state.copyWith(
          status: TrackerLinkStatus.invalid,
          errorMessage: failure.message,
        ));
        return false;
      },
      (available) => available,
    );

    if (!isAvailable) {
      emit(state.copyWith(
        status: TrackerLinkStatus.invalid,
        errorMessage: 'Tracker not found or already in use',
      ));
      return;
    }

    // Get tracker info
    final infoResult = await getTrackerInfo(ImeiParams(imei: event.imei));

    infoResult.fold(
      (failure) => emit(state.copyWith(
        status: TrackerLinkStatus.invalid,
        errorMessage: failure.message,
      )),
      (tracker) => emit(state.copyWith(
        status: TrackerLinkStatus.valid,
        trackerInfo: tracker,
      )),
    );
  }

  Future<void> _onLinkTrackerToVehicle(
    LinkTrackerToVehicle event,
    Emitter<TrackerLinkState> emit,
  ) async {
    emit(state.copyWith(status: TrackerLinkStatus.linking));

    final result = await linkTracker(LinkTrackerParams(
      vehicleId: event.vehicleId,
      trackerId: event.imei,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        status: TrackerLinkStatus.error,
        errorMessage: failure.message,
      )),
      (vehicle) => emit(state.copyWith(
        status: TrackerLinkStatus.linked,
        vehicle: vehicle,
      )),
    );
  }

  Future<void> _onUnlinkTrackerFromVehicle(
    UnlinkTrackerFromVehicle event,
    Emitter<TrackerLinkState> emit,
  ) async {
    emit(state.copyWith(status: TrackerLinkStatus.unlinking));

    final result = await unlinkTracker(IdParams(id: event.vehicleId));

    result.fold(
      (failure) => emit(state.copyWith(
        status: TrackerLinkStatus.error,
        errorMessage: failure.message,
      )),
      (vehicle) => emit(state.copyWith(
        status: TrackerLinkStatus.unlinked,
        vehicle: vehicle,
      )),
    );
  }

  void _onResetTrackerLink(
    ResetTrackerLink event,
    Emitter<TrackerLinkState> emit,
  ) {
    emit(TrackerLinkState.initial());
  }

  void _onClearTrackerError(
    ClearTrackerError event,
    Emitter<TrackerLinkState> emit,
  ) {
    emit(state.copyWith(
      status: TrackerLinkStatus.initial,
      errorMessage: null,
    ));
  }
}
