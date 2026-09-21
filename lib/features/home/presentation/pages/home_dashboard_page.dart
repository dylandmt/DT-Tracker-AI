import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../map/domain/entities/vehicle_location.dart';
import '../../../map/domain/usecases/get_vehicle_location.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/domain/usecases/get_vehicles.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  List<VehicleEntity> _vehicles = const [];
  VehicleEntity? _selected;
  VehicleLocationEntity? _location;
  VehiclePlan? _expandedPlan;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final result = await sl<GetVehicles>()(const NoParams());
    if (!mounted) return;
    result.fold((_) => setState(() => _loading = false), (vehicles) async {
      setState(() {
        _vehicles = vehicles;
        _selected = vehicles.isEmpty ? null : vehicles.first;
        _loading = false;
      });
      await _loadLocation();
    });
  }

  Future<void> _loadLocation() async {
    final vehicle = _selected;
    if (vehicle?.hasTracker != true) {
      if (mounted) {
        setState(() => _location = null);
      }
      return;
    }
    final result = await sl<GetVehicleLocation>()(IdParams(id: vehicle!.id));
    if (mounted) {
      result.fold(
        (_) => setState(() => _location = null),
        (value) => setState(() => _location = value),
      );
    }
  }

  bool get _canShare => _vehicles.any(
    (vehicle) =>
        vehicle.plan == VehiclePlan.protect ||
        vehicle.plan == VehiclePlan.total,
  );

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadVehicles,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              BlocBuilder<AuthBloc, AuthState>(
                builder: (_, state) => Text(
                  'Hola, ${state.user?.firstName ?? state.user?.displayName ?? 'usuario'}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tu mundo, mas seguro',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (selected == null)
                _emptyState(context)
              else ...[
                _vehicleMap(context, selected),
                const SizedBox(height: 16),
                _metrics(context),
                const SizedBox(height: 24),
                Text(
                  'Acciones rapidas',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _action(
                      context,
                      Icons.gps_fixed,
                      'En tiempo real',
                      () => context.go(RouteConstants.homeMap),
                    ),
                    _action(
                      context,
                      Icons.fence,
                      'Geocercas',
                      () => context.push(RouteConstants.geofences),
                    ),
                    _action(
                      context,
                      Icons.notifications_active,
                      'Alertas',
                      () => context.push(RouteConstants.alerts),
                    ),
                    if (_canShare)
                      _action(
                        context,
                        Icons.people,
                        'Amigos',
                        () => context.go(RouteConstants.homeFriends),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Planes DT Tracker',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Elige la proteccion que necesita cada automovil.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _plan(
                  context,
                  VehiclePlan.essential,
                  'Essential',
                  'Ubicacion en tiempo real, 7 dias de historial y 2 geocercas.',
                ),
                _plan(
                  context,
                  VehiclePlan.protect,
                  'Protect',
                  'Todo Essential, 30 dias, compartir ubicacion e inmovilizacion remota.',
                ),
                _plan(
                  context,
                  VehiclePlan.total,
                  'Total',
                  'Todo Protect, 12 meses, geocercas ilimitadas y proteccion avanzada.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Icon(Icons.directions_car_outlined, size: 56),
          const SizedBox(height: 12),
          const Text('Agrega un automovil para comenzar.'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.push(RouteConstants.vehicleAdd),
            child: const Text('Agregar automovil'),
          ),
        ],
      ),
    ),
  );

  Widget _vehicleMap(BuildContext context, VehicleEntity vehicle) {
    final location = _location;
    final position = location == null
        ? const LatLng(19.4326, -99.1332)
        : LatLng(location.latitude, location.longitude);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 250,
        child: Stack(
          children: [
            GoogleMap(
              key: ValueKey('${vehicle.id}-${location?.lastUpdate}'),
              initialCameraPosition: CameraPosition(
                target: position,
                zoom: location == null ? 10 : 15,
              ),
              markers: location == null
                  ? const {}
                  : {
                      Marker(
                        markerId: MarkerId(vehicle.id),
                        position: position,
                      ),
                    },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: vehicle.id,
                      items: _vehicles
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (id) async {
                        setState(() {
                          _selected = _vehicles.firstWhere(
                            (item) => item.id == id,
                          );
                          _location = null;
                        });
                        await _loadLocation();
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Chip(
                avatar: Icon(
                  location?.isOnline == true
                      ? Icons.circle
                      : Icons.circle_outlined,
                  color: location?.isOnline == true ? Colors.green : null,
                  size: 14,
                ),
                label: Text(
                  location?.isOnline == true ? 'En linea' : 'Sin conexion',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metrics(BuildContext context) => Row(
    children: [
      _metric(
        context,
        Icons.schedule,
        _location?.lastUpdate.localizedTimeAgo(context) ?? 'Sin datos',
        'Actualizado',
      ),
      _metric(
        context,
        Icons.speed,
        _location == null ? '-' : _location!.formattedSpeed,
        'Velocidad',
      ),
      _metric(
        context,
        Icons.battery_full,
        _location == null ? '-' : '${_location!.battery}%',
        'Bateria',
      ),
    ],
  );

  Widget _metric(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );

  Widget _action(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) => SizedBox(
    width: (MediaQuery.sizeOf(context).width - 42) / 2,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _plan(
    BuildContext context,
    VehiclePlan plan,
    String title,
    String description,
  ) {
    final expanded = _expandedPlan == plan;
    final isCurrentPlan = _selected?.plan == plan;
    final icon = plan == VehiclePlan.essential
        ? Icons.location_on
        : plan == VehiclePlan.protect
        ? Icons.shield
        : Icons.workspace_premium;
    final details = switch (plan) {
      VehiclePlan.essential => const [
        'Ubicacion GPS en tiempo real',
        'Estado del vehiculo y del tracker',
        '7 dias de historial y 2 geocercas',
      ],
      VehiclePlan.protect => const [
        'Todo lo incluido en Essential',
        '30 dias de historial y 10 geocercas',
        'Compartir ubicacion e inmovilizacion remota',
      ],
      VehiclePlan.total => const [
        'Todo lo incluido en Protect',
        '12 meses de historial y geocercas ilimitadas',
        'Modo robo, seguimiento intensivo y usuarios autorizados',
      ],
    };

    return Card(
      color: isCurrentPlan
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        onTap: () => setState(() {
          _expandedPlan = expanded ? null : plan;
        }),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isCurrentPlan) const Icon(Icons.check_circle),
                  const SizedBox(width: 4),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
              const SizedBox(height: 8),
              Text(description),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 180),
                crossFadeState: expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: details
                        .map(
                          (detail) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(detail)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
