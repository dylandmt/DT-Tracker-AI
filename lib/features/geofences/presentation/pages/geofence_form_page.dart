import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/permissions/permission_handler.dart';
import '../../../../core/permissions/permission_status.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../injection_container.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/domain/usecases/get_vehicles.dart';
import '../../domain/entities/geofence.dart';
import '../../domain/usecases/geofence_usecases.dart';
import '../bloc/geofence_bloc.dart';

class GeofenceFormPage extends StatefulWidget {
  final String? geofenceId;
  const GeofenceFormPage({super.key, this.geofenceId});
  bool get isEditing => geofenceId != null;
  @override
  State<GeofenceFormPage> createState() => _GeofenceFormPageState();
}

class _GeofenceFormPageState extends State<GeofenceFormPage> {
  static const _defaultCenter = LatLng(19.4326, -99.1332);
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  double _radiusMeters = AppConstants.defaultGeofenceRadiusMeters;
  LatLng _center = _defaultCenter;
  List<VehicleEntity> _linkedVehicles = [];
  Set<String> _vehicleIds = {};
  bool _triggerOnEnter = true;
  bool _triggerOnExit = true;
  bool _isActive = true;
  bool _hasSelectedArea = false;
  bool _loaded = false;
  bool _loadingVehicles = true;
  GoogleMapController? _mapController;
  bool _isGettingCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    if (widget.isEditing) {
      context.read<GeofenceBloc>().add(LoadGeofenceForEdit(widget.geofenceId!));
    }
  }

  Future<void> _loadVehicles() async {
    final result = await sl<GetVehicles>()(const NoParams());
    if (!mounted) return;
    result.fold(
      (failure) => context.showErrorSnackBar(failure.message),
      (vehicles) => setState(
        () => _linkedVehicles = vehicles
            .where((vehicle) => vehicle.hasTracker)
            .toList(),
      ),
    );
    if (mounted) setState(() => _loadingVehicles = false);
  }

  void _populate(GeofenceEntity geofence) {
    if (_loaded) return;
    _loaded = true;
    _nameController.text = geofence.name;
    _radiusMeters = geofence.radiusMeters
        .clamp(
          AppConstants.minGeofenceRadiusMeters,
          AppConstants.maxGeofenceRadiusMeters,
        )
        .toDouble();
    _center = LatLng(geofence.latitude, geofence.longitude);
    _hasSelectedArea = true;
    _vehicleIds = geofence.vehicleIds.toSet();
    _triggerOnEnter = geofence.triggerOnEnter;
    _triggerOnExit = geofence.triggerOnExit;
    _isActive = geofence.isActive;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_vehicleIds.isEmpty) {
      context.showErrorSnackBar(context.l10n.selectLinkedVehicle);
      return;
    }
    if (!_triggerOnEnter && !_triggerOnExit) {
      context.showErrorSnackBar(context.l10n.enableGeofenceTrigger);
      return;
    }
    context.read<GeofenceBloc>().add(
      SubmitGeofence(
        id: widget.geofenceId,
        params: GeofenceParams(
          id: widget.geofenceId,
          name: _nameController.text.trim(),
          latitude: _center.latitude,
          longitude: _center.longitude,
          radiusMeters: _radiusMeters,
          vehicleIds: _vehicleIds.toList(),
          triggerOnEnter: _triggerOnEnter,
          triggerOnExit: _triggerOnExit,
          isActive: _isActive,
        ),
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    if (_isGettingCurrentLocation) return;

    setState(() => _isGettingCurrentLocation = true);
    try {
      final permissionHandler = sl<AppPermissionHandler>();
      var status = await permissionHandler.checkPermission(
        AppPermission.location,
      );
      if (!status.isGranted) {
        status = await permissionHandler.requestPermission(
          AppPermission.location,
        );
      }

      if (!status.isGranted) {
        if (mounted) {
          if (status.requiresSettings) {
            _showLocationPermissionDialog();
          } else {
            context.showErrorSnackBar(context.l10n.locationPermissionDenied);
          }
        }
        return;
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) _showEnableLocationServicesDialog();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final center = LatLng(position.latitude, position.longitude);
      setState(() {
        _center = center;
        _hasSelectedArea = true;
      });
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(center, 16),
      );
    } catch (error) {
      if (mounted) context.showErrorSnackBar(error.toString());
    } finally {
      if (mounted) setState(() => _isGettingCurrentLocation = false);
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.isEditing ? context.l10n.editGeofence : context.l10n.addGeofence,
      ),
    ),
    body: BlocConsumer<GeofenceBloc, GeofenceState>(
      listener: (context, state) {
        if (state.editingGeofence != null) {
          setState(() => _populate(state.editingGeofence!));
        }
        if (state.hasError && state.errorMessage != null) {
          context.showErrorSnackBar(state.errorMessage!);
        }
        if (state.isSuccess) {
          context.showSuccessSnackBar(
            widget.isEditing
                ? context.l10n.geofenceUpdated
                : context.l10n.geofenceCreated,
          );
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        if (state.isLoading && widget.isEditing && !_loaded) {
          return const Center(child: CircularProgressIndicator());
        }
        final mapHeight = (MediaQuery.sizeOf(context).height * .42)
            .clamp(280.0, 420.0)
            .toDouble();
        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: context.l10n.name),
                validator: Validators.validateGeofenceName,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: mapHeight,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _center,
                          zoom: 14,
                        ),
                        onMapCreated: (controller) =>
                            _mapController = controller,
                        gestureRecognizers: {
                          Factory<EagerGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                          ),
                        },
                        onTap: (center) => setState(() {
                          _center = center;
                          _hasSelectedArea = true;
                        }),
                        markers: {
                          Marker(
                            markerId: const MarkerId('geofence-center'),
                            position: _center,
                          ),
                        },
                        circles: {
                          Circle(
                            circleId: const CircleId('geofence-preview'),
                            center: _center,
                            radius: _radiusMeters,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .16),
                            strokeColor: Theme.of(context).colorScheme.primary,
                            strokeWidth: 2,
                          ),
                        },
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        color: Theme.of(context).colorScheme.surface,
                        elevation: 2,
                        borderRadius: BorderRadius.circular(8),
                        child: IconButton(
                          icon: _isGettingCurrentLocation
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location),
                          tooltip: context.l10n.myLocation,
                          onPressed: _isGettingCurrentLocation
                              ? null
                              : _goToCurrentLocation,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.l10n.radiusMeters),
                  Text('${_radiusMeters.toStringAsFixed(0)} m'),
                ],
              ),
              Slider(
                min: AppConstants.minGeofenceRadiusMeters,
                max: AppConstants.maxGeofenceRadiusMeters,
                divisions: 99,
                value: _radiusMeters,
                label: '${_radiusMeters.toStringAsFixed(0)} m',
                onChanged: (radius) => setState(() => _radiusMeters = radius),
              ),
              Text(context.l10n.tapMapToSetCenter),
              const SizedBox(height: 4),
              Text(
                context.l10n.trackerEvaluationDelay,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.vehicles,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_loadingVehicles)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_linkedVehicles.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(context.l10n.noLinkedVehicles),
                )
              else
                ..._linkedVehicles.map(
                  (vehicle) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        value: _vehicleIds.contains(vehicle.id),
                        secondary: _VehicleThumbnail(vehicle: vehicle),
                        title: Text(vehicle.name),
                        subtitle: Text(vehicle.plateNumber),
                        onChanged: (selected) => setState(
                          () => selected == true
                              ? _vehicleIds.add(vehicle.id)
                              : _vehicleIds.remove(vehicle.id),
                        ),
                      ),
                    ),
                  ),
                ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.triggerOnEnter),
                value: _triggerOnEnter,
                onChanged: (value) => setState(() => _triggerOnEnter = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.triggerOnExit),
                value: _triggerOnExit,
                onChanged: (value) => setState(() => _triggerOnExit = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.active),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed:
                    state.isSubmitting ||
                        _nameController.text.trim().isEmpty ||
                        !_hasSelectedArea
                    ? null
                    : _submit,
                child: state.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.isEditing
                            ? context.l10n.saveChanges
                            : context.l10n.createGeofence,
                      ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _VehicleThumbnail extends StatelessWidget {
  const _VehicleThumbnail({required this.vehicle});

  final VehicleEntity vehicle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 52,
        height: 52,
        child: vehicle.primaryImageUrl == null
            ? Container(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.directions_car_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : CachedNetworkImage(
                imageUrl: vehicle.primaryImageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.directions_car_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
      ),
    );
  }
}
