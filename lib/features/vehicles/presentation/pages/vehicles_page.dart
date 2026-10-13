import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/design/dt_components.dart';
import '../../../../core/design/dt_design_tokens.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/image_cache.dart';
import '../../domain/entities/vehicle.dart';
import '../bloc/vehicles_bloc.dart';
import '../widgets/delete_vehicle_dialog.dart';
import '../widgets/vehicle_card.dart';
import '../widgets/vehicles_empty_state.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<VehiclesBloc>().add(const StartWatchingVehicles());
  }

  @override
  Widget build(BuildContext context) => DTAppScaffold(
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => context.push(RouteConstants.vehicleAdd),
      icon: const Icon(Icons.add),
      label: Text(context.l10n.addVehicle),
    ),
    body: SafeArea(
      child: BlocConsumer<VehiclesBloc, VehiclesState>(
        listener: (context, state) {
          if (state.hasError && state.errorMessage != null) {
            context.showErrorSnackBar(state.errorMessage!);
            context.read<VehiclesBloc>().add(const ClearVehiclesError());
          }
          if (state.isDeleted) {
            context.showSuccessSnackBar(context.l10n.vehicleDeleted);
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.vehicles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.isEmpty) {
            return VehiclesEmptyState(
              onAddVehicle: () => context.push(RouteConstants.vehicleAdd),
            );
          }
          final vehicles = state.vehicles.where(_matchesQuery).toList();
          return RefreshIndicator(
            onRefresh: () => _refresh(state),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                DTSpacing.md,
                DTSpacing.sm,
                DTSpacing.md,
                96,
              ),
              itemCount: vehicles.length + 1,
              separatorBuilder: (_, index) =>
                  SizedBox(height: index == 0 ? DTSpacing.md : DTSpacing.xs),
              itemBuilder: (context, index) {
                if (index == 0) return _header(context, state.vehicles.length);
                final vehicle = vehicles[index - 1];
                return VehicleCard(
                  vehicle: vehicle,
                  onTap: () => context.push(
                    RouteConstants.vehicleDetail.replaceFirst(
                      ':id',
                      vehicle.id,
                    ),
                  ),
                  onLongPress: () => _showDeleteDialog(context, vehicle),
                );
              },
            ),
          );
        },
      ),
    ),
  );

  Widget _header(BuildContext context, int vehicleCount) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.myVehicles,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: DTSpacing.xxs),
                Text(
                  context.l10n.myVehiclesSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.dtColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          DTMapActionButton(
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: context.l10n.refresh,
            size: 44,
            onPressed: () =>
                context.read<VehiclesBloc>().add(const RefreshVehicles()),
          ),
        ],
      ),
      const SizedBox(height: DTSpacing.md),
      TextField(
        onChanged: (value) => setState(() => _query = value.trim()),
        decoration: InputDecoration(
          hintText: context.l10n.searchVehicles,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: context.l10n.dismiss,
                  onPressed: () => setState(() => _query = ''),
                  icon: const Icon(Icons.close),
                ),
        ),
      ),
      const SizedBox(height: DTSpacing.sm),
      Text(
        '$vehicleCount ${context.l10n.vehicles}',
        style: Theme.of(context).textTheme.labelMedium,
      ),
    ],
  );

  bool _matchesQuery(VehicleEntity vehicle) {
    if (_query.isEmpty) return true;
    final query = _query.toLowerCase();
    return vehicle.name.toLowerCase().contains(query) ||
        vehicle.plateNumber.toLowerCase().contains(query) ||
        (vehicle.fullDescription?.toLowerCase().contains(query) ?? false);
  }

  Future<void> _refresh(VehiclesState state) async {
    await refreshCachedImages(
      state.vehicles.expand((vehicle) => vehicle.imageUrls),
    );
    if (!mounted) return;
    context.read<VehiclesBloc>().add(const RefreshVehicles());
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    VehicleEntity vehicle,
  ) async {
    final confirmed = await showDeleteVehicleDialog(context, vehicle);
    if (confirmed == true && context.mounted) {
      context.read<VehiclesBloc>().add(
        DeleteVehicleRequested(vehicleId: vehicle.id),
      );
    }
  }
}
