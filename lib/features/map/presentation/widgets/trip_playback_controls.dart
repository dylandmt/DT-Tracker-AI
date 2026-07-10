import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/entities/trip_point.dart';

class TripPlaybackControls extends StatelessWidget {
  final TripPointEntity currentPoint;
  final int position;
  final int pointCount;
  final bool isPlaying;
  final double speed;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final ValueChanged<int> onSeek;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onClose;

  const TripPlaybackControls({
    super.key,
    required this.currentPoint,
    required this.position,
    required this.pointCount,
    required this.isPlaying,
    required this.speed,
    required this.onPlayPause,
    required this.onStop,
    required this.onSeek,
    required this.onSpeedChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = pointCount < 2 ? 0.0 : position / (pointCount - 1);

    return Material(
      color: colorScheme.surface,
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.route_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentPoint.timestamp.formattedDateTime,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                PopupMenuButton<double>(
                  tooltip: 'Playback speed',
                  initialValue: speed,
                  onSelected: onSpeedChanged,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 1.0, child: Text('1x speed')),
                    PopupMenuItem(value: 2.0, child: Text('2x speed')),
                    PopupMenuItem(value: 4.0, child: Text('4x speed')),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('${speed.toStringAsFixed(0)}x'),
                  ),
                ),
                IconButton(
                  tooltip: 'Close replay',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: pointCount < 2
                  ? null
                  : (value) => onSeek((value * (pointCount - 1)).round()),
            ),
            Row(
              children: [
                IconButton.filled(
                  tooltip: isPlaying ? 'Pause replay' : 'Play replay',
                  onPressed: onPlayPause,
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                IconButton(
                  tooltip: 'Restart replay',
                  onPressed: onStop,
                  icon: const Icon(Icons.restart_alt),
                ),
                const SizedBox(width: 8),
                Text('$position / ${pointCount - 1}'),
                const Spacer(),
                Icon(Icons.speed, size: 18, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(currentPoint.speed.formatSpeed),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
