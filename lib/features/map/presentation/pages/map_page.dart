import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/permissions/permission_handler.dart';
import '../../../../core/permissions/permission_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../injection_container.dart';
import '../../../geofences/domain/entities/geofence.dart';
import '../../../geofences/presentation/bloc/geofence_bloc.dart';
import '../../domain/entities/trip_point.dart';
import '../../domain/entities/vehicle_location.dart';
import '../bloc/map_bloc.dart';
import '../widgets/map_controls.dart';
import '../widgets/trip_playback_controls.dart';
import '../widgets/vehicle_info_card.dart';
import '../widgets/vehicle_list_panel.dart';

/// Map page with real-time vehicle tracking
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _controllerCompleter = Completer();

  bool _showVehicleList = false;
  bool _locationPermissionGranted = false;
  bool _isGettingLocation = false;
  bool _locationServicesEnabled = true;
  bool _servicesBannerDismissed = false;

  // Default camera position (Mexico City)
  static const _defaultPosition = LatLng(19.4326, -99.1332);
  static const _defaultZoom = 12.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start watching vehicle locations
    context.read<MapBloc>().add(const StartWatchingLocations());
    // Check location permission
    _checkLocationPermission();
    _checkLocationServices();
  }

  Future<void> _checkLocationPermission() async {
    final permissionHandler = sl<AppPermissionHandler>();
    final status = await permissionHandler.checkPermission(
      AppPermission.location,
    );
    if (!mounted) return;

    setState(() => _locationPermissionGranted = status.isGranted);
    if (status.isGranted) {
      _centerOnCurrentLocationIfPermitted();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationServices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<MapBloc, MapState>(
        listenWhen: (previous, current) =>
            (previous.errorMessage != current.errorMessage &&
                current.errorMessage != null) ||
            (previous.tripStatus != current.tripStatus &&
                current.tripStatus == TripStatus.loaded) ||
            (previous.playbackPosition != current.playbackPosition &&
                current.currentPlaybackPoint != null),
        listener: (context, state) {
          if (state.errorMessage != null) {
            context.showErrorSnackBar(state.errorMessage!);
            context.read<MapBloc>().add(const ClearMapError());
          }
          if (state.tripStatus == TripStatus.loaded) {
            if (state.hasTripHistory) {
              _fitTripPoints(state.tripPoints);
            } else {
              context.showSnackBar('No trip data for this date');
            }
          }
          if (state.currentPlaybackPoint != null &&
              (state.isPlaying || state.isPaused)) {
            _followPlaybackPoint(state.tripPoints, state.playbackPosition);
          }
        },
        builder: (context, state) {
          final geofences = context.watch<GeofenceBloc>().state.geofences;
          return Stack(
            children: [
              // Google Map
              _buildMap(context, state, geofences),

              // Safe area overlay for status bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: MediaQuery.of(context).padding.top,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.8),
                ),
              ),

              // Top bar with search and menu
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: _buildTopBar(context, state),
              ),

              // Location services banner
              if (!_locationServicesEnabled && !_servicesBannerDismissed)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 60,
                  left: 16,
                  right: 16,
                  child: _buildServicesBanner(context),
                ),

              // Map controls (right side)
              Positioned(
                right: 16,
                top: MediaQuery.of(context).padding.top + 80,
                child: MapControls(
                  mapType: state.mapType,
                  showTraffic: state.showTraffic,
                  onZoomIn: _zoomIn,
                  onZoomOut: _zoomOut,
                  onMyLocation: _goToMyLocation,
                  onFitBounds: () => _fitAllVehicles(state.vehicleLocations),
                  onToggleTraffic: () {
                    context.read<MapBloc>().add(const ToggleTrafficLayer());
                  },
                  onMapTypeChanged: (type) {
                    context.read<MapBloc>().add(ChangeMapType(type));
                  },
                ),
              ),

              // Vehicle list panel (left side, sliding)
              if (_showVehicleList)
                Positioned(
                  top: 0,
                  left: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: VehicleListPanel(
                      vehicles: state.vehicleLocations,
                      selectedVehicle: state.selectedVehicle,
                      onVehicleSelected: (vehicle) {
                        _selectVehicle(context, vehicle);
                        setState(() => _showVehicleList = false);
                      },
                      onClose: () => setState(() => _showVehicleList = false),
                    ),
                  ),
                ),

              // Selected vehicle info card (bottom)
              if (state.hasSelectedVehicle && !state.hasTripHistory)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: VehicleInfoCard(
                    vehicle: state.selectedVehicle!,
                    onClose: () {
                      context.read<MapBloc>().add(
                        const ClearVehicleSelection(),
                      );
                    },
                    onViewHistory: () {
                      // TODO: Navigate to trip history page
                      _showTripHistoryDialog(context, state.selectedVehicle!);
                    },
                    onNavigate: () {
                      _openNavigation(state.selectedVehicle!);
                    },
                  ),
                ),

              if (state.hasTripHistory && state.currentPlaybackPoint != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: SafeArea(
                    top: false,
                    child: TripPlaybackControls(
                      currentPoint: state.currentPlaybackPoint!,
                      position: state.playbackPosition,
                      pointCount: state.tripPoints.length,
                      isPlaying: state.isPlaying,
                      speed: state.playbackSpeed,
                      onPlayPause: () {
                        context.read<MapBloc>().add(
                          state.isPlaying
                              ? const PauseTripPlayback()
                              : const StartTripPlayback(),
                        );
                      },
                      onStop: () =>
                          context.read<MapBloc>().add(const StopTripPlayback()),
                      onSeek: (position) => context.read<MapBloc>().add(
                        UpdatePlaybackPosition(position),
                      ),
                      onSpeedChanged: (speed) => context.read<MapBloc>().add(
                        ChangePlaybackSpeed(speed),
                      ),
                      onClose: () =>
                          context.read<MapBloc>().add(const ClearTripHistory()),
                    ),
                  ),
                ),

              // Loading overlay
              if (state.isLoading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black26,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _checkLocationServices() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (mounted) {
      // Show toast when services become enabled after being disabled
      final wasEnabled = _locationServicesEnabled;
      setState(() {
        _locationServicesEnabled = enabled;
      });
      if (!wasEnabled && enabled) {
        // Services transitioned to enabled
        context.showSuccessSnackBar('Location services enabled');
        // Reset dismissal so banner stays hidden naturally
        setState(() => _servicesBannerDismissed = false);
      }
    }
  }

  Widget _buildMap(
    BuildContext context,
    MapState state,
    List<GeofenceEntity> geofences,
  ) {
    final markers = _buildMarkers(
      state.vehicleLocations,
      state.selectedVehicle,
      playbackPoint: state.hasTripHistory ? state.currentPlaybackPoint : null,
    );
    final polylines = _buildTripPolylines(state);

    return SizedBox.expand(
      child: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: _defaultPosition,
          zoom: _defaultZoom,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
          if (!_controllerCompleter.isCompleted) {
            _controllerCompleter.complete(controller);
          }

          if (_locationPermissionGranted) {
            _centerOnCurrentLocationIfPermitted();
          }

          // Fit to show all vehicles once map is loaded
          if (state.vehicleLocations.isNotEmpty) {
            _fitAllVehicles(state.vehicleLocations);
          }
        },
        markers: markers,
        polylines: polylines,
        circles: _buildGeofenceCircles(geofences),
        mapType: _getGoogleMapType(state.mapType),
        trafficEnabled: state.showTraffic,
        myLocationEnabled: _locationPermissionGranted,
        myLocationButtonEnabled: false, // We use our own button
        zoomControlsEnabled: false,
        compassEnabled: true,
        mapToolbarEnabled: false,
        onTap: (_) {
          // Clear selection when tapping on map
          context.read<MapBloc>().add(const ClearVehicleSelection());
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, MapState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Menu button to show vehicle list
        Material(
          color: colorScheme.surface,
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => setState(() => _showVehicleList = !_showVehicleList),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Badge(
                isLabelVisible: state.vehicleLocations.isNotEmpty,
                label: Text('${state.vehicleLocations.length}'),
                child: Icon(
                  _showVehicleList ? Icons.close : Icons.menu,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Status bar showing vehicle counts
        Expanded(
          child: Material(
            color: colorScheme.surface,
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatusIndicator(
                    icon: Icons.directions_car,
                    label: 'Total',
                    count: state.vehicleLocations.length,
                    color: colorScheme.primary,
                  ),
                  _StatusIndicator(
                    icon: Icons.wifi,
                    label: 'Online',
                    count: state.onlineVehicleCount,
                    color: AppColors.statusOnline,
                  ),
                  _StatusIndicator(
                    icon: Icons.play_arrow,
                    label: 'Moving',
                    count: state.movingVehicleCount,
                    color: AppColors.statusMoving,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Set<Marker> _buildMarkers(
    List<VehicleLocationEntity> vehicles,
    VehicleLocationEntity? selectedVehicle, {
    TripPointEntity? playbackPoint,
  }) {
    final markers = vehicles.map((vehicle) {
      final markerColor = _getMarkerColor(vehicle.status);

      return Marker(
        markerId: MarkerId(vehicle.vehicleId),
        position: LatLng(vehicle.latitude, vehicle.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
        infoWindow: InfoWindow(
          title: vehicle.vehicleName,
          snippet: '${vehicle.plateNumber} • ${vehicle.formattedSpeed}',
        ),
        onTap: () => _selectVehicle(context, vehicle),
      );
    }).toSet();

    if (playbackPoint != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('trip-playback'),
          position: LatLng(playbackPoint.latitude, playbackPoint.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: 'Trip replay',
            snippet: playbackPoint.timestamp.formattedDateTime,
          ),
          zIndexInt: 2,
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildTripPolylines(MapState state) {
    final tripPoints = state.tripPoints;
    if (tripPoints.length < 2) return const {};

    if (!state.isPlaying && !state.isPaused) {
      return {
        Polyline(
          polylineId: const PolylineId('trip-history'),
          points: tripPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(),
          color: AppColors.routeColor,
          width: 5,
        ),
      };
    }

    final playedPoints = tripPoints.take(state.playbackPosition + 1).toList();
    final remainingPoints = tripPoints.skip(state.playbackPosition).toList();
    final polylines = <Polyline>{};

    if (playedPoints.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('trip-played'),
          points: playedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(),
          color: AppColors.routeColor,
          width: 6,
        ),
      );
    }

    if (remainingPoints.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('trip-remaining'),
          points: remainingPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(),
          color: Colors.blueGrey,
          width: 4,
        ),
      );
    }

    return polylines;
  }

  Set<Circle> _buildGeofenceCircles(List<GeofenceEntity> geofences) => geofences
      .where((geofence) => geofence.isActive)
      .map(
        (geofence) => Circle(
          circleId: CircleId('geofence-${geofence.id}'),
          center: LatLng(geofence.latitude, geofence.longitude),
          radius: geofence.radiusMeters,
          fillColor: AppColors.geofenceFill,
          strokeColor: AppColors.geofenceStroke,
          strokeWidth: 2,
        ),
      )
      .toSet();

  double _getMarkerColor(VehicleStatus status) {
    return switch (status) {
      VehicleStatus.moving => BitmapDescriptor.hueBlue,
      VehicleStatus.idle => BitmapDescriptor.hueOrange,
      VehicleStatus.offline => BitmapDescriptor.hueRed,
    };
  }

  MapType _getGoogleMapType(MapViewType type) {
    return switch (type) {
      MapViewType.normal => MapType.normal,
      MapViewType.satellite => MapType.satellite,
      MapViewType.terrain => MapType.terrain,
      MapViewType.hybrid => MapType.hybrid,
    };
  }

  void _selectVehicle(BuildContext context, VehicleLocationEntity vehicle) {
    context.read<MapBloc>().add(SelectVehicle(vehicle));
    _animateToPosition(LatLng(vehicle.latitude, vehicle.longitude));
  }

  Future<void> _animateToPosition(LatLng position, {double zoom = 15}) async {
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, zoom),
    );
  }

  void _followPlaybackPoint(List<TripPointEntity> points, int position) {
    final point = points[position];
    final bearing = position == 0
        ? 0.0
        : _bearingBetween(points[position - 1], point);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(point.latitude, point.longitude),
          zoom: 17,
          tilt: 45,
          bearing: bearing,
        ),
      ),
    );
  }

  double _bearingBetween(TripPointEntity from, TripPointEntity to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final deltaLng = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(deltaLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// Center the map at startup only when location access was granted earlier.
  Future<void> _centerOnCurrentLocationIfPermitted() async {
    if (_mapController == null) return;

    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;

      await _animateToPosition(
        LatLng(position.latitude, position.longitude),
        zoom: 16,
      );
    } catch (_) {
      // Keep the default camera position when automatic centering is unavailable.
    }
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  Future<void> _goToMyLocation() async {
    if (_isGettingLocation) return;

    setState(() => _isGettingLocation = true);
    // Re-show banner once user tries to go to My Location again
    if (mounted) {
      setState(() => _servicesBannerDismissed = false);
    }

    try {
      final permissionHandler = sl<AppPermissionHandler>();

      // Check and request permission if needed
      var status = await permissionHandler.checkPermission(
        AppPermission.location,
      );

      if (status != AppPermissionStatus.granted) {
        status = await permissionHandler.requestPermission(
          AppPermission.location,
        );
      }

      if (status == AppPermissionStatus.granted) {
        setState(() => _locationPermissionGranted = true);

        // Check if location services are enabled
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            _showEnableLocationServicesDialog();
          }
          return;
        }

        // Get current position
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );

        // Animate to current position
        await _animateToPosition(
          LatLng(position.latitude, position.longitude),
          zoom: 16,
        );
      } else if (status == AppPermissionStatus.permanentlyDenied) {
        if (mounted) {
          _showLocationPermissionDialog();
        }
      } else {
        if (mounted) {
          context.showErrorSnackBar('Location permission denied');
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to get location: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location permission is permanently denied. '
          'Please enable it in app settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              sl<AppPermissionHandler>().openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showEnableLocationServicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Location Services'),
        content: const Text(
          'Location services are turned off.\n\n'
          'Please enable them in system settings to use My Location and real-time updates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.gps_off, color: colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Location services are off. Enable them for accurate tracking.',
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
            TextButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                await _checkLocationServices();
              },
              child: const Text('Enable'),
            ),
            IconButton(
              tooltip: 'Dismiss',
              icon: Icon(Icons.close, color: colorScheme.onErrorContainer),
              onPressed: () {
                setState(() => _servicesBannerDismissed = true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fitAllVehicles(List<VehicleLocationEntity> vehicles) async {
    if (vehicles.isEmpty) return;

    if (vehicles.length == 1) {
      await _animateToPosition(
        LatLng(vehicles.first.latitude, vehicles.first.longitude),
      );
      return;
    }

    // Calculate bounds
    double minLat = vehicles.first.latitude;
    double maxLat = vehicles.first.latitude;
    double minLng = vehicles.first.longitude;
    double maxLng = vehicles.first.longitude;

    for (final vehicle in vehicles) {
      if (vehicle.latitude < minLat) minLat = vehicle.latitude;
      if (vehicle.latitude > maxLat) maxLat = vehicle.latitude;
      if (vehicle.longitude < minLng) minLng = vehicle.longitude;
      if (vehicle.longitude > maxLng) maxLng = vehicle.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  Future<void> _fitTripPoints(List<TripPointEntity> points) async {
    if (points.isEmpty) return;

    if (points.length == 1) {
      await _animateToPosition(
        LatLng(points.first.latitude, points.first.longitude),
      );
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    if (minLat == maxLat && minLng == maxLng) {
      await _animateToPosition(LatLng(minLat, minLng));
      return;
    }

    await _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50,
      ),
    );
  }

  void _showTripHistoryDialog(
    BuildContext context,
    VehicleLocationEntity vehicle,
  ) {
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: 30));
    final lastUpdate = vehicle.lastUpdate.toLocal();
    final initialDate =
        lastUpdate.isBefore(firstDate) || lastUpdate.isAfter(now)
        ? now
        : lastUpdate;

    showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now,
    ).then((selectedDate) {
      if (selectedDate != null) {
        context.read<MapBloc>().add(
          LoadTripHistory(
            startDate: DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
            ),
            endDate: DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              23,
              59,
              59,
            ),
          ),
        );
      }
    });
  }

  void _openNavigation(VehicleLocationEntity vehicle) {
    // TODO: Open Google Maps or Apple Maps for navigation
    context.showSnackBar('Opening navigation to ${vehicle.vehicleName}...');
  }
}

class _StatusIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatusIndicator({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
