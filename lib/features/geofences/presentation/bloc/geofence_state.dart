part of 'geofence_bloc.dart';

enum GeofenceStatus {
  initial,
  loading,
  loaded,
  editing,
  submitting,
  success,
  deleting,
  deleted,
  error,
}

class GeofenceState extends Equatable {
  final GeofenceStatus status;
  final List<GeofenceEntity> geofences;
  final GeofenceEntity? editingGeofence;
  final String? errorMessage;
  const GeofenceState({
    required this.status,
    required this.geofences,
    this.editingGeofence,
    this.errorMessage,
  });
  factory GeofenceState.initial() =>
      const GeofenceState(status: GeofenceStatus.initial, geofences: []);
  bool get isLoading => status == GeofenceStatus.loading;
  bool get isSubmitting => status == GeofenceStatus.submitting;
  bool get isSuccess => status == GeofenceStatus.success;
  bool get hasError => status == GeofenceStatus.error;
  GeofenceState copyWith({
    GeofenceStatus? status,
    List<GeofenceEntity>? geofences,
    GeofenceEntity? editingGeofence,
    String? errorMessage,
  }) => GeofenceState(
    status: status ?? this.status,
    geofences: geofences ?? this.geofences,
    editingGeofence: editingGeofence ?? this.editingGeofence,
    errorMessage: errorMessage,
  );
  @override
  List<Object?> get props => [status, geofences, editingGeofence, errorMessage];
}
