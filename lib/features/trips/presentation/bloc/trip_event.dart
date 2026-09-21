part of 'trip_bloc.dart';

sealed class TripEvent extends Equatable {
  const TripEvent();
  @override
  List<Object?> get props => [];
}

class TripsRequested extends TripEvent {
  const TripsRequested();
}

class TripStarted extends TripEvent {
  final VehicleEntity vehicle;
  const TripStarted(this.vehicle);
  @override
  List<Object?> get props => [vehicle];
}

class TripEnded extends TripEvent {
  final String tripId;
  const TripEnded(this.tripId);
  @override
  List<Object?> get props => [tripId];
}

class TripDetailRequested extends TripEvent {
  final String tripId;
  const TripDetailRequested(this.tripId);
  @override
  List<Object?> get props => [tripId];
}
