import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/utils/extensions.dart';
import '../bloc/vehicles_bloc.dart';
import '../widgets/delete_vehicle_dialog.dart';
import '../widgets/vehicle_card.dart';
import '../widgets/vehicles_empty_state.dart';

/// Page displaying a grid of user's vehicles
class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  @override
  void initState() {
    super.initState();
    // Start watching vehicles on page load
    context.read<VehiclesBloc>().add(const StartWatchingVehicles());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<VehiclesBloc>().add(const RefreshVehicles());
            },
          ),
        ],
      ),
      body: BlocConsumer<VehiclesBloc, VehiclesState>(
        listener: (context, state) {
          if (state.hasError && state.errorMessage != null) {
            context.showErrorSnackBar(state.errorMessage!);
            context.read<VehiclesBloc>().add(const ClearVehiclesError());
          }
          if (state.isDeleted) {
            context.showSuccessSnackBar('Vehicle deleted successfully');
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.vehicles.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.isEmpty) {
            return VehiclesEmptyState(
              onAddVehicle: () => context.push(RouteConstants.vehicleAdd),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<VehiclesBloc>().add(const RefreshVehicles());
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: state.vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = state.vehicles[index];
                return VehicleCard(
                  vehicle: vehicle,
                  onTap: () => context.push(
                    RouteConstants.vehicleDetail.replaceFirst(':id', vehicle.id),
                  ),
                  onLongPress: () => _showDeleteDialog(context, vehicle),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteConstants.vehicleAdd),
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, vehicle) async {
    final confirmed = await showDeleteVehicleDialog(context, vehicle);
    if (confirmed == true && mounted) {
      context.read<VehiclesBloc>().add(
            DeleteVehicleRequested(vehicleId: vehicle.id),
          );
    }
  }
}
