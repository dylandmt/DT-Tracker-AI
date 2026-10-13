import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/design/dt_components.dart';
import '../../../../core/design/dt_design_tokens.dart';
import '../../../../core/design/dt_vehicle_marker.dart';
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
  BitmapDescriptor? _vehicleMarker;
  Brightness? _markerBrightness;
  double? _markerPixelRatio;
  bool _loading = true;
  MapType _mapType = MapType.normal;

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
        _selected ??= vehicles.isEmpty ? null : vehicles.first;
        if (_selected != null && !vehicles.any((v) => v.id == _selected!.id)) {
          _selected = vehicles.isEmpty ? null : vehicles.first;
        }
        _loading = false;
      });
      await _loadLocation();
    });
  }

  Future<void> _loadLocation() async {
    final vehicle = _selected;
    if (vehicle?.hasTracker != true) {
      if (mounted) setState(() => _location = null);
      return;
    }
    final colorScheme = Theme.of(context).colorScheme;
    final markerSurface = context.dtColors.surfaceOverlay;
    final markerBrightness = Theme.of(context).brightness;
    final markerPixelRatio = MediaQuery.devicePixelRatioOf(context);
    final result = await sl<GetVehicleLocation>()(IdParams(id: vehicle!.id));
    if (!mounted) return;
    result.fold((_) => setState(() => _location = null), (value) async {
      final needsMarker =
          _vehicleMarker == null ||
          _markerBrightness != markerBrightness ||
          _markerPixelRatio != markerPixelRatio;
      final marker = needsMarker
          ? await DTVehicleMarker.create(
              accent: colorScheme.primary,
              surface: markerSurface,
              onPrimary: colorScheme.onPrimary,
              devicePixelRatio: markerPixelRatio,
            )
          : _vehicleMarker;
      if (mounted) {
        setState(() {
          _location = value;
          _vehicleMarker = marker;
          _markerBrightness = markerBrightness;
          _markerPixelRatio = markerPixelRatio;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DTAppScaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadVehicles,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              DTSpacing.md,
              DTSpacing.sm,
              DTSpacing.md,
              DTSpacing.xxl,
            ),
            children: [
              _header(context),
              const SizedBox(height: DTSpacing.sm),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(DTSpacing.xxxl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_selected == null)
                _emptyState(context)
              else ...[
                DTVehicleSelector(
                  label: _selected!.name,
                  leading: const Icon(Icons.directions_car_outlined),
                  onTap: _showVehicleSelector,
                ),
                const SizedBox(height: DTSpacing.sm),
                _locationPreview(context),
                const SizedBox(height: DTSpacing.sm),
                _metrics(context),
                const SizedBox(height: DTSpacing.lg),
                Text(
                  context.l10n.quickActions,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: DTSpacing.xs),
                _quickActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    builder: (_, state) {
      final user = state.user;
      final name =
          user?.firstName ?? user?.displayName ?? context.l10n.guestUser;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                isDark
                    ? 'assets/images/dt_tracker_logo_dark.png'
                    : 'assets/images/dt_tracker_logo_light.png',
                height: 30,
                fit: BoxFit.contain,
                semanticLabel: context.l10n.appTitle,
              ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: context.l10n.alerts,
                onPressed: () => context.push(RouteConstants.alerts),
                icon: const Icon(Icons.notifications_none_outlined),
              ),
              const SizedBox(width: DTSpacing.xs),
              _profileAvatar(context, user?.photoUrl),
            ],
          ),
          const SizedBox(height: DTSpacing.xs),
          Text(
            context.l10n.homeGreeting(name),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: DTSpacing.xxs),
          Text(
            context.l10n.homeTagline,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.dtColors.textSecondary,
            ),
          ),
        ],
      );
    },
  );

  Widget _profileAvatar(BuildContext context, String? photoUrl) => CircleAvatar(
    radius: 21,
    backgroundColor: context.dtColors.surfaceRaised,
    foregroundImage: photoUrl == null
        ? null
        : CachedNetworkImageProvider(photoUrl),
    child: photoUrl == null ? const Icon(Icons.person_outline) : null,
  );

  Widget _emptyState(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(DTSpacing.xxxl),
      child: Column(
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 56,
            color: context.dtColors.muted,
          ),
          const SizedBox(height: DTSpacing.sm),
          Text(context.l10n.addFirstVehicle),
          const SizedBox(height: DTSpacing.sm),
          FilledButton(
            onPressed: () => context.push(RouteConstants.vehicleAdd),
            child: Text(context.l10n.addVehicle),
          ),
        ],
      ),
    ),
  );

  Widget _locationPreview(BuildContext context) {
    final location = _location;
    if (location == null) {
      return DTGlassCard(
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 196,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_off_outlined,
                  color: context.dtColors.muted,
                ),
                const SizedBox(height: DTSpacing.xs),
                Text(
                  context.l10n.noData,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }
    final position = LatLng(location.latitude, location.longitude);
    return ClipRRect(
      borderRadius: const BorderRadius.all(DTRadius.lg),
      child: SizedBox(
        height: 196,
        child: Stack(
          children: [
            GoogleMap(
              key: ValueKey(_selected!.id),
              initialCameraPosition: CameraPosition(target: position, zoom: 15),
              markers: {
                Marker(
                  markerId: MarkerId(_selected!.id),
                  position: position,
                  icon:
                      _vehicleMarker ??
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ),
                  anchor: const Offset(.5, .5),
                ),
              },
              mapType: _mapType,
              style: Theme.of(context).brightness == Brightness.dark
                  ? _darkMapStyle
                  : null,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),
            Positioned(
              top: DTSpacing.sm,
              left: DTSpacing.sm,
              child: DTStatusPill(
                status: location.isOnline
                    ? DTVehicleStatus.online
                    : DTVehicleStatus.offline,
                label: location.isOnline
                    ? context.l10n.online
                    : context.l10n.offline,
              ),
            ),
            Positioned(
              top: DTSpacing.sm,
              right: DTSpacing.sm,
              child: Column(
                children: [
                  DTMapActionButton(
                    icon: const Icon(Icons.layers_outlined, size: 18),
                    tooltip: context.l10n.mapType,
                    size: 44,
                    selected: _mapType == MapType.satellite,
                    onPressed: () => setState(() {
                      _mapType = _mapType == MapType.normal
                          ? MapType.satellite
                          : MapType.normal;
                    }),
                  ),
                  const SizedBox(height: DTSpacing.xxs),
                  DTMapActionButton(
                    icon: const Icon(Icons.navigation_outlined, size: 18),
                    tooltip: context.l10n.navigate,
                    size: 44,
                    onPressed: () => context.go(RouteConstants.homeMap),
                  ),
                  const SizedBox(height: DTSpacing.xxs),
                  DTMapActionButton(
                    icon: const Icon(Icons.fullscreen, size: 18),
                    tooltip: context.l10n.realTime,
                    size: 44,
                    onPressed: () => context.go(RouteConstants.homeMap),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metrics(BuildContext context) => Row(
    children: [
      Expanded(
        child: DTMetricTile(
          icon: const Icon(Icons.schedule_outlined),
          value:
              _location?.lastUpdate.localizedTimeAgo(context) ??
              context.l10n.noData,
          label: context.l10n.updated,
          compact: true,
        ),
      ),
      const SizedBox(width: DTSpacing.xs),
      Expanded(
        child: DTMetricTile(
          icon: const Icon(Icons.speed_outlined),
          value: _location?.formattedSpeed ?? '-',
          label: context.l10n.speed,
          compact: true,
        ),
      ),
      const SizedBox(width: DTSpacing.xs),
      Expanded(
        child: DTMetricTile(
          icon: const Icon(Icons.battery_full_outlined),
          value: _location == null ? '-' : '${_location!.battery}%',
          label: context.l10n.battery,
          color: _location?.isBatteryLow == true
              ? context.dtColors.alert
              : context.dtColors.online,
          compact: true,
        ),
      ),
    ],
  );

  Widget _quickActions(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: DTSpacing.xs,
    crossAxisSpacing: DTSpacing.xs,
    childAspectRatio: 2.05,
    children: [
      DTActionTile(
        icon: const Icon(Icons.gps_fixed),
        label: context.l10n.realTime,
        subtitle: context.l10n.liveLocation,
        color: Theme.of(context).colorScheme.primary,
        compact: true,
        showTrailing: false,
        onTap: () => context.go(RouteConstants.homeMap),
      ),
      DTActionTile(
        icon: const Icon(Icons.fence),
        label: context.l10n.geofences,
        subtitle: context.l10n.zonesAndAlerts,
        color: context.dtColors.purple,
        compact: true,
        showTrailing: false,
        onTap: () => context.push(RouteConstants.geofences),
      ),
      DTActionTile(
        icon: const Icon(Icons.notifications_active_outlined),
        label: context.l10n.alerts,
        subtitle: context.l10n.recentEvents,
        color: context.dtColors.idle,
        compact: true,
        showTrailing: false,
        onTap: () => context.push(RouteConstants.alerts),
      ),
      DTActionTile(
        icon: const Icon(Icons.bar_chart_outlined),
        label: context.l10n.statistics,
        subtitle: context.l10n.usageAndReports,
        color: context.dtColors.online,
        compact: true,
        showTrailing: false,
        onTap: () => context.push(RouteConstants.statistics),
      ),
    ],
  );

  Future<void> _showVehicleSelector() async {
    final selected = await showModalBottomSheet<VehicleEntity>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            DTSpacing.md,
            0,
            DTSpacing.md,
            DTSpacing.xl,
          ),
          itemCount: _vehicles.length,
          separatorBuilder: (_, _) => const SizedBox(height: DTSpacing.xs),
          itemBuilder: (context, index) {
            final vehicle = _vehicles[index];
            return ListTile(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(DTRadius.md),
              ),
              tileColor: vehicle.id == _selected?.id
                  ? context.dtColors.surfaceRaised
                  : null,
              leading: const Icon(Icons.directions_car_outlined),
              title: Text(vehicle.name),
              subtitle: Text(vehicle.fullDescription ?? ''),
              trailing: vehicle.id == _selected?.id
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(context, vehicle),
            );
          },
        ),
      ),
    );
    if (selected == null || selected.id == _selected?.id || !mounted) return;
    setState(() {
      _selected = selected;
      _location = null;
      _vehicleMarker = null;
      _markerBrightness = null;
      _markerPixelRatio = null;
    });
    await _loadLocation();
  }
}

const _darkMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#0B1629"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#A5B6D2"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0B1629"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#253D5D"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#081326"}]}
]''';
