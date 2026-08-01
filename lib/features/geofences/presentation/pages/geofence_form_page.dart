import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_constants.dart';
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
  final _radiusController = TextEditingController(
    text: AppConstants.defaultGeofenceRadiusMeters.toStringAsFixed(0),
  );
  LatLng _center = _defaultCenter;
  List<VehicleEntity> _linkedVehicles = [];
  Set<String> _vehicleIds = {};
  bool _triggerOnEnter = true;
  bool _triggerOnExit = true;
  bool _isActive = true;
  bool _loaded = false;
  bool _loadingVehicles = true;

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
    _radiusController.text = geofence.radiusMeters.toStringAsFixed(0);
    _center = LatLng(geofence.latitude, geofence.longitude);
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
          radiusMeters: double.parse(_radiusController.text),
          vehicleIds: _vehicleIds.toList(),
          triggerOnEnter: _triggerOnEnter,
          triggerOnExit: _triggerOnExit,
          isActive: _isActive,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _radiusController.dispose();
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
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _radiusController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.l10n.radiusMeters,
                ),
                validator: Validators.validateGeofenceRadius,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: mapHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _center,
                      zoom: 14,
                    ),
                    gestureRecognizers: {
                      Factory<EagerGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                    onTap: (center) => setState(() => _center = center),
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
                        radius:
                            double.tryParse(_radiusController.text) ??
                            AppConstants.defaultGeofenceRadiusMeters,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: .16),
                        strokeColor: Theme.of(context).colorScheme.primary,
                        strokeWidth: 2,
                      ),
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
                  (vehicle) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _vehicleIds.contains(vehicle.id),
                    title: Text(vehicle.name),
                    subtitle: Text(vehicle.plateNumber),
                    onChanged: (selected) => setState(
                      () => selected == true
                          ? _vehicleIds.add(vehicle.id)
                          : _vehicleIds.remove(vehicle.id),
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
                onPressed: state.isSubmitting ? null : _submit,
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
