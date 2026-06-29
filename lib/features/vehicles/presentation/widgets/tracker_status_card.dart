import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/tracker_info.dart';
import '../../domain/entities/vehicle.dart';

/// Card widget for displaying tracker status and link/unlink actions
class TrackerStatusCard extends StatelessWidget {
  final VehicleEntity vehicle;
  final TrackerStatusEntity? trackerStatus;
  final bool isLoading;
  final VoidCallback? onLinkTracker;
  final VoidCallback? onUnlinkTracker;

  const TrackerStatusCard({
    super.key,
    required this.vehicle,
    this.trackerStatus,
    this.isLoading = false,
    this.onLinkTracker,
    this.onUnlinkTracker,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!vehicle.hasTracker) {
      return _buildNoTrackerCard(context, colorScheme, textTheme);
    }

    return _buildLinkedTrackerCard(context, colorScheme, textTheme);
  }

  Widget _buildNoTrackerCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      color: colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.gps_off,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No GPS Tracker',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Link a GPS tracker to enable real-time tracking',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isLoading ? null : onLinkTracker,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                label: const Text('Link Tracker'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedTrackerCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isOnline = trackerStatus?.online ?? false;
    final statusColor = isOnline ? AppColors.statusOnline : AppColors.statusOffline;

    return Card(
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.gps_fixed,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GPS Tracker Linked',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicle.trackerId ?? '',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOnline ? 'Online' : 'Offline',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (trackerStatus != null) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              // Tracker stats
              Row(
                children: [
                  _buildStatItem(
                    context,
                    Icons.battery_full,
                    '${trackerStatus!.battery}%',
                    'Battery',
                    _getBatteryColor(trackerStatus!.battery),
                  ),
                  const SizedBox(width: 24),
                  _buildStatItem(
                    context,
                    Icons.speed,
                    trackerStatus!.speed.formatSpeed,
                    'Speed',
                    colorScheme.primary,
                  ),
                  const SizedBox(width: 24),
                  _buildStatItem(
                    context,
                    Icons.access_time,
                    trackerStatus!.lastUpdate.timeAgo,
                    'Last Update',
                    colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // Unlink button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onUnlinkTracker,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link_off),
                label: const Text('Unlink Tracker'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBatteryColor(int battery) {
    if (battery >= 50) return AppColors.statusOnline;
    if (battery >= 20) return AppColors.statusIdle;
    return AppColors.statusAlert;
  }
}
