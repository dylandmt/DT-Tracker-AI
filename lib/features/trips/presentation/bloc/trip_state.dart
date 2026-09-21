part of 'trip_bloc.dart';

class TripState extends Equatable {
  final TripEntity? activeTrip;
  final List<TripEntity> trips;
  final List<VehicleEntity> vehicles;
  final TripEntity? selectedTrip;
  final bool isLoading;
  final bool isStarting;
  final bool isEnding;
  final bool isLoadingDetail;
  final Failure? failure;
  const TripState({
    this.activeTrip,
    this.trips = const [],
    this.vehicles = const [],
    this.selectedTrip,
    this.isLoading = false,
    this.isStarting = false,
    this.isEnding = false,
    this.isLoadingDetail = false,
    this.failure,
  });
  List<VehicleEntity> get linkedVehicles =>
      vehicles.where((vehicle) => vehicle.hasTracker).toList();
  TripState copyWith({
    TripEntity? activeTrip,
    bool clearActiveTrip = false,
    List<TripEntity>? trips,
    List<VehicleEntity>? vehicles,
    TripEntity? selectedTrip,
    bool? isLoading,
    bool? isStarting,
    bool? isEnding,
    bool? isLoadingDetail,
    Failure? failure,
    bool clearFailure = false,
  }) => TripState(
    activeTrip: clearActiveTrip ? null : activeTrip ?? this.activeTrip,
    trips: trips ?? this.trips,
    vehicles: vehicles ?? this.vehicles,
    selectedTrip: selectedTrip ?? this.selectedTrip,
    isLoading: isLoading ?? this.isLoading,
    isStarting: isStarting ?? this.isStarting,
    isEnding: isEnding ?? this.isEnding,
    isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
    failure: clearFailure ? null : failure ?? this.failure,
  );
  @override
  List<Object?> get props => [
    activeTrip,
    trips,
    vehicles,
    selectedTrip,
    isLoading,
    isStarting,
    isEnding,
    isLoadingDetail,
    failure,
  ];
}
