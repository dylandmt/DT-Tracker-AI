import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/design/dt_components.dart';
import '../../../../core/design/dt_design_tokens.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../injection_container.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../domain/entities/statistics.dart';
import '../../domain/usecases/statistics_usecases.dart';

class DailyStatisticsPage extends StatefulWidget {
  const DailyStatisticsPage({
    super.key,
    required this.vehicle,
    required this.date,
  });

  final VehicleEntity vehicle;
  final DateTime date;

  @override
  State<DailyStatisticsPage> createState() => _DailyStatisticsPageState();
}

class _DailyStatisticsPageState extends State<DailyStatisticsPage> {
  DailyStatistics? _statistics;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final result = await sl<GetDailyStatistics>()(
      DailyStatisticsParams(vehicleId: widget.vehicle.id, date: widget.date),
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() => _error = failure.message),
      (value) => setState(() => _statistics = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _statistics;
    return DTAppScaffold(
      useAmbientBackground: false,
      body: SafeArea(
        child: data == null
            ? _loadingOrError(context)
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  DTSpacing.md,
                  DTSpacing.md,
                  DTSpacing.md,
                  DTSpacing.xxl,
                ),
                children: [
                  _header(context),
                  const SizedBox(height: DTSpacing.lg),
                  DTVehicleSelector(
                    label:
                        widget.vehicle.fullDescription ?? widget.vehicle.name,
                    leading: const Icon(Icons.directions_car_outlined),
                    enabled: false,
                    onTap: null,
                  ),
                  const SizedBox(height: DTSpacing.sm),
                  DTSegmentedTabs(
                    labels: [context.l10n.day, context.l10n.week],
                    selectedIndex: 0,
                    onSelected: (index) {
                      if (index == 1) context.pop();
                    },
                  ),
                  const SizedBox(height: DTSpacing.sm),
                  DTDateRangeSelector(
                    label: DateFormat.yMMMMd(
                      Localizations.localeOf(context).toString(),
                    ).format(widget.date.toLocal()),
                    onTap: _pickDay,
                  ),
                  const SizedBox(height: DTSpacing.lg),
                  _summary(context, data.summary),
                  const SizedBox(height: DTSpacing.lg),
                  DTSpeedChart(samples: data.speedSeries),
                ],
              ),
      ),
    );
  }

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

  Widget _loadingOrError(BuildContext context) => Center(
    child: _error == null
        ? const CircularProgressIndicator()
        : Padding(
            padding: const EdgeInsets.all(DTSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 56,
                  color: context.dtColors.alert,
                ),
                const SizedBox(height: DTSpacing.md),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: DTSpacing.sm),
                TextButton(onPressed: _load, child: Text(context.l10n.retry)),
              ],
            ),
          ),
  );

  Widget _summary(BuildContext context, StatisticsSummary summary) =>
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
            value: '${summary.distanceKm.toStringAsFixed(1)} km',
            label: context.l10n.totalDistance,
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

  Future<void> _pickDay() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: widget.date.toLocal(),
      firstDate: DateTime.utc(2020),
      lastDate: DateTime.now(),
    );
    if (!mounted || selected == null) return;
    context.pushReplacement(
      RouteConstants.dailyStatistics,
      extra: {'vehicle': widget.vehicle, 'date': selected.toUtc()},
    );
  }
}

class DTSpeedChart extends StatefulWidget {
  const DTSpeedChart({super.key, required this.samples});

  final List<SpeedSample> samples;

  @override
  State<DTSpeedChart> createState() => _DTSpeedChartState();
}

class _DTSpeedChartState extends State<DTSpeedChart> {
  int? _selectedIndex;

  void _select(Offset position, double width) {
    if (widget.samples.isEmpty) return;
    final usableWidth =
        width - _SpeedPainter.leftInset - _SpeedPainter.rightInset;
    final fraction = ((position.dx - _SpeedPainter.leftInset) / usableWidth)
        .clamp(0.0, 1.0);
    final start = widget.samples.first.timestamp.millisecondsSinceEpoch;
    final end = widget.samples.last.timestamp.millisecondsSinceEpoch;
    final target = start + ((end - start) * fraction).round();
    var nearest = 0;
    var distance = double.infinity;
    for (var index = 0; index < widget.samples.length; index += 1) {
      final candidate =
          (widget.samples[index].timestamp.millisecondsSinceEpoch - target)
              .abs();
      if (candidate < distance) {
        nearest = index;
        distance = candidate.toDouble();
      }
    }
    setState(() => _selectedIndex = nearest);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.samples.isEmpty) {
      return DTGlassCard(
        child: SizedBox(
          height: 260,
          child: Center(child: Text(context.l10n.noSpeedRecords)),
        ),
      );
    }
    final selected = _selectedIndex == null
        ? null
        : widget.samples[_selectedIndex!];
    final axisMax = SpeedChartAxis.upperBound(
      widget.samples.fold<double>(
        0,
        (maximum, sample) =>
            maximum > sample.speedKmh ? maximum : sample.speedKmh,
      ),
    );
    return DTGlassCard(
      child: SizedBox(
        height: 288,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.speedDuringDay,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text('km/h', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: DTSpacing.xs),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) =>
                      _select(details.localPosition, constraints.maxWidth),
                  onHorizontalDragUpdate: (details) =>
                      _select(details.localPosition, constraints.maxWidth),
                  child: CustomPaint(
                    painter: _SpeedPainter(
                      samples: widget.samples,
                      lineColor: Theme.of(context).colorScheme.primary,
                      labelColor: context.dtColors.textSecondary,
                      axisMax: axisMax,
                      selectedIndex: _selectedIndex,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            if (selected != null)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${DateFormat.Hm().format(selected.timestamp.toLocal())}  ${selected.speedKmh.toStringAsFixed(0)} km/h',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SpeedChartAxis {
  const SpeedChartAxis._();

  static double upperBound(double maxSpeedKmh) {
    if (maxSpeedKmh <= 0) return 40;
    const steps = [20.0, 40.0, 80.0, 120.0, 160.0, 200.0, 240.0];
    return steps.firstWhere(
      (step) => step >= maxSpeedKmh,
      orElse: () => (maxSpeedKmh / 40).ceil() * 40,
    );
  }

  static const hours = [0, 6, 12, 18, 24];
}

class _SpeedPainter extends CustomPainter {
  const _SpeedPainter({
    required this.samples,
    required this.lineColor,
    required this.labelColor,
    required this.axisMax,
    required this.selectedIndex,
  });

  static const leftInset = 38.0;
  static const rightInset = 8.0;
  static const topInset = 8.0;
  static const bottomInset = 26.0;
  final List<SpeedSample> samples;
  final Color lineColor;
  final Color labelColor;
  final double axisMax;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTWH(
      leftInset,
      topInset,
      size.width - leftInset - rightInset,
      size.height - topInset - bottomInset,
    );
    final dayStart = DateTime.utc(
      samples.first.timestamp.year,
      samples.first.timestamp.month,
      samples.first.timestamp.day,
    ).millisecondsSinceEpoch;
    const dayLength = Duration.millisecondsPerDay;
    final gridPaint = Paint()
      ..color = labelColor.withValues(alpha: .18)
      ..strokeWidth = 1;
    final labelStyle = TextStyle(color: labelColor, fontSize: 11);
    for (var tick = 0; tick <= 4; tick += 1) {
      final y = plot.bottom - plot.height * tick / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      final text = TextPainter(
        text: TextSpan(
          text: (axisMax * tick / 4).round().toString(),
          style: labelStyle,
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        Offset(plot.left - text.width - 6, y - text.height / 2),
      );
    }
    for (final hour in SpeedChartAxis.hours) {
      final x = plot.left + plot.width * hour / 24;
      final text = TextPainter(
        text: TextSpan(
          text: '${hour.toString().padLeft(2, '0')}:00',
          style: labelStyle,
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        Offset(
          (x - text.width / 2).clamp(plot.left, plot.right - text.width),
          plot.bottom + 6,
        ),
      );
    }
    Offset point(SpeedSample sample) => Offset(
      plot.left +
          plot.width *
              ((sample.timestamp.millisecondsSinceEpoch - dayStart) / dayLength)
                  .clamp(0.0, 1.0),
      plot.bottom - plot.height * (sample.speedKmh / axisMax).clamp(0.0, 1.0),
    );
    final path = Path();
    for (var index = 0; index < samples.length; index += 1) {
      final offset = point(samples[index]);
      if (index == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    final area = Path.from(path)
      ..lineTo(plot.right, plot.bottom)
      ..lineTo(plot.left, plot.bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          colors: [
            lineColor.withValues(alpha: .32),
            lineColor.withValues(alpha: 0),
          ],
        ).createShader(plot),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    if (selectedIndex != null) {
      final selected = point(samples[selectedIndex!]);
      canvas.drawLine(
        Offset(selected.dx, plot.top),
        Offset(selected.dx, plot.bottom),
        Paint()..color = labelColor.withValues(alpha: .35),
      );
      canvas.drawCircle(selected, 5, Paint()..color = lineColor);
      canvas.drawCircle(selected, 2, Paint()..color = labelColor);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedPainter old) =>
      old.samples != samples ||
      old.selectedIndex != selectedIndex ||
      old.axisMax != axisMax ||
      old.lineColor != lineColor ||
      old.labelColor != labelColor;
}
