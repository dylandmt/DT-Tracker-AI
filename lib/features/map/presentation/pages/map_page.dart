import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/design/dt_components.dart';
import '../../../../core/design/dt_design_tokens.dart';
import '../../../../core/design/dt_vehicle_marker.dart';
import '../../../../core/permissions/permission_handler.dart';
import '../../../../core/permissions/permission_status.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../injection_container.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../geofences/domain/entities/geofence.dart';
import '../../../geofences/presentation/bloc/geofence_bloc.dart';
import '../../../social/data/datasources/social_backend_datasource.dart';
import '../../../vehicles/presentation/cubit/selected_vehicle_cubit.dart';
import '../../domain/entities/trip_point.dart';
import '../../domain/entities/vehicle_location.dart';
import '../bloc/map_bloc.dart';
import '../utils/map_panel_coordinator.dart';
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

  final _panelCoordinator = MapPanelCoordinator();
  bool _locationPermissionGranted = false;
  bool _isGettingLocation = false;
  bool _locationServicesEnabled = true;
  bool _servicesBannerDismissed = false;
  List<_SharedVehicleLocation> _sharedLocations = const [];
  Timer? _sharedLocationsTimer;
  final Map<VehicleStatus, BitmapDescriptor> _vehicleMarkers = {};
  Brightness? _markerBrightness;
  double? _markerPixelRatio;
  VehicleSheetStage _vehicleSheetStage = VehicleSheetStage.intermediate;

  // Default camera position (Mexico City)
  static const _defaultPosition = LatLng(19.4326, -99.1332);
  static const _defaultZoom = 12.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start watching vehicle locations
    context.read<MapBloc>().add(const StartWatchingLocations());
    _loadSharedLocations();
    _sharedLocationsTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadSharedLocations(),
    );
    // Check location permission
    _checkLocationPermission();
    _checkLocationServices();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    if (_markerBrightness != brightness || _markerPixelRatio != pixelRatio) {
      _markerBrightness = brightness;
      _markerPixelRatio = pixelRatio;
      _vehicleMarkers.clear();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadVehicleMarkers(),
      );
    }
  }

  Future<void> _loadVehicleMarkers() async {
    if (!mounted) return;
    final colors = context.dtColors;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final markers = await Future.wait(
      VehicleStatus.values.map(
        (status) => DTVehicleMarker.create(
          accent: switch (status) {
            VehicleStatus.moving => colors.moving,
            VehicleStatus.idle => colors.idle,
            VehicleStatus.offline => colors.offline,
          },
          surface: colors.surfaceOverlay,
          onPrimary: onPrimary,
          devicePixelRatio: _markerPixelRatio ?? 1,
          haloOpacity: status == VehicleStatus.offline ? .06 : .1,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      for (var index = 0; index < VehicleStatus.values.length; index += 1) {
        _vehicleMarkers[VehicleStatus.values[index]] = markers[index];
      }
    });
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
    _sharedLocationsTimer?.cancel();
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
      body: BlocListener<SelectedVehicleCubit, SelectedVehicleState>(
        listenWhen: (previous, current) =>
            previous.selectedVehicle?.id != current.selectedVehicle?.id,
        listener: (_, __) => _syncMapSelection(),
        child: BlocConsumer<MapBloc, MapState>(
          listenWhen: (previous, current) =>
              (previous.errorMessage != current.errorMessage &&
                  current.errorMessage != null) ||
              (previous.tripStatus != current.tripStatus &&
                  current.tripStatus == TripStatus.loaded) ||
              (previous.playbackPosition != current.playbackPosition &&
                  current.currentPlaybackPoint != null) ||
              previous.vehicleLocations != current.vehicleLocations,
          listener: (context, state) {
            _syncMapSelection();
            if (state.errorMessage != null) {
              context.showErrorSnackBar(state.errorMessage!);
              context.read<MapBloc>().add(const ClearMapError());
            }
            if (state.tripStatus == TripStatus.loaded) {
              if (state.hasTripHistory) {
                _fitTripPoints(state.tripPoints);
              } else {
                context.showSnackBar(
                  AppLocalizations.of(context)!.noTripDataForDate,
                );
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

                // Secondary controls yield visual space while details are expanded.
                Positioned(
                  right: DTSpacing.md,
                  top: MediaQuery.of(context).padding.top + 80,
                  child: IgnorePointer(
                    ignoring: _vehicleSheetStage == VehicleSheetStage.expanded,
                    child: AnimatedOpacity(
                      opacity: _vehicleSheetStage == VehicleSheetStage.expanded
                          ? 0
                          : 1,
                      duration: MediaQuery.of(context).disableAnimations
                          ? Duration.zero
                          : DTMotion.fast,
                      child: MapControls(
                        mapType: state.mapType,
                        showTraffic: state.showTraffic,
                        onZoomIn: _zoomIn,
                        onZoomOut: _zoomOut,
                        onMyLocation: _goToMyLocation,
                        onFitBounds: () =>
                            _fitAllVehicles(state.vehicleLocations),
                        onToggleTraffic: () {
                          context.read<MapBloc>().add(
                            const ToggleTrafficLayer(),
                          );
                        },
                        onMapTypeChanged: (type) {
                          context.read<MapBloc>().add(ChangeMapType(type));
                        },
                      ),
                    ),
                  ),
                ),

                // Vehicle list panel (left side, sliding)
                if (_panelCoordinator.vehicleListVisible)
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
                        },
                        onClose: () =>
                            setState(_panelCoordinator.closeVehicleList),
                      ),
                    ),
                  ),

                // Selected vehicle sheet with compact, medium and expanded states.
                if (_panelCoordinator.shouldShowVehicleSheet(
                      state.hasSelectedVehicle,
                    ) &&
                    !state.hasTripHistory)
                  Positioned.fill(
                    child: VehicleInfoCard(
                      key: ValueKey(state.selectedVehicle!.vehicleId),
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
                      onGeofences: () => context.push(RouteConstants.geofences),
                      onAlerts: () => context.push(RouteConstants.alerts),
                      onShare: () => context.push(RouteConstants.shareLocation),
                      onLiveTracking: () => _animateToPosition(
                        LatLng(
                          state.selectedVehicle!.latitude,
                          state.selectedVehicle!.longitude,
                        ),
                      ),
                      onStageChanged: (stage) {
                        if (_vehicleSheetStage != stage) {
                          setState(() => _vehicleSheetStage = stage);
                        }
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
                        onStop: () => context.read<MapBloc>().add(
                          const StopTripPlayback(),
                        ),
                        onSeek: (position) => context.read<MapBloc>().add(
                          UpdatePlaybackPosition(position),
                        ),
                        onSpeedChanged: (speed) => context.read<MapBloc>().add(
                          ChangePlaybackSpeed(speed),
                        ),
                        onClose: () => context.read<MapBloc>().add(
                          const ClearTripHistory(),
                        ),
                      ),
                    ),
                  ),

                // Loading overlay
                if (state.isLoading)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Theme.of(
                        context,
                      ).colorScheme.scrim.withValues(alpha: .18),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),

                if (state.isTripLoading)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Theme.of(
                        context,
                      ).colorScheme.scrim.withValues(alpha: .18),
                      child: Center(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.loadingTripHistory,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
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
        context.showSuccessSnackBar(
          AppLocalizations.of(context)!.locationServicesEnabled,
        );
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
    markers.addAll(_buildSharedMarkers(_sharedLocations));
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
        style: Theme.of(context).brightness == Brightness.dark
            ? _darkMapStyle
            : _lightMapStyle,
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
    return Row(
      children: [
        DTMapActionButton(
          icon: Badge(
            isLabelVisible: state.vehicleLocations.isNotEmpty,
            label: Text('${state.vehicleLocations.length}'),
            child: Icon(
              _panelCoordinator.vehicleListVisible ? Icons.close : Icons.menu,
            ),
          ),
          tooltip: AppLocalizations.of(context)!.vehicles,
          onPressed: () => setState(() {
            if (_panelCoordinator.vehicleListVisible) {
              _panelCoordinator.closeVehicleList();
            } else {
              _panelCoordinator.openVehicleList();
            }
          }),
        ),
        const SizedBox(width: DTSpacing.xs),
        Expanded(
          child: DTGlassCard(
            padding: const EdgeInsets.symmetric(
              horizontal: DTSpacing.sm,
              vertical: DTSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatusIndicator(
                  icon: Icons.directions_car_outlined,
                  label: AppLocalizations.of(context)!.total,
                  count: state.vehicleLocations.length,
                  color: Theme.of(context).colorScheme.primary,
                ),
                _StatusIndicator(
                  icon: Icons.wifi_outlined,
                  label: AppLocalizations.of(context)!.online,
                  count: state.onlineVehicleCount,
                  color: context.dtColors.online,
                ),
                _StatusIndicator(
                  icon: Icons.play_arrow_outlined,
                  label: AppLocalizations.of(context)!.moving,
                  count: state.movingVehicleCount,
                  color: context.dtColors.moving,
                ),
              ],
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
      return Marker(
        markerId: MarkerId(vehicle.vehicleId),
        position: LatLng(vehicle.latitude, vehicle.longitude),
        icon:
            _vehicleMarkers[vehicle.status] ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow.noText,
        onTap: () => _selectVehicle(context, vehicle),
        zIndexInt: selectedVehicle?.vehicleId == vehicle.vehicleId ? 2 : 1,
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
            title: AppLocalizations.of(context)!.tripReplay,
            snippet: playbackPoint.timestamp.localizedDateTime(context),
          ),
          zIndexInt: 2,
        ),
      );
    }

    return markers;
  }

  Future<void> _loadSharedLocations() async {
    try {
      final social = sl<SocialBackendDataSource>();
      final shares = await social.incomingLocationShares();
      final visibleShares = shares.where((share) {
        final status = share['status']?.toString().toLowerCase();
        return status != 'revoked' && status != 'expired';
      }).toList();
      final responses = await Future.wait<Map<String, dynamic>?>(
        visibleShares.map((share) async {
          try {
            return await social.sharedLocations(share['shareId'].toString());
          } catch (_) {
            return null;
          }
        }),
      );
      final locations = responses.indexed
          .expand((entry) {
            final response = entry.$2;
            if (response == null) return const <_SharedVehicleLocation>[];
            final values = response['locations'];
            if (values is! List) return const <_SharedVehicleLocation>[];
            final share = visibleShares[entry.$1];
            return values.whereType<Map>().map(
              (location) => _SharedVehicleLocation.fromJson(location, share),
            );
          })
          .whereType<_SharedVehicleLocation>()
          .toList();
      if (mounted) setState(() => _sharedLocations = locations);
    } catch (_) {
      // Shared locations are optional and should not disrupt owner tracking.
    }
  }

  Set<Marker> _buildSharedMarkers(List<_SharedVehicleLocation> locations) {
    return locations
        .map(
          (location) => Marker(
            markerId: MarkerId(
              'shared_${location.ownerUid}_${location.vehicleId}',
            ),
            position: LatLng(location.latitude, location.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet,
            ),
            infoWindow: InfoWindow(
              title: location.ownerName.isEmpty
                  ? context.l10n.user
                  : location.ownerName,
              snippet: location.vehicleName,
            ),
          ),
        )
        .toSet();
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
          color: Theme.of(context).colorScheme.primary,
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
          color: Theme.of(context).colorScheme.primary,
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
          color: context.dtColors.muted,
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
          fillColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: .2),
          strokeColor: Theme.of(context).colorScheme.primary,
          strokeWidth: 2,
        ),
      )
      .toSet();

  MapType _getGoogleMapType(MapViewType type) {
    return switch (type) {
      MapViewType.normal => MapType.normal,
      MapViewType.satellite => MapType.satellite,
      MapViewType.terrain => MapType.terrain,
      MapViewType.hybrid => MapType.hybrid,
    };
  }

  void _selectVehicle(BuildContext context, VehicleLocationEntity vehicle) {
    final selectedFromList = _panelCoordinator.vehicleListVisible;
    setState(() {
      if (selectedFromList) {
        _panelCoordinator.selectVehicle();
      } else {
        _panelCoordinator.selectMarker();
      }
    });
    if (_vehicleSheetStage != VehicleSheetStage.intermediate) {
      setState(() => _vehicleSheetStage = VehicleSheetStage.intermediate);
    }
    context.read<SelectedVehicleCubit>().selectVehicle(vehicle.vehicleId);
    _animateToPosition(LatLng(vehicle.latitude, vehicle.longitude));
  }

  void _syncMapSelection() {
    if (!mounted) return;
    final selectedId = context
        .read<SelectedVehicleCubit>()
        .state
        .selectedVehicle
        ?.id;
    final mapBloc = context.read<MapBloc>();
    final currentId = mapBloc.state.selectedVehicle?.vehicleId;
    if (selectedId == currentId) return;
    final location = mapBloc.state.vehicleLocations
        .where((item) => item.vehicleId == selectedId)
        .firstOrNull;
    if (location == null) {
      mapBloc.add(const ClearVehicleSelection());
      return;
    }
    mapBloc.add(SelectVehicle(location));
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
          context.showErrorSnackBar(
            AppLocalizations.of(context)!.locationPermissionDenied,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e.toString());
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
        title: Text(context.l10n.locationPermissionRequired),
        content: Text(context.l10n.locationPermissionPermanentlyDenied),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              sl<AppPermissionHandler>().openSettings();
            },
            child: Text(context.l10n.openSettings),
          ),
        ],
      ),
    );
  }

  void _showEnableLocationServicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.enableLocationServices),
        content: Text(context.l10n.locationServicesTurnedOff),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: Text(context.l10n.openSettings),
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
                context.l10n.locationServicesOffBanner,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
            TextButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                await _checkLocationServices();
              },
              child: Text(context.l10n.enable),
            ),
            IconButton(
              tooltip: context.l10n.dismiss,
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
      if (selectedDate != null && context.mounted) {
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

  Future<void> _openNavigation(VehicleLocationEntity vehicle) async {
    final destination = '${vehicle.latitude},${vehicle.longitude}';
    final navigationUri = Platform.isIOS
        ? Uri.http('maps.apple.com', '/', {'daddr': destination})
        : Uri(scheme: 'google.navigation', queryParameters: {'q': destination});
    final fallbackUri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });

    final launched = await launchUrl(
      navigationUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    }
  }
}

const _darkMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#050B16"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#A5B6D2"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#050B16"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#0B1629"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#101F36"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#253D5D"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#081326"}]}
]''';

const _lightMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#F7F9FD"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#58687F"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#FFFFFF"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#EEF3FA"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#FFFFFF"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#D7E8FF"}]}
]''';

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

class _SharedVehicleLocation {
  const _SharedVehicleLocation({
    required this.ownerUid,
    required this.ownerName,
    required this.vehicleId,
    required this.latitude,
    required this.longitude,
    required this.vehicleName,
  });

  final String ownerUid;
  final String ownerName;
  final String vehicleId;
  final double latitude;
  final double longitude;
  final String vehicleName;

  static _SharedVehicleLocation? fromJson(
    Map<dynamic, dynamic> json,
    Map<String, dynamic> share,
  ) {
    final point = json['location'] is Map
        ? json['location'] as Map
        : json['coordinates'] is Map
        ? json['coordinates'] as Map
        : json;
    final lat = _coordinate(point['lat'] ?? point['latitude']);
    final lng = _coordinate(point['lng'] ?? point['longitude']);
    if (lat == null || lng == null) return null;

    final owner = json['owner'];
    final ownerMap = owner is Map ? owner : const <dynamic, dynamic>{};
    final ownerUid =
        ownerMap['uid']?.toString() ?? share['ownerUid']?.toString() ?? '';
    final nameParts =
        [
              ownerMap['firstName'],
              ownerMap['lastName'],
              ownerMap['secondLastName'],
            ]
            .map((value) => value?.toString().trim() ?? '')
            .where((value) => value.isNotEmpty)
            .toList();
    final ownerName = nameParts.isNotEmpty
        ? nameParts.join(' ')
        : ownerMap['email']?.toString() ??
              ownerMap['username']?.toString() ??
              '';

    return _SharedVehicleLocation(
      ownerUid: ownerUid,
      ownerName: ownerName,
      vehicleId: json['vehicleId']?.toString() ?? '',
      latitude: lat,
      longitude: lng,
      vehicleName:
          json['vehicleName']?.toString() ??
          [json['vehicleBrand'], json['vehicleModel'], json['vehicleYear']]
              .where((value) => value != null && value.toString().isNotEmpty)
              .join(' '),
    );
  }

  static double? _coordinate(Object? value) => switch (value) {
    num value => value.toDouble(),
    String value => double.tryParse(value),
    _ => null,
  };
}
