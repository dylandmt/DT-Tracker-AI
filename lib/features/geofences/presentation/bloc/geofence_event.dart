part of 'geofence_bloc.dart';

sealed class GeofenceEvent extends Equatable {
  const GeofenceEvent();
  @override
  List<Object?> get props => [];
}

class LoadGeofences extends GeofenceEvent {
  const LoadGeofences();
}

class WatchGeofencesRequested extends GeofenceEvent {
  const WatchGeofencesRequested();
}

class LoadGeofenceForEdit extends GeofenceEvent {
  final String id;
  const LoadGeofenceForEdit(this.id);
  @override
  List<Object?> get props => [id];
}

class GeofencesUpdated extends GeofenceEvent {
  final List<GeofenceEntity>? geofences;
  final String? error;
  const GeofencesUpdated({this.geofences, this.error});
  @override
  List<Object?> get props => [geofences, error];
}

class SubmitGeofence extends GeofenceEvent {
  final String? id;
  final GeofenceParams params;
  const SubmitGeofence({this.id, required this.params});
  @override
  List<Object?> get props => [id, params];
}

class DeleteGeofenceRequested extends GeofenceEvent {
  final String id;
  const DeleteGeofenceRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class ClearGeofenceError extends GeofenceEvent {
  const ClearGeofenceError();
}
