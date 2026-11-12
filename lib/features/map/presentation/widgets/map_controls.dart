import 'package:flutter/material.dart';

import '../../../../core/design/dt_components.dart';
import '../../../../core/design/dt_design_tokens.dart';
import '../../../../core/utils/extensions.dart';
import '../bloc/map_bloc.dart';

class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
    required this.mapType,
    required this.showTraffic,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMyLocation,
    required this.onFitBounds,
    required this.onToggleTraffic,
    required this.onMapTypeChanged,
  });

  final MapViewType mapType;
  final bool showTraffic;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onMyLocation;
  final VoidCallback onFitBounds;
  final VoidCallback onToggleTraffic;
  final ValueChanged<MapViewType> onMapTypeChanged;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      DTMapActionButton(
        icon: const Icon(Icons.layers_outlined),
        tooltip: context.l10n.mapType,
        onPressed: () => _showMapTypeSheet(context),
        selected: mapType != MapViewType.normal,
      ),
      const SizedBox(height: DTSpacing.xs),
      DTMapActionButton(
        icon: const Icon(Icons.traffic_outlined),
        tooltip: showTraffic
            ? context.l10n.hideTraffic
            : context.l10n.showTraffic,
        onPressed: onToggleTraffic,
        selected: showTraffic,
      ),
      const SizedBox(height: DTSpacing.xs),
      _ZoomControl(onZoomIn: onZoomIn, onZoomOut: onZoomOut),
      const SizedBox(height: DTSpacing.xs),
      DTMapActionButton(
        icon: const Icon(Icons.my_location_outlined),
        tooltip: context.l10n.myLocation,
        onPressed: onMyLocation,
      ),
      const SizedBox(height: DTSpacing.xs),
      DTMapActionButton(
        icon: const Icon(Icons.fit_screen_outlined),
        tooltip: context.l10n.fitAllVehicles,
        onPressed: onFitBounds,
      ),
    ],
  );

  void _showMapTypeSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    builder: (context) => DTVehicleBottomSheet(
      showHandle: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: MapViewType.values
            .map(
              (type) => ListTile(
                leading: Icon(_iconFor(type)),
                title: Text(_labelFor(context, type)),
                trailing: type == mapType ? const Icon(Icons.check) : null,
                onTap: () {
                  onMapTypeChanged(type);
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    ),
  );

  String _labelFor(BuildContext context, MapViewType type) => switch (type) {
    MapViewType.normal => context.l10n.normal,
    MapViewType.satellite => context.l10n.satellite,
    MapViewType.terrain => context.l10n.terrain,
    MapViewType.hybrid => context.l10n.hybrid,
  };

  IconData _iconFor(MapViewType type) => switch (type) {
    MapViewType.normal => Icons.map_outlined,
    MapViewType.satellite => Icons.satellite_alt_outlined,
    MapViewType.terrain => Icons.terrain_outlined,
    MapViewType.hybrid => Icons.layers_outlined,
  };
}

class _ZoomControl extends StatelessWidget {
  const _ZoomControl({required this.onZoomIn, required this.onZoomOut});

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    elevation: 2,
    shape: const StadiumBorder(),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: context.l10n.zoomIn,
          onPressed: onZoomIn,
          icon: const Icon(Icons.add),
        ),
        Container(width: 28, height: 1, color: context.dtColors.border),
        IconButton(
          tooltip: context.l10n.zoomOut,
          onPressed: onZoomOut,
          icon: const Icon(Icons.remove),
        ),
      ],
    ),
  );
}
