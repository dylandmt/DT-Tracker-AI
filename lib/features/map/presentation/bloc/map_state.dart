part of 'map_bloc.dart';

/// Status of the map data loading
enum MapStatus {
  initial,
  loading,
  loaded,
  error,
}

/// Status of trip history loading
enum TripStatus {
  initial,
  loading,
  loaded,
  error,
}

/// Status of trip playback
enum PlaybackStatus {
  idle,
  playing,
  paused,
}

/// Map view type
enum MapViewType {
  normal,
  satellite,
  terrain,
  hybrid,
}

/// State for the MapBloc
class MapState extends Equatable {
  /// Current map data status
  final MapStatus status;

  /// List of all vehicle locations
  final List<VehicleLocationEntity> vehicleLocations;

  /// Currently selected vehicle (for details/focus)
  final VehicleLocationEntity? selectedVehicle;

  /// Trip history status
  final TripStatus tripStatus;

  /// Trip history data
  final TripEntity? tripHistory;

  /// Trip points for playback
  final List<TripPointEntity> tripPoints;

  /// Current playback position (index in tripPoints)
  final int playbackPosition;

  /// Playback status
  final PlaybackStatus playbackStatus;

  /// Error message
  final String? errorMessage;

  /// Whether to show traffic layer
  final bool showTraffic;

  /// Current map type
  final MapViewType mapType;

  const MapState({
    this.status = MapStatus.initial,
    this.vehicleLocations = const [],
    this.selectedVehicle,
    this.tripStatus = TripStatus.initial,
    this.tripHistory,
    this.tripPoints = const [],
    this.playbackPosition = 0,
    this.playbackStatus = PlaybackStatus.idle,
    this.errorMessage,
    this.showTraffic = false,
    this.mapType = MapViewType.normal,
  });

  /// Whether the map is loading
  bool get isLoading => status == MapStatus.loading;

  /// Whether the map has loaded
  bool get isLoaded => status == MapStatus.loaded;

  /// Whether there's an error
  bool get hasError => status == MapStatus.error;

  /// Whether a vehicle is selected
  bool get hasSelectedVehicle => selectedVehicle != null;

  /// Whether there's trip history loaded
  bool get hasTripHistory => tripHistory != null && tripPoints.isNotEmpty;

  /// Whether trip is loading
  bool get isTripLoading => tripStatus == TripStatus.loading;

  /// Whether playback is active
  bool get isPlaying => playbackStatus == PlaybackStatus.playing;

  /// Whether playback is paused
  bool get isPaused => playbackStatus == PlaybackStatus.paused;

  /// Current playback point
  TripPointEntity? get currentPlaybackPoint {
    if (tripPoints.isEmpty || playbackPosition >= tripPoints.length) {
      return null;
    }
    return tripPoints[playbackPosition];
  }

  /// Playback progress (0.0 - 1.0)
  double get playbackProgress {
    if (tripPoints.isEmpty) return 0;
    return playbackPosition / (tripPoints.length - 1);
  }

  /// Number of online vehicles
  int get onlineVehicleCount {
    return vehicleLocations.where((v) => v.isOnline).length;
  }

  /// Number of moving vehicles
  int get movingVehicleCount {
    return vehicleLocations.where((v) => v.isMoving).length;
  }

  /// Create a copy with updated values
  MapState copyWith({
    MapStatus? status,
    List<VehicleLocationEntity>? vehicleLocations,
    VehicleLocationEntity? selectedVehicle,
    bool clearSelectedVehicle = false,
    TripStatus? tripStatus,
    TripEntity? tripHistory,
    List<TripPointEntity>? tripPoints,
    int? playbackPosition,
    PlaybackStatus? playbackStatus,
    String? errorMessage,
    bool? showTraffic,
    MapViewType? mapType,
  }) {
    return MapState(
      status: status ?? this.status,
      vehicleLocations: vehicleLocations ?? this.vehicleLocations,
      selectedVehicle:
          clearSelectedVehicle ? null : selectedVehicle ?? this.selectedVehicle,
      tripStatus: tripStatus ?? this.tripStatus,
      tripHistory: tripHistory ?? this.tripHistory,
      tripPoints: tripPoints ?? this.tripPoints,
      playbackPosition: playbackPosition ?? this.playbackPosition,
      playbackStatus: playbackStatus ?? this.playbackStatus,
      errorMessage: errorMessage,
      showTraffic: showTraffic ?? this.showTraffic,
      mapType: mapType ?? this.mapType,
    );
  }

  @override
  List<Object?> get props => [
        status,
        vehicleLocations,
        selectedVehicle,
        tripStatus,
        tripHistory,
        tripPoints,
        playbackPosition,
        playbackStatus,
        errorMessage,
        showTraffic,
        mapType,
      ];
}
