import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/statistics.dart';
import '../bloc/statistics_bloc.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late final DateTime _initialTo = DateUtils.dateOnly(DateTime.now().toUtc());
  late final DateTime _initialFrom = _initialTo.subtract(
    const Duration(days: 6),
  );
  @override
  void initState() {
    super.initState();
    context.read<StatisticsBloc>().add(
      StatisticsRequested(from: _initialFrom, to: _initialTo),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.statistics)),
    body: BlocBuilder<StatisticsBloc, StatisticsState>(
      builder: (context, state) {
        if (state.status == StatisticsStatus.loading &&
            state.statistics == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == StatisticsStatus.error) {
          return _message(
            Icons.error_outline,
            state.failure?.message ?? context.l10n.statisticsLoadError,
            action: () => context.read<StatisticsBloc>().add(
              StatisticsRequested(
                from: state.from ?? _initialFrom,
                to: state.to ?? _initialTo,
              ),
            ),
          );
        }
        if (state.status == StatisticsStatus.empty) {
          return _message(
            Icons.insights_outlined,
            state.selectedVehicle?.hasTracker == false
                ? context.l10n.vehicleWithoutTrackerStatistics
                : context.l10n.addVehicleForStatistics,
          );
        }
        final statistics = state.statistics;
        if (statistics == null || state.selectedVehicle == null) {
          return const SizedBox.shrink();
        }
        return RefreshIndicator(
          onRefresh: () async => context.read<StatisticsBloc>().add(
            StatisticsRangeChanged(from: statistics.from, to: statistics.to),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: state.selectedVehicle!.id,
                decoration: InputDecoration(labelText: context.l10n.vehicle),
                items: state.vehicles
                    .map(
                      (vehicle) => DropdownMenuItem(
                        value: vehicle.id,
                        child: Text(vehicle.fullDescription ?? vehicle.name),
                      ),
                    )
                    .toList(),
                onChanged: state.status == StatisticsStatus.loading
                    ? null
                    : (id) {
                        if (id != null) {
                          context.read<StatisticsBloc>().add(
                            StatisticsVehicleChanged(id),
                          );
                        }
                      },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: state.status == StatisticsStatus.loading
                    ? null
                    : () => _pickRange(statistics),
                icon: const Icon(Icons.date_range),
                label: Text(
                  '${DateFormat.MMMd().format(statistics.from)} - ${DateFormat.MMMd().format(statistics.to)}',
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.kmDriven,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              _BarChart(
                days: statistics.days,
                onTap: (day) => context.push(
                  RouteConstants.dailyStatistics,
                  extra: {'vehicle': state.selectedVehicle!, 'date': day.date},
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '${statistics.summary.distanceKm.toStringAsFixed(1)} km',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Center(
                child: Text(
                  context.l10n.totalDistance,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.8,
                children: [
                  _metric(
                    context.l10n.dailyAverage,
                    '${statistics.summary.averageDailyDistanceKm.toStringAsFixed(1)} km',
                  ),
                  _metric(
                    context.l10n.averageSpeed,
                    '${statistics.summary.averageSpeedKmh.toStringAsFixed(1)} km/h',
                  ),
                  _metric(
                    context.l10n.maximumSpeed,
                    '${statistics.summary.maxSpeedKmh.toStringAsFixed(0)} km/h',
                  ),
                  _metric(
                    context.l10n.movingTime,
                    '${statistics.summary.movingMinutes.toStringAsFixed(0)} min',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
  Widget _message(IconData icon, String message, {VoidCallback? action}) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              if (action != null)
                TextButton(onPressed: action, child: Text(context.l10n.retry)),
            ],
          ),
        ),
      );
  Future<void> _pickRange(VehicleStatistics statistics) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.utc(2020),
      lastDate: DateTime.now().toUtc(),
      initialDateRange: DateTimeRange(
        start: statistics.from,
        end: statistics.to,
      ),
      helpText: context.l10n.selectUpToSevenDays,
    );
    if (!mounted || picked == null) {
      return;
    }
    if (picked.duration.inDays > 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.statisticsRangeMaximum)),
      );
      return;
    }
    context.read<StatisticsBloc>().add(
      StatisticsRangeChanged(
        from: picked.start.toUtc(),
        to: picked.end.toUtc(),
      ),
    );
  }

  Widget _metric(String label, String value) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.days, required this.onTap});
  final List<DailyStatistics> days;
  final ValueChanged<DailyStatistics> onTap;

  @override
  Widget build(BuildContext context) {
    final max = days.fold<double>(
      1,
      (value, day) =>
          day.summary.distanceKm > value ? day.summary.distanceKm : value,
    );
    return SizedBox(
      height: 210,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days
            .map(
              (day) => Expanded(
                child: InkWell(
                  onTap: () => onTap(day),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 160 * day.summary.distanceKm / max,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat.E().format(day.date),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
