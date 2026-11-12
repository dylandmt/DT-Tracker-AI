import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/design/dt_components.dart';
import '../../../../core/design/dt_design_tokens.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/statistics.dart';
import '../bloc/statistics_bloc.dart';
import '../../../vehicles/presentation/cubit/selected_vehicle_cubit.dart';
import '../../../vehicles/domain/entities/vehicle.dart';

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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _requestStatistics(
        context.read<SelectedVehicleCubit>().state.selectedVehicle,
      ),
    );
  }

  void _requestStatistics(VehicleEntity? vehicle) {
    context.read<StatisticsBloc>().add(
      StatisticsRequested(
        vehicle: vehicle,
        from: context.read<StatisticsBloc>().state.from ?? _initialFrom,
        to: context.read<StatisticsBloc>().state.to ?? _initialTo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DTAppScaffold(
    useAmbientBackground: false,
    body: SafeArea(
      child: BlocListener<SelectedVehicleCubit, SelectedVehicleState>(
        listenWhen: (previous, current) =>
            previous.selectedVehicle?.id != current.selectedVehicle?.id,
        listener: (_, selection) =>
            _requestStatistics(selection.selectedVehicle),
        child: BlocBuilder<StatisticsBloc, StatisticsState>(
          builder: (context, state) {
            final selection = context.watch<SelectedVehicleCubit>().state;
            final vehicle = selection.selectedVehicle;
            return RefreshIndicator(
              onRefresh: () async => context.read<StatisticsBloc>().add(
                StatisticsRequested(
                  vehicle: vehicle,
                  from: state.from ?? _initialFrom,
                  to: state.to ?? _initialTo,
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  DTSpacing.md,
                  DTSpacing.md,
                  DTSpacing.md,
                  DTSpacing.xxl,
                ),
                children: [
                  _header(context),
                  const SizedBox(height: DTSpacing.lg),
                  if (vehicle != null) ...[
                    DTVehicleSelector(
                      label: vehicle.fullDescription ?? vehicle.name,
                      leading: const Icon(Icons.directions_car_outlined),
                      onTap: () => _showVehicleSelector(selection),
                    ),
                    const SizedBox(height: DTSpacing.sm),
                  ],
                  if (state.status == StatisticsStatus.loading)
                    const Padding(
                      padding: EdgeInsets.all(DTSpacing.xxxl),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.status == StatisticsStatus.error)
                    _message(
                      Icons.error_outline,
                      state.failure?.message ??
                          context.l10n.statisticsLoadError,
                      action: () => _requestStatistics(vehicle),
                    )
                  else if (state.status == StatisticsStatus.empty)
                    _message(
                      Icons.insights_outlined,
                      vehicle?.hasTracker == false
                          ? context.l10n.vehicleWithoutTrackerStatistics
                          : context.l10n.addVehicleForStatistics,
                    )
                  else if (state.statistics case final statistics?) ...[
                    DTSegmentedTabs(
                      labels: [context.l10n.day, context.l10n.week],
                      selectedIndex: 1,
                      onSelected: (index) {
                        if (index == 0) {
                          context.push(
                            RouteConstants.dailyStatistics,
                            extra: {'vehicle': vehicle, 'date': statistics.to},
                          );
                        }
                      },
                    ),
                    const SizedBox(height: DTSpacing.sm),
                    DTDateRangeSelector(
                      label: _rangeLabel(context, statistics),
                      onTap: () => _pickRange(statistics),
                    ),
                    const SizedBox(height: DTSpacing.lg),
                    _WeeklyDistanceChart(
                      days: statistics.days,
                      onTap: (day) => context.push(
                        RouteConstants.dailyStatistics,
                        extra: {'vehicle': vehicle, 'date': day.date},
                      ),
                    ),
                    const SizedBox(height: DTSpacing.md),
                    _totalDistance(context, statistics.summary),
                    const SizedBox(height: DTSpacing.sm),
                    _summaryGrid(context, statistics.summary),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _header(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back),
      ),
      Expanded(
        child: Text(
          context.l10n.statistics,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(width: 48),
    ],
  );

  Widget _totalDistance(BuildContext context, StatisticsSummary summary) =>
      DTGlassCard(
        child: Row(
          children: [
            Icon(
              Icons.route_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: DTSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.totalDistance,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${summary.distanceKm.toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _summaryGrid(BuildContext context, StatisticsSummary summary) =>
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: DTSpacing.xs,
        crossAxisSpacing: DTSpacing.xs,
        mainAxisExtent: _metricTileExtent(context),
        children: [
          DTMetricTile(
            icon: const Icon(Icons.route_outlined),
            value: '${summary.averageDailyDistanceKm.toStringAsFixed(1)} km',
            label: context.l10n.dailyAverage,
          ),
          DTMetricTile(
            icon: const Icon(Icons.speed_outlined),
            value: '${summary.averageSpeedKmh.toStringAsFixed(1)} km/h',
            label: context.l10n.averageSpeed,
          ),
          DTMetricTile(
            icon: const Icon(Icons.speed_outlined),
            value: '${summary.maxSpeedKmh.toStringAsFixed(0)} km/h',
            label: context.l10n.maximumSpeed,
            color: context.dtColors.cyan,
          ),
          DTMetricTile(
            icon: const Icon(Icons.schedule_outlined),
            value: '${summary.movingMinutes.toStringAsFixed(0)} min',
            label: context.l10n.movingTime,
            color: context.dtColors.online,
          ),
        ],
      );

  double _metricTileExtent(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return (116 + ((textScale - 1).clamp(0.0, .5) * 44)).toDouble();
  }

  Widget _message(IconData icon, String message, {VoidCallback? action}) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(DTSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: context.dtColors.muted),
              const SizedBox(height: DTSpacing.md),
              Text(message, textAlign: TextAlign.center),
              if (action != null)
                TextButton(onPressed: action, child: Text(context.l10n.retry)),
            ],
          ),
        ),
      );

  String _rangeLabel(BuildContext context, VehicleStatistics statistics) {
    final locale = Localizations.localeOf(context).toString();
    final format = DateFormat.MMMd(locale);
    return '${format.format(statistics.from.toLocal())} - ${format.format(statistics.to.toLocal())}';
  }

  Future<void> _showVehicleSelector(SelectedVehicleState state) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => DTVehicleBottomSheet(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: state.vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = state.vehicles[index];
            return ListTile(
              leading: const Icon(Icons.directions_car_outlined),
              title: Text(vehicle.fullDescription ?? vehicle.name),
              trailing: vehicle.id == state.selectedVehicle?.id
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(context, vehicle.id),
            );
          },
        ),
      ),
    );
    if (!mounted || selected == null || selected == state.selectedVehicle?.id) {
      return;
    }
    context.read<SelectedVehicleCubit>().selectVehicle(selected);
  }

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
    if (!mounted || picked == null) return;
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
}

class _WeeklyDistanceChart extends StatelessWidget {
  const _WeeklyDistanceChart({required this.days, required this.onTap});

  final List<DailyStatistics> days;
  final ValueChanged<DailyStatistics> onTap;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return DTGlassCard(
        child: SizedBox(
          height: 220,
          child: Center(child: Text(context.l10n.noData)),
        ),
      );
    }
    final max = days.fold<double>(
      1,
      (value, day) =>
          value > day.summary.distanceKm ? value : day.summary.distanceKm,
    );
    final locale = Localizations.localeOf(context).toString();
    return DTGlassCard(
      child: SizedBox(
        height: 246,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.kmDriven,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DTSpacing.sm),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: days
                    .map(
                      (day) => Expanded(
                        child: Semantics(
                          button: true,
                          label:
                              '${DateFormat.E(locale).format(day.date)} ${day.summary.distanceKm.toStringAsFixed(1)} km',
                          child: InkWell(
                            onTap: () => onTap(day),
                            borderRadius: const BorderRadius.all(DTRadius.sm),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: AnimatedContainer(
                                        duration:
                                            MediaQuery.of(
                                              context,
                                            ).disableAnimations
                                            ? Duration.zero
                                            : DTMotion.normal,
                                        height:
                                            154 * day.summary.distanceKm / max,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              context.dtColors.primaryBright,
                                            ],
                                          ),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: DTRadius.sm,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: DTSpacing.xs),
                                  Text(
                                    DateFormat.E(locale).format(day.date),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
