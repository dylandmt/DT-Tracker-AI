import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../domain/entities/trip.dart';
import '../bloc/trip_bloc.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});
  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  @override
  void initState() {
    super.initState();
    context.read<TripBloc>().add(const TripsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trips),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<TripBloc>().add(const TripsRequested()),
          ),
        ],
      ),
      body: BlocConsumer<TripBloc, TripState>(
        listener: (context, state) {
          if (state.failure != null) {
            context.showErrorSnackBar(state.failure!.message);
          }
        },
        builder: (context, state) {
          if (state.isLoading &&
              state.trips.isEmpty &&
              state.activeTrip == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<TripBloc>().add(const TripsRequested()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.activeTrip != null)
                  _ActiveTripCard(
                    trip: state.activeTrip!,
                    isEnding: state.isEnding,
                    onEnd: () => context.read<TripBloc>().add(
                      TripEnded(state.activeTrip!.tripId),
                    ),
                  )
                else
                  _StartTripCard(
                    vehicles: state.linkedVehicles,
                    isStarting: state.isStarting,
                    onStart: (vehicle) =>
                        context.read<TripBloc>().add(TripStarted(vehicle)),
                  ),
                const SizedBox(height: 24),
                Text(
                  l10n.tripHistory,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (state.trips.where((trip) => !trip.isActive).isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text(l10n.noTripsYet)),
                  )
                else
                  ...state.trips
                      .where((trip) => !trip.isActive)
                      .map(
                        (trip) => _TripTile(
                          trip: trip,
                          onTap: () => _showDetail(context, trip),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, TripEntity trip) {
    final tripBloc = context.read<TripBloc>();
    tripBloc.add(TripDetailRequested(trip.tripId));
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: tripBloc,
        child: BlocBuilder<TripBloc, TripState>(
          builder: (context, state) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child:
                state.isLoadingDetail &&
                    state.selectedTrip?.tripId != trip.tripId
                ? const Center(child: CircularProgressIndicator())
                : _TripDetails(
                    trip: state.selectedTrip?.tripId == trip.tripId
                        ? state.selectedTrip!
                        : trip,
                  ),
          ),
        ),
      ),
    );
  }
}

class _StartTripCard extends StatelessWidget {
  final List<VehicleEntity> vehicles;
  final bool isStarting;
  final ValueChanged<VehicleEntity> onStart;
  const _StartTripCard({
    required this.vehicles,
    required this.isStarting,
    required this.onStart,
  });
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.startTrip, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              vehicles.isEmpty
                  ? l10n.noVehiclesWithTrackers
                  : l10n.selectVehicleToStartTrip,
            ),
            const SizedBox(height: 16),
            if (vehicles.isNotEmpty)
              ...vehicles.map(
                (vehicle) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.directions_car),
                  title: Text(vehicle.name),
                  subtitle: Text(vehicle.plateNumber),
                  trailing: FilledButton(
                    onPressed: isStarting ? null : () => onStart(vehicle),
                    child: isStarting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.start),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  final TripEntity trip;
  final bool isEnding;
  final VoidCallback onEnd;
  const _ActiveTripCard({
    required this.trip,
    required this.isEnding,
    required this.onEnd,
  });
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.activeTrip,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('${l10n.tracker}: ${trip.trackerId}'),
            Text(DateFormat.yMMMd().add_jm().format(trip.startedAt.toLocal())),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isEnding ? null : onEnd,
              icon: const Icon(Icons.stop),
              label: isEnding
                  ? const CircularProgressIndicator()
                  : Text(l10n.endTrip),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  final TripEntity trip;
  final VoidCallback onTap;
  const _TripTile({required this.trip, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: const Icon(Icons.route),
      title: Text(DateFormat.yMMMd().add_jm().format(trip.startedAt.toLocal())),
      subtitle: Text(
        '${trip.distanceKm.toStringAsFixed(1)} km - ${_duration(trip.durationSeconds)}',
      ),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

class _TripDetails extends StatelessWidget {
  final TripEntity trip;
  const _TripDetails({required this.trip});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tripDetails,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        _Metric(
          label: l10n.distance,
          value: '${trip.distanceKm.toStringAsFixed(2)} km',
        ),
        _Metric(label: l10n.duration, value: _duration(trip.durationSeconds)),
        _Metric(
          label: l10n.maxSpeed,
          value: '${trip.maxSpeedKmh.toStringAsFixed(1)} km/h',
        ),
        _Metric(
          label: l10n.averageSpeed,
          value: '${trip.averageSpeedKmh.toStringAsFixed(1)} km/h',
        ),
        _Metric(label: l10n.points, value: '${trip.pointCount}'),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

String _duration(int seconds) =>
    '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${((seconds % 3600) ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
