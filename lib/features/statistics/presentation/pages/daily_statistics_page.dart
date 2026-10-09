import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../injection_container.dart';
import '../../../../core/utils/extensions.dart';
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
    final result = await sl<GetDailyStatistics>()(
      DailyStatisticsParams(vehicleId: widget.vehicle.id, date: widget.date),
    );
    if (!mounted) {
      return;
    }
    result.fold(
      (failure) => setState(() => _error = failure.message),
      (value) => setState(() => _statistics = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _statistics;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.statistics)),
      body: data == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        TextButton(
                          onPressed: _load,
                          child: Text(context.l10n.retry),
                        ),
                      ],
                    ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  DateFormat.yMMMMd().format(widget.date),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(widget.vehicle.fullDescription ?? widget.vehicle.name),
                const SizedBox(height: 24),
                _summary(data.summary),
                const SizedBox(height: 24),
                Text(
                  context.l10n.speedDuringDay,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _SpeedChart(samples: data.speedSeries),
              ],
            ),
    );
  }

  Widget _summary(StatisticsSummary summary) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      for (final item in [
        (
          context.l10n.totalDistance,
          '${summary.distanceKm.toStringAsFixed(1)} km',
        ),
        (
          context.l10n.averageSpeed,
          '${summary.averageSpeedKmh.toStringAsFixed(1)} km/h',
        ),
        (
          context.l10n.maximumSpeed,
          '${summary.maxSpeedKmh.toStringAsFixed(0)} km/h',
        ),
        (
          context.l10n.movingTime,
          '${summary.movingMinutes.toStringAsFixed(0)} min',
        ),
      ])
        SizedBox(
          width: (MediaQuery.sizeOf(context).width - 44) / 2,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Text(
                    item.$2,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(item.$1),
                ],
              ),
            ),
          ),
        ),
    ],
  );
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

class _SpeedChart extends StatefulWidget {
  const _SpeedChart({required this.samples});
  final List<SpeedSample> samples;

  @override
  State<_SpeedChart> createState() => _SpeedChartState();
}

class _SpeedChartState extends State<_SpeedChart> {
  int? _selectedIndex;

  void _select(Offset position, double width) {
    final usableWidth =
        width - _SpeedPainter.leftInset - _SpeedPainter.rightInset;
    final fraction = ((position.dx - _SpeedPainter.leftInset) / usableWidth)
        .clamp(0.0, 1.0);
    final start = widget.samples.first.timestamp.millisecondsSinceEpoch;
    final end = widget.samples.last.timestamp.millisecondsSinceEpoch;
    final target = start + ((end - start) * fraction).round();
    var nearest = 0;
    var nearestDistance = double.infinity;
    for (var index = 0; index < widget.samples.length; index += 1) {
      final distance =
          (widget.samples[index].timestamp.millisecondsSinceEpoch - target)
              .abs();
      if (distance < nearestDistance) {
        nearest = index;
        nearestDistance = distance.toDouble();
      }
    }
    setState(() => _selectedIndex = nearest);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.samples.isEmpty) {
      return SizedBox(
        height: 260,
        child: Center(child: Text(context.l10n.noSpeedRecords)),
      );
    }
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _selectedIndex == null
        ? null
        : widget.samples[_selectedIndex!];
    final axisMax = SpeedChartAxis.upperBound(
      widget.samples.fold<double>(
        0,
        (max, sample) => sample.speedKmh > max ? sample.speedKmh : max,
      ),
    );
    return Container(
      height: 288,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.speedDuringDay,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onInverseSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'km/h',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onInverseSurface.withValues(alpha: .7),
            ),
          ),
          const SizedBox(height: 8),
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
                    lineColor: colorScheme.primary,
                    labelColor: colorScheme.onInverseSurface,
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
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onInverseSurface,
                ),
              ),
            ),
        ],
      ),
    );
  }
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
      ..color = labelColor.withValues(alpha: .16)
      ..strokeWidth = 1;
    final labelStyle = TextStyle(
      color: labelColor.withValues(alpha: .82),
      fontSize: 11,
    );
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
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), gridPaint);
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
    for (var i = 0; i < samples.length; i++) {
      final offset = point(samples[i]);
      if (i == 0) {
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
            lineColor.withValues(alpha: .34),
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
