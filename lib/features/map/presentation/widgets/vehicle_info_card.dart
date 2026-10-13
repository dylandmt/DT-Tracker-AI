import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dt_components.dart';
import '../../../../core/design/dt_design_tokens.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vehicle_location.dart';

enum VehicleSheetStage { compact, intermediate, expanded }

class VehicleInfoCard extends StatefulWidget {
  const VehicleInfoCard({
    super.key,
    required this.vehicle,
    this.onClose,
    this.onViewHistory,
    this.onNavigate,
    this.onGeofences,
    this.onAlerts,
    this.onShare,
    this.onLiveTracking,
    this.onStageChanged,
  });

  final VehicleLocationEntity vehicle;
  final VoidCallback? onClose;
  final VoidCallback? onViewHistory;
  final VoidCallback? onNavigate;
  final VoidCallback? onGeofences;
  final VoidCallback? onAlerts;
  final VoidCallback? onShare;
  final VoidCallback? onLiveTracking;
  final ValueChanged<VehicleSheetStage>? onStageChanged;

  @override
  State<VehicleInfoCard> createState() => _VehicleInfoCardState();
}

class _VehicleInfoCardState extends State<VehicleInfoCard> {
  static const _compactSize = .24;
  static const _intermediateSize = .55;
  static const _expandedSize = .86;

  final _sheetController = DraggableScrollableController();
  VehicleSheetStage _stage = VehicleSheetStage.intermediate;

  bool get _isCompact => _stage == VehicleSheetStage.compact;

  @override
  void didUpdateWidget(covariant VehicleInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicle.vehicleId != widget.vehicle.vehicleId) {
      _setIntermediateSnap();
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _setIntermediateSnap() {
    if (_stage != VehicleSheetStage.intermediate) {
      setState(() => _stage = VehicleSheetStage.intermediate);
      widget.onStageChanged?.call(VehicleSheetStage.intermediate);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sheetController.isAttached) return;
      _sheetController.animateTo(
        _intermediateSize,
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : DTMotion.sheet,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      controller: _sheetController,
      minChildSize: _compactSize,
      initialChildSize: _intermediateSize,
      maxChildSize: _expandedSize,
      snap: true,
      snapSizes: const [_compactSize, _intermediateSize, _expandedSize],
      builder: (context, scrollController) =>
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              final stage = _stageFor(notification.extent);
              if (_stage != stage) {
                setState(() => _stage = stage);
                widget.onStageChanged?.call(stage);
              }
              return false;
            },
            child: DTVehicleBottomSheet(
              padding: const EdgeInsets.fromLTRB(
                DTSpacing.md,
                DTSpacing.xs,
                DTSpacing.md,
                DTSpacing.md,
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: DTSpacing.sm),
                      decoration: BoxDecoration(
                        color: context.dtColors.muted.withValues(alpha: .55),
                        borderRadius: const BorderRadius.all(DTRadius.pill),
                      ),
                    ),
                  ),
                  _header(context, l10n),
                  const SizedBox(height: DTSpacing.sm),
                  _compactMetrics(context, l10n),
                  if (!_isCompact) ...[
                    const SizedBox(height: DTSpacing.sm),
                    _location(context),
                    const SizedBox(height: DTSpacing.md),
                    _primaryActions(context, l10n),
                    const SizedBox(height: DTSpacing.md),
                    Text(
                      l10n.tracker,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: DTSpacing.sm),
                    _trackerDetails(context, l10n),
                    const SizedBox(height: DTSpacing.md),
                    _quickActions(context, l10n),
                  ],
                ],
              ),
            ),
          ),
    );
  }

  VehicleSheetStage _stageFor(double extent) {
    if (extent > .64) return VehicleSheetStage.expanded;
    if (extent >= .42) return VehicleSheetStage.intermediate;
    return VehicleSheetStage.compact;
  }

  Widget _header(BuildContext context, AppLocalizations l10n) => Row(
    children: [
      _vehicleImage(context),
      const SizedBox(width: DTSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.vehicle.vehicleName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              widget.vehicle.plateNumber,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      DTStatusPill(
        status: _designStatus(widget.vehicle),
        label: _statusLabel(l10n, widget.vehicle),
      ),
      if (widget.onClose != null)
        IconButton(
          tooltip: l10n.dismiss,
          onPressed: widget.onClose,
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
    ],
  );

  Widget _compactMetrics(BuildContext context, AppLocalizations l10n) => Row(
    children: [
      Expanded(
        child: _metric(
          context,
          Icons.speed_outlined,
          widget.vehicle.speed.localizedSpeed(context),
          l10n.speed,
          Theme.of(context).colorScheme.primary,
        ),
      ),
      if (!_isCompact) ...[
        Expanded(
          child: _metric(
            context,
            Icons.battery_full_outlined,
            '${widget.vehicle.battery}%',
            l10n.battery,
            widget.vehicle.isBatteryLow
                ? context.dtColors.alert
                : context.dtColors.online,
          ),
        ),
        Expanded(
          child: _metric(
            context,
            Icons.schedule_outlined,
            widget.vehicle.lastUpdate.localizedTimeAgo(context),
            l10n.updated,
            context.dtColors.textSecondary,
          ),
        ),
      ],
    ],
  );

  Widget _metric(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) => Column(
    children: [
      Icon(icon, color: color),
      const SizedBox(height: DTSpacing.xxs),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );

  Widget _location(BuildContext context) => DTGlassCard(
    padding: const EdgeInsets.all(DTSpacing.sm),
    child: Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: DTSpacing.xs),
        Expanded(
          child: Text(
            widget.vehicle.formattedCoordinates,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context)!.locationServices,
          onPressed: widget.onLiveTracking,
          icon: const Icon(Icons.my_location_outlined),
        ),
      ],
    ),
  );

  Widget _primaryActions(BuildContext context, AppLocalizations l10n) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: widget.onViewHistory,
          icon: const Icon(Icons.timeline_outlined),
          label: Text(l10n.history),
        ),
      ),
      const SizedBox(width: DTSpacing.sm),
      Expanded(
        child: FilledButton.icon(
          onPressed: widget.onNavigate,
          icon: const Icon(Icons.navigation_outlined),
          label: Text(l10n.navigate),
        ),
      ),
    ],
  );

  Widget _trackerDetails(BuildContext context, AppLocalizations l10n) =>
      DTGlassCard(
        child: Column(
          children: [
            _detailRow(
              context,
              Icons.gps_fixed,
              l10n.tracker,
              widget.vehicle.trackerId,
            ),
            const Divider(height: DTSpacing.lg),
            _detailRow(
              context,
              Icons.wifi_outlined,
              l10n.tracking,
              _statusLabel(l10n, widget.vehicle),
            ),
          ],
        ),
      );

  Widget _detailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) => Row(
    children: [
      Icon(icon, size: 18, color: context.dtColors.textSecondary),
      const SizedBox(width: DTSpacing.xs),
      Expanded(
        child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ),
      Text(value, style: Theme.of(context).textTheme.labelMedium),
    ],
  );

  Widget _quickActions(BuildContext context, AppLocalizations l10n) {
    final actions = <Widget>[
      if (widget.onLiveTracking != null)
        DTActionTile(
          icon: const Icon(Icons.gps_fixed),
          label: l10n.realTime,
          onTap: widget.onLiveTracking!,
          compact: true,
          showTrailing: false,
        ),
      if (widget.onGeofences != null)
        DTActionTile(
          icon: const Icon(Icons.fence_outlined),
          label: l10n.geofences,
          onTap: widget.onGeofences!,
          color: context.dtColors.purple,
          compact: true,
          showTrailing: false,
        ),
      if (widget.onAlerts != null)
        DTActionTile(
          icon: const Icon(Icons.notifications_active_outlined),
          label: l10n.alerts,
          onTap: widget.onAlerts!,
          color: context.dtColors.idle,
          compact: true,
          showTrailing: false,
        ),
      if (widget.onShare != null)
        DTActionTile(
          icon: const Icon(Icons.share_outlined),
          label: l10n.shareLocation,
          onTap: widget.onShare!,
          color: context.dtColors.online,
          compact: true,
          showTrailing: false,
        ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: DTSpacing.xs,
      crossAxisSpacing: DTSpacing.xs,
      childAspectRatio: 2.1,
      children: actions,
    );
  }

  Widget _vehicleImage(BuildContext context) => Container(
    width: 56,
    height: 56,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: context.dtColors.surfaceRaised,
      borderRadius: const BorderRadius.all(DTRadius.md),
    ),
    child: widget.vehicle.imageUrl == null
        ? const Icon(Icons.directions_car_outlined)
        : CachedNetworkImage(
            imageUrl: widget.vehicle.imageUrl!,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => const Icon(Icons.directions_car_outlined),
          ),
  );

  String _statusLabel(AppLocalizations l10n, VehicleLocationEntity vehicle) =>
      switch (vehicle.status) {
        VehicleStatus.moving => l10n.moving,
        VehicleStatus.idle => l10n.idle,
        VehicleStatus.offline => l10n.offline,
      };

  DTVehicleStatus _designStatus(VehicleLocationEntity vehicle) =>
      switch (vehicle.status) {
        VehicleStatus.moving => DTVehicleStatus.moving,
        VehicleStatus.idle => DTVehicleStatus.idle,
        VehicleStatus.offline => DTVehicleStatus.offline,
      };
}
