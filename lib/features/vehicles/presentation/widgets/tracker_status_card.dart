import 'package:flutter/material.dart';

import '../../../../core/design/dt_components.dart';
import '../../../../core/design/dt_design_tokens.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/tracker_info.dart';
import '../../domain/entities/vehicle.dart';

class TrackerStatusCard extends StatelessWidget {
  const TrackerStatusCard({
    super.key,
    required this.vehicle,
    this.trackerStatus,
    this.isLoading = false,
    this.onLinkTracker,
    this.onUnlinkTracker,
  });

  final VehicleEntity vehicle;
  final TrackerStatusEntity? trackerStatus;
  final bool isLoading;
  final VoidCallback? onLinkTracker;
  final VoidCallback? onUnlinkTracker;

  @override
  Widget build(BuildContext context) {
    if (!vehicle.hasTracker) return _unlinked(context);
    return _linked(context);
  }

  Widget _unlinked(BuildContext context) => DTGlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.dtColors.muted.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.gps_off, color: context.dtColors.muted),
            ),
            const SizedBox(width: DTSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.noGpsTracker,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: DTSpacing.xxs),
                  Text(
                    context.l10n.linkGpsTrackerToTrack,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: DTSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isLoading ? null : onLinkTracker,
            icon: _progressOrIcon(Icons.link),
            label: Text(context.l10n.linkGpsTracker),
          ),
        ),
      ],
    ),
  );

  Widget _linked(BuildContext context) {
    final status = trackerStatus;
    final online = status?.online ?? false;
    final designStatus = online
        ? DTVehicleStatus.online
        : DTVehicleStatus.offline;
    return DTGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      (online
                              ? context.dtColors.online
                              : context.dtColors.offline)
                          .withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.gps_fixed,
                  color: online
                      ? context.dtColors.online
                      : context.dtColors.offline,
                ),
              ),
              const SizedBox(width: DTSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.gpsTrackerLinked,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: DTSpacing.xxs),
                    Text(
                      vehicle.trackerId ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              DTStatusPill(
                status: designStatus,
                label: online ? context.l10n.online : context.l10n.offline,
              ),
            ],
          ),
          if (status != null) ...[
            const SizedBox(height: DTSpacing.md),
            Divider(color: context.dtColors.border, height: 1),
            const SizedBox(height: DTSpacing.md),
            Row(
              children: [
                _metric(
                  context,
                  Icons.battery_full_outlined,
                  '${status.battery}%',
                  context.l10n.battery,
                  status.battery < 20
                      ? context.dtColors.alert
                      : context.dtColors.online,
                ),
                _metric(
                  context,
                  Icons.speed_outlined,
                  status.speed.localizedSpeed(context),
                  context.l10n.speed,
                  Theme.of(context).colorScheme.primary,
                ),
                _metric(
                  context,
                  Icons.schedule_outlined,
                  status.lastUpdate.localizedTimeAgo(context),
                  context.l10n.lastUpdate,
                  context.dtColors.textSecondary,
                ),
              ],
            ),
          ],
          const SizedBox(height: DTSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onUnlinkTracker,
              icon: _progressOrIcon(Icons.link_off),
              label: Text(context.l10n.unlinkTracker),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.dtColors.alert,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) => Expanded(
    child: Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: DTSpacing.xxs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );

  Widget _progressOrIcon(IconData icon) => isLoading
      ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Icon(icon);
}
