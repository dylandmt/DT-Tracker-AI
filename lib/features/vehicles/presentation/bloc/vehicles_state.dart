part of 'vehicles_bloc.dart';

/// Status enum for vehicles state
enum VehiclesStatus {
  initial,
  loading,
  loaded,
  error,
  deleting,
  deleted,
}

/// State for the VehiclesBloc
class VehiclesState extends Equatable {
  final VehiclesStatus status;
  final List<VehicleEntity> vehicles;
  final String? errorMessage;

  const VehiclesState({
    required this.status,
    required this.vehicles,
    this.errorMessage,
  });

  /// Initial state
  factory VehiclesState.initial() {
    return const VehiclesState(
      status: VehiclesStatus.initial,
      vehicles: [],
    );
  }

  /// State helpers
  bool get isLoading => status == VehiclesStatus.loading;
  bool get isLoaded => status == VehiclesStatus.loaded;
  bool get hasError => status == VehiclesStatus.error;
  bool get isDeleting => status == VehiclesStatus.deleting;
  bool get isDeleted => status == VehiclesStatus.deleted;
  bool get isEmpty => vehicles.isEmpty;
  bool get hasVehicles => vehicles.isNotEmpty;

  /// Copy with modified fields
  VehiclesState copyWith({
    VehiclesStatus? status,
    List<VehicleEntity>? vehicles,
    String? errorMessage,
  }) {
    return VehiclesState(
      status: status ?? this.status,
      vehicles: vehicles ?? this.vehicles,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, vehicles, errorMessage];
}
