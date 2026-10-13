import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dt_components.dart';
import '../../../../core/design/dt_design_tokens.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vehicle_location.dart';

enum VehicleListFilter { all, online, moving, offline }

class VehicleListPanel extends StatefulWidget {
  const VehicleListPanel({
    super.key,
    required this.vehicles,
    required this.onVehicleSelected,
    this.selectedVehicle,
    this.onClose,
  });

  final List<VehicleLocationEntity> vehicles;
  final VehicleLocationEntity? selectedVehicle;
  final ValueChanged<VehicleLocationEntity> onVehicleSelected;
  final VoidCallback? onClose;

  @override
  State<VehicleListPanel> createState() => _VehicleListPanelState();
}

class _VehicleListPanelState extends State<VehicleListPanel> {
  VehicleListFilter _filter = VehicleListFilter.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visibleVehicles = widget.vehicles.where(_matches).toList();
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: width.clamp(280.0, 380.0),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.horizontal(right: DTRadius.xl),
        child: SafeArea(
          right: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DTSpacing.md,
                  DTSpacing.sm,
                  DTSpacing.sm,
                  DTSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: .14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_car_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: DTSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.vehicles,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            l10n.vehicleSummary(
                              widget.vehicles.length,
                              widget.vehicles.where((v) => v.isOnline).length,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (widget.onClose != null)
                      IconButton(
                        tooltip: l10n.dismiss,
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DTSpacing.md),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    hintText: l10n.search,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(height: DTSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: DTSpacing.md),
                child: Row(
                  children: VehicleListFilter.values
                      .map(
                        (filter) => Padding(
                          padding: const EdgeInsets.only(right: DTSpacing.xs),
                          child: FilterChip(
                            label: Text(_filterLabel(l10n, filter)),
                            selected: _filter == filter,
                            onSelected: (_) => setState(() => _filter = filter),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: DTSpacing.sm),
              Expanded(
                child: visibleVehicles.isEmpty
                    ? _emptyState(context)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          DTSpacing.md,
                          0,
                          DTSpacing.md,
                          DTSpacing.xl,
                        ),
                        itemCount: visibleVehicles.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: DTSpacing.xs),
                        itemBuilder: (context, index) {
                          final vehicle = visibleVehicles[index];
                          return DTVehicleTile(
                            title: vehicle.vehicleName,
                            subtitle: vehicle.plateNumber,
                            status: _designStatus(vehicle),
                            statusLabel: _statusLabel(l10n, vehicle),
                            leading: _vehicleImage(context, vehicle),
                            trailing: Text(
                              vehicle.speed.localizedSpeed(context),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            onTap: () => widget.onVehicleSelected(vehicle),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _matches(VehicleLocationEntity vehicle) {
    final query = _query.toLowerCase();
    final matchesQuery =
        query.isEmpty ||
        vehicle.vehicleName.toLowerCase().contains(query) ||
        vehicle.plateNumber.toLowerCase().contains(query);
    if (!matchesQuery) return false;
    return switch (_filter) {
      VehicleListFilter.all => true,
      VehicleListFilter.online => vehicle.isOnline,
      VehicleListFilter.moving => vehicle.isMoving,
      VehicleListFilter.offline => !vehicle.isOnline,
    };
  }

  String _filterLabel(AppLocalizations l10n, VehicleListFilter filter) =>
      switch (filter) {
        VehicleListFilter.all => l10n.all,
        VehicleListFilter.online => l10n.online,
        VehicleListFilter.moving => l10n.moving,
        VehicleListFilter.offline => l10n.offline,
      };

  String _statusLabel(AppLocalizations l10n, VehicleLocationEntity vehicle) =>
      switch (vehicle.status) {
        VehicleStatus.moving => l10n.moving,
        VehicleStatus.idle => l10n.idle,
        VehicleStatus.offline => l10n.offline,
      };

  DTVehicleStatus _designStatus(VehicleLocationEntity vehicle) =>
      switch (vehicle.status) {
        VehicleStatus.moving => DTVehicleStatus.moving,
        VehicleStatus.idle => DTVehicleStatus.idle,
        VehicleStatus.offline => DTVehicleStatus.offline,
      };

  Widget _emptyState(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(DTSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 48,
            color: context.dtColors.muted,
          ),
          const SizedBox(height: DTSpacing.sm),
          Text(
            AppLocalizations.of(context)!.noVehiclesWithTrackers,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _vehicleImage(BuildContext context, VehicleLocationEntity vehicle) =>
      Container(
        width: 52,
        height: 52,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.dtColors.surfaceRaised,
          borderRadius: const BorderRadius.all(DTRadius.md),
        ),
        child: vehicle.imageUrl == null
            ? const Icon(Icons.directions_car_outlined)
            : CachedNetworkImage(
                imageUrl: vehicle.imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) =>
                    const Icon(Icons.directions_car_outlined),
              ),
      );
}
