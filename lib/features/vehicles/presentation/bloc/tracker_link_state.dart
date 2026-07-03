part of 'tracker_link_bloc.dart';

/// Status enum for tracker link state
enum TrackerLinkStatus {
  initial,
  validating,
  valid,
  invalid,
  linking,
  linked,
  unlinking,
  unlinked,
  error,
}

/// State for the TrackerLinkBloc
class TrackerLinkState extends Equatable {
  final TrackerLinkStatus status;
  final String? imei;
  final TrackerInfoEntity? trackerInfo;
  final VehicleEntity? vehicle;
  final String? errorMessage;

  const TrackerLinkState({
    required this.status,
    this.imei,
    this.trackerInfo,
    this.vehicle,
    this.errorMessage,
  });

  /// Initial state
  factory TrackerLinkState.initial() {
    return const TrackerLinkState(
      status: TrackerLinkStatus.initial,
    );
  }

  /// State helpers
  bool get isValidating => status == TrackerLinkStatus.validating;
  bool get isValid => status == TrackerLinkStatus.valid;
  bool get isInvalid => status == TrackerLinkStatus.invalid;
  bool get isLinking => status == TrackerLinkStatus.linking;
  bool get isLinked => status == TrackerLinkStatus.linked;
  bool get isUnlinking => status == TrackerLinkStatus.unlinking;
  bool get isUnlinked => status == TrackerLinkStatus.unlinked;
  bool get hasError => status == TrackerLinkStatus.error;
  bool get isLoading =>
      isValidating || isLinking || isUnlinking;

  /// Copy with modified fields
  TrackerLinkState copyWith({
    TrackerLinkStatus? status,
    String? imei,
    TrackerInfoEntity? trackerInfo,
    VehicleEntity? vehicle,
    String? errorMessage,
  }) {
    return TrackerLinkState(
      status: status ?? this.status,
      imei: imei ?? this.imei,
      trackerInfo: trackerInfo ?? this.trackerInfo,
      vehicle: vehicle ?? this.vehicle,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        imei,
        trackerInfo,
        vehicle,
        errorMessage,
      ];
}
