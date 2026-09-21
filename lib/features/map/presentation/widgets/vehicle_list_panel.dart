import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vehicle_location.dart';

/// Sliding panel showing list of vehicles with their status
class VehicleListPanel extends StatelessWidget {
  final List<VehicleLocationEntity> vehicles;
  final VehicleLocationEntity? selectedVehicle;
  final ValueChanged<VehicleLocationEntity> onVehicleSelected;
  final VoidCallback? onClose;

  const VehicleListPanel({
    super.key,
    required this.vehicles,
    this.selectedVehicle,
    required this.onVehicleSelected,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_car, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.vehicles,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.vehicleSummary(
                          vehicles.length,
                          vehicles.where((v) => v.isOnline).length,
                        ),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),

          // Vehicle list
          Expanded(
            child: vehicles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noVehiclesWithTrackers,
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      final isSelected =
                          selectedVehicle?.vehicleId == vehicle.vehicleId;

                      return _VehicleListItem(
                        vehicle: vehicle,
                        isSelected: isSelected,
                        onTap: () => onVehicleSelected(vehicle),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _VehicleListItem extends StatelessWidget {
  final VehicleLocationEntity vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleListItem({
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final statusColor = switch (vehicle.status) {
      VehicleStatus.moving => AppColors.statusMoving,
      VehicleStatus.idle => AppColors.statusIdle,
      VehicleStatus.offline => AppColors.statusOffline,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : null,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: colorScheme.primary, width: 2)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Stack(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: vehicle.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: vehicle.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(
                          Icons.directions_car,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.directions_car,
                      color: colorScheme.onSurfaceVariant,
                    ),
            ),
            // Status indicator
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          vehicle.vehicleName,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          vehicle.plateNumber,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.speed,
                  size: 14,
                  color: vehicle.speed > 100
                      ? AppColors.statusAlert
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  vehicle.speed.localizedSpeed(context),
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: vehicle.speed > 100 ? AppColors.statusAlert : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              vehicle.lastUpdate.localizedTimeAgo(context),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
