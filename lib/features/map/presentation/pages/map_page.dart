import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/permissions/permission_handler.dart';
import '../../../../core/permissions/permission_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/vehicle_location.dart';
import '../bloc/map_bloc.dart';
import '../widgets/map_controls.dart';
import '../widgets/vehicle_info_card.dart';
import '../widgets/vehicle_list_panel.dart';

/// Map page with real-time vehicle tracking
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _controllerCompleter = Completer();

  bool _showVehicleList = false;
  bool _locationPermissionGranted = false;
  bool _isGettingLocation = false;

  // Default camera position (Mexico City)
  static const _defaultPosition = LatLng(19.4326, -99.1332);
  static const _defaultZoom = 12.0;

  @override
  void initState() {
    super.initState();
    // Start watching vehicle locations
    context.read<MapBloc>().add(const StartWatchingLocations());
    // Check location permission
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final permissionHandler = sl<AppPermissionHandler>();
    final status = await permissionHandler.checkPermission(AppPermission.location);
    if (mounted) {
      setState(() {
        _locationPermissionGranted = status == AppPermissionStatus.granted;
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<MapBloc, MapState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage &&
            current.errorMessage != null,
        listener: (context, state) {
          if (state.errorMessage != null) {
            context.showErrorSnackBar(state.errorMessage!);
            context.read<MapBloc>().add(const ClearMapError());
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Google Map
              _buildMap(context, state),

              // Safe area overlay for status bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: MediaQuery.of(context).padding.top,
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.8),
                ),
              ),

              // Top bar with search and menu
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: _buildTopBar(context, state),
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
              if (state.hasSelectedVehicle)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: VehicleInfoCard(
                    vehicle: state.selectedVehicle!,
                    onClose: () {
                      context
                          .read<MapBloc>()
                          .add(const ClearVehicleSelection());
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

              // Loading overlay
              if (state.isLoading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black26,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(BuildContext context, MapState state) {
    final markers = _buildMarkers(state.vehicleLocations, state.selectedVehicle);

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

        // Fit to show all vehicles once map is loaded
        if (state.vehicleLocations.isNotEmpty) {
          _fitAllVehicles(state.vehicleLocations);
        }
      },
        markers: markers,
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
    VehicleLocationEntity? selectedVehicle,
  ) {
    return vehicles.map((vehicle) {
      final markerColor = _getMarkerColor(vehicle.status);

      return Marker(
        markerId: MarkerId(vehicle.vehicleId),
        position: LatLng(vehicle.latitude, vehicle.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
        infoWindow: InfoWindow(
          title: vehicle.vehicleName,
          snippet:
              '${vehicle.plateNumber} • ${vehicle.formattedSpeed}',
        ),
        onTap: () => _selectVehicle(context, vehicle),
      );
    }).toSet();
  }

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

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  Future<void> _goToMyLocation() async {
    if (_isGettingLocation) return;

    setState(() => _isGettingLocation = true);

    try {
      final permissionHandler = sl<AppPermissionHandler>();
      
      // Check and request permission if needed
      var status = await permissionHandler.checkPermission(AppPermission.location);
      
      if (status != AppPermissionStatus.granted) {
        status = await permissionHandler.requestPermission(AppPermission.location);
      }

      if (status == AppPermissionStatus.granted) {
        setState(() => _locationPermissionGranted = true);

        // Check if location services are enabled
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            context.showErrorSnackBar('Please enable location services');
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

  void _showTripHistoryDialog(
    BuildContext context,
    VehicleLocationEntity vehicle,
  ) {
    // Simple date picker for now
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    ).then((selectedDate) {
      if (selectedDate != null) {
        context.read<MapBloc>().add(LoadTripHistory(
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
            ));
      }
    });
  }

  void _openNavigation(VehicleLocationEntity vehicle) {
    // TODO: Open Google Maps or Apple Maps for navigation
    context.showSnackBar(
      'Opening navigation to ${vehicle.vehicleName}...',
    );
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
