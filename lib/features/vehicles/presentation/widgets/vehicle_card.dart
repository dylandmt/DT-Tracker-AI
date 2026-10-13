import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dt_components.dart';
import '../../../../core/design/dt_design_tokens.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/vehicle.dart';

/// Compact vehicle summary that intentionally shows link state, not live telemetry.
class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.onLongPress,
  });

  final VehicleEntity vehicle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => DTGlassCard(
    onTap: onTap,
    onLongPress: onLongPress,
    semanticLabel: '${vehicle.name}, ${vehicle.plateNumber}',
    padding: const EdgeInsets.all(DTSpacing.sm),
    child: Row(
      children: [
        _photo(context),
        const SizedBox(width: DTSpacing.sm),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicle.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: DTSpacing.xxs),
              Text(
                vehicle.plateNumber,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.dtColors.textSecondary,
                ),
              ),
              if (vehicle.fullDescription != null) ...[
                const SizedBox(height: DTSpacing.xxs),
                Text(
                  vehicle.fullDescription!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: DTSpacing.xs),
              _gpsState(context),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: context.dtColors.muted),
      ],
    ),
  );

  Widget _photo(BuildContext context) => Container(
    width: 84,
    height: 84,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: context.dtColors.surfaceRaised,
      borderRadius: const BorderRadius.all(DTRadius.md),
    ),
    child: vehicle.primaryImageUrl == null
        ? Icon(
            Icons.directions_car_outlined,
            color: context.dtColors.textSecondary,
            size: 34,
          )
        : CachedNetworkImage(
            imageUrl: vehicle.primaryImageUrl!,
            fit: BoxFit.cover,
            placeholder: (_, _) => const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, _, _) => Icon(
              Icons.directions_car_outlined,
              color: context.dtColors.textSecondary,
              size: 34,
            ),
          ),
  );

  Widget _gpsState(BuildContext context) {
    final linked = vehicle.hasTracker;
    final color = linked
        ? Theme.of(context).colorScheme.primary
        : context.dtColors.muted;
    return Semantics(
      label: linked ? context.l10n.gpsTrackerLinked : context.l10n.noGpsTracker,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DTSpacing.xs,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: const BorderRadius.all(DTRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              linked ? Icons.gps_fixed : Icons.gps_off,
              size: 14,
              color: color,
            ),
            const SizedBox(width: DTSpacing.xxs),
            Text(
              linked ? context.l10n.gps : context.l10n.noGps,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
