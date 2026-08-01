import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/geofence.dart';
import '../bloc/geofence_bloc.dart';

class GeofencesPage extends StatefulWidget {
  const GeofencesPage({super.key});
  @override
  State<GeofencesPage> createState() => _GeofencesPageState();
}

class _GeofencesPageState extends State<GeofencesPage> {
  @override
  void initState() {
    super.initState();
    context.read<GeofenceBloc>().add(const WatchGeofencesRequested());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.geofences)),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => context.push(RouteConstants.geofenceAdd),
      icon: const Icon(Icons.add),
      label: Text(context.l10n.addGeofence),
    ),
    body: BlocConsumer<GeofenceBloc, GeofenceState>(
      listener: (context, state) {
        if (state.hasError && state.errorMessage != null) {
          context.showErrorSnackBar(state.errorMessage!);
          context.read<GeofenceBloc>().add(const ClearGeofenceError());
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.geofences.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.geofences.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fence_outlined, size: 64),
                  SizedBox(height: 16),
                  Text(context.l10n.noGeofencesYet),
                  SizedBox(height: 8),
                  Text(
                    context.l10n.createZoneToMonitor,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              context.read<GeofenceBloc>().add(const LoadGeofences()),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.geofences.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _GeofenceTile(
              geofence: state.geofences[index],
              onEdit: () =>
                  context.push('/geofences/${state.geofences[index].id}/edit'),
              onDelete: () => _confirmDelete(state.geofences[index]),
            ),
          ),
        );
      },
    ),
  );

  Future<void> _confirmDelete(GeofenceEntity geofence) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteGeofence),
        content: Text(context.l10n.deleteNamedGeofence(geofence.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (remove == true && mounted)
      context.read<GeofenceBloc>().add(DeleteGeofenceRequested(geofence.id));
  }
}

class _GeofenceTile extends StatelessWidget {
  final GeofenceEntity geofence;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _GeofenceTile({
    required this.geofence,
    required this.onEdit,
    required this.onDelete,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onEdit,
      leading: Icon(geofence.isActive ? Icons.fence : Icons.fence_outlined),
      title: Text(geofence.name),
      subtitle: Text(
        context.l10n.geofenceVehicleSummary(
          geofence.radiusMeters.toStringAsFixed(0),
          geofence.vehicleIds.length,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: geofence.isActive, onChanged: null),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    ),
  );
}
