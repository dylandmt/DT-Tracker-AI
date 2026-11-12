import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/watch_vehicles.dart';

enum SelectedVehicleStatus { initial, loading, ready, error }

class SelectedVehicleState extends Equatable {
  const SelectedVehicleState({
    this.status = SelectedVehicleStatus.initial,
    this.vehicles = const [],
    this.selectedVehicle,
    this.userId,
    this.errorMessage,
  });

  final SelectedVehicleStatus status;
  final List<VehicleEntity> vehicles;
  final VehicleEntity? selectedVehicle;
  final String? userId;
  final String? errorMessage;

  SelectedVehicleState copyWith({
    SelectedVehicleStatus? status,
    List<VehicleEntity>? vehicles,
    VehicleEntity? selectedVehicle,
    String? userId,
    String? errorMessage,
    bool clearSelectedVehicle = false,
    bool clearUserId = false,
    bool clearError = false,
  }) => SelectedVehicleState(
    status: status ?? this.status,
    vehicles: vehicles ?? this.vehicles,
    selectedVehicle: clearSelectedVehicle
        ? null
        : selectedVehicle ?? this.selectedVehicle,
    userId: clearUserId ? null : userId ?? this.userId,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [
    status,
    vehicles,
    selectedVehicle,
    userId,
    errorMessage,
  ];
}

/// Session-scoped source of truth for the user's active vehicle.
class SelectedVehicleCubit extends Cubit<SelectedVehicleState> {
  SelectedVehicleCubit({
    required FirebaseAuth firebaseAuth,
    required WatchVehicles watchVehicles,
    required SharedPreferences preferences,
  }) : _firebaseAuth = firebaseAuth,
       _watchVehicles = watchVehicles,
       _preferences = preferences,
       super(const SelectedVehicleState()) {
    _authSubscription = _firebaseAuth.authStateChanges().listen(
      (user) => _startSession(user?.uid),
    );
    _startSession(_firebaseAuth.currentUser?.uid);
  }

  static const _preferencePrefix = 'selected_vehicle_id_';

  final FirebaseAuth _firebaseAuth;
  final WatchVehicles _watchVehicles;
  final SharedPreferences _preferences;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<Either<Failure, List<VehicleEntity>>>?
  _vehiclesSubscription;
  int _sessionGeneration = 0;
  bool _restorationComplete = false;
  String? _pendingPreferredId;
  Future<void> _persistenceQueue = Future.value();

  void selectVehicle(String vehicleId) {
    final vehicle = state.vehicles
        .where((item) => item.id == vehicleId)
        .firstOrNull;
    if (vehicle == null || vehicle.id == state.selectedVehicle?.id) return;
    _pendingPreferredId = vehicle.id;
    emit(state.copyWith(selectedVehicle: vehicle));
    _persist(vehicle.id, _sessionGeneration, state.userId);
  }

  void _startSession(String? userId) {
    if (userId == state.userId &&
        state.status != SelectedVehicleStatus.initial) {
      return;
    }
    final generation = ++_sessionGeneration;
    _vehiclesSubscription?.cancel();
    _restorationComplete = false;
    _pendingPreferredId = null;

    if (userId == null) {
      emit(const SelectedVehicleState());
      return;
    }

    emit(
      SelectedVehicleState(
        status: SelectedVehicleStatus.loading,
        userId: userId,
      ),
    );
    _vehiclesSubscription = _watchVehicles(const NoParams()).listen((result) {
      if (generation != _sessionGeneration) return;
      result.fold(
        (failure) => emit(
          state.copyWith(
            status: SelectedVehicleStatus.error,
            errorMessage: failure.message,
          ),
        ),
        (vehicles) => _updateVehicles(vehicles, generation),
      );
    });
    _restore(userId, generation);
  }

  Future<void> _restore(String userId, int generation) async {
    final vehicleId = _preferences.getString('$_preferencePrefix$userId');
    if (generation != _sessionGeneration) return;
    _pendingPreferredId = vehicleId;
    _restorationComplete = true;
    _resolveSelection(state.vehicles, vehicleId, generation);
  }

  void _updateVehicles(List<VehicleEntity> vehicles, int generation) {
    if (!_restorationComplete) {
      emit(
        state.copyWith(
          vehicles: vehicles,
          status: SelectedVehicleStatus.loading,
        ),
      );
      return;
    }
    _resolveSelection(
      vehicles,
      state.selectedVehicle?.id ?? _pendingPreferredId,
      generation,
    );
  }

  void _resolveSelection(
    List<VehicleEntity> vehicles,
    String? preferredId,
    int generation,
  ) {
    final selected = preferredId == null
        ? null
        : vehicles.where((vehicle) => vehicle.id == preferredId).firstOrNull;
    if (vehicles.isEmpty) {
      emit(
        SelectedVehicleState(
          status: SelectedVehicleStatus.ready,
          vehicles: vehicles,
          userId: state.userId,
        ),
      );
      return;
    }
    final fallback = selected ?? vehicles.first;
    emit(
      SelectedVehicleState(
        status: SelectedVehicleStatus.ready,
        vehicles: vehicles,
        selectedVehicle: fallback,
        userId: state.userId,
      ),
    );
    if (fallback.id != preferredId) {
      _persist(fallback.id, generation, state.userId);
    }
    _pendingPreferredId = fallback.id;
  }

  void _persist(String? vehicleId, int generation, String? userId) {
    if (userId == null || generation != _sessionGeneration) return;
    final key = '$_preferencePrefix$userId';
    _persistenceQueue = _persistenceQueue.then((_) async {
      if (generation != _sessionGeneration || state.userId != userId) return;
      if (vehicleId == null) {
        await _preferences.remove(key);
      } else {
        await _preferences.setString(key, vehicleId);
      }
    });
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    await _vehiclesSubscription?.cancel();
    return super.close();
  }
}
