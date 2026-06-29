part of 'tracker_link_bloc.dart';

/// Events for the TrackerLinkBloc
sealed class TrackerLinkEvent extends Equatable {
  const TrackerLinkEvent();

  @override
  List<Object?> get props => [];
}

/// Validate an IMEI before linking
class ValidateImei extends TrackerLinkEvent {
  final String imei;

  const ValidateImei({required this.imei});

  @override
  List<Object?> get props => [imei];
}

/// Link a tracker to a vehicle
class LinkTrackerToVehicle extends TrackerLinkEvent {
  final String vehicleId;
  final String imei;

  const LinkTrackerToVehicle({
    required this.vehicleId,
    required this.imei,
  });

  @override
  List<Object?> get props => [vehicleId, imei];
}

/// Unlink a tracker from a vehicle
class UnlinkTrackerFromVehicle extends TrackerLinkEvent {
  final String vehicleId;

  const UnlinkTrackerFromVehicle({required this.vehicleId});

  @override
  List<Object?> get props => [vehicleId];
}

/// Reset tracker link state
class ResetTrackerLink extends TrackerLinkEvent {
  const ResetTrackerLink();
}

/// Clear tracker error
class ClearTrackerError extends TrackerLinkEvent {
  const ClearTrackerError();
}
