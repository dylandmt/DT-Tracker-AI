import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/vehicle_location.dart';

/// Bottom sheet card showing selected vehicle information
class VehicleInfoCard extends StatelessWidget {
  final VehicleLocationEntity vehicle;
  final VoidCallback? onClose;
  final VoidCallback? onViewHistory;
  final VoidCallback? onNavigate;

  const VehicleInfoCard({
    super.key,
    required this.vehicle,
    this.onClose,
    this.onViewHistory,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header row with vehicle info and close button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle image or icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getVehicleColor(vehicle.color)?.withValues(alpha: 0.2) ??
                      colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: vehicle.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          vehicle.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.directions_car,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.directions_car,
                        color: _getVehicleColor(vehicle.color) ??
                            colorScheme.primary,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 12),

              // Vehicle details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.vehicleName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.plateNumber,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge
              _StatusBadge(status: vehicle.status),

              // Close button
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _StatItem(
                icon: Icons.speed,
                label: 'Speed',
                value: vehicle.formattedSpeed,
                color: vehicle.speed > 100
                    ? AppColors.statusAlert
                    : colorScheme.primary,
              ),
              _StatItem(
                icon: Icons.battery_std,
                label: 'Battery',
                value: '${vehicle.battery}%',
                color: vehicle.isBatteryLow
                    ? AppColors.statusAlert
                    : AppColors.statusOnline,
              ),
              _StatItem(
                icon: Icons.access_time,
                label: 'Updated',
                value: vehicle.lastUpdate.timeAgo,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Location info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vehicle.formattedCoordinates,
                    style: textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewHistory,
                  icon: const Icon(Icons.timeline),
                  label: const Text('History'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navigate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color? _getVehicleColor(String? colorName) {
    if (colorName == null) return null;
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'black':
        return Colors.black87;
      case 'white':
        return Colors.grey;
      case 'silver':
        return Colors.blueGrey;
      case 'gray':
      case 'grey':
        return Colors.grey;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.amber;
      case 'orange':
        return Colors.orange;
      case 'brown':
        return Colors.brown;
      default:
        return null;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final VehicleStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (status) {
      VehicleStatus.moving => (AppColors.statusMoving, 'Moving', Icons.play_arrow),
      VehicleStatus.idle => (AppColors.statusIdle, 'Idle', Icons.pause),
      VehicleStatus.offline => (AppColors.statusOffline, 'Offline', Icons.cloud_off),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
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
}
