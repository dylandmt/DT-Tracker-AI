import 'package:flutter/material.dart';

import '../bloc/map_bloc.dart';

/// Map control buttons (zoom, map type, etc.)
class MapControls extends StatelessWidget {
  final MapViewType mapType;
  final bool showTraffic;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onMyLocation;
  final VoidCallback onFitBounds;
  final VoidCallback onToggleTraffic;
  final ValueChanged<MapViewType> onMapTypeChanged;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Map type button
        _ControlButton(
          icon: Icons.layers,
          onPressed: () => _showMapTypeSheet(context),
          tooltip: 'Map type',
        ),
        const SizedBox(height: 8),

        // Traffic toggle
        _ControlButton(
          icon: Icons.traffic,
          onPressed: onToggleTraffic,
          isActive: showTraffic,
          tooltip: showTraffic ? 'Hide traffic' : 'Show traffic',
        ),
        const SizedBox(height: 8),

        // Zoom in
        _ControlButton(
          icon: Icons.add,
          onPressed: onZoomIn,
          tooltip: 'Zoom in',
        ),
        const SizedBox(height: 4),

        // Zoom out
        _ControlButton(
          icon: Icons.remove,
          onPressed: onZoomOut,
          tooltip: 'Zoom out',
        ),
        const SizedBox(height: 8),

        // My location
        _ControlButton(
          icon: Icons.my_location,
          onPressed: onMyLocation,
          tooltip: 'My location',
        ),
        const SizedBox(height: 8),

        // Fit all vehicles
        _ControlButton(
          icon: Icons.fit_screen,
          onPressed: onFitBounds,
          tooltip: 'Fit all vehicles',
        ),
      ],
    );
  }

  void _showMapTypeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MapTypeSheet(
        currentType: mapType,
        onTypeSelected: (type) {
          onMapTypeChanged(type);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;
  final String tooltip;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    this.isActive = false,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? colorScheme.primaryContainer : colorScheme.surface,
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: isActive ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapTypeSheet extends StatelessWidget {
  final MapViewType currentType;
  final ValueChanged<MapViewType> onTypeSelected;

  const _MapTypeSheet({
    required this.currentType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
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
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'Map Type',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Map type options
          Row(
            children: [
              _MapTypeOption(
                type: MapViewType.normal,
                label: 'Normal',
                icon: Icons.map,
                isSelected: currentType == MapViewType.normal,
                onTap: () => onTypeSelected(MapViewType.normal),
              ),
              const SizedBox(width: 12),
              _MapTypeOption(
                type: MapViewType.satellite,
                label: 'Satellite',
                icon: Icons.satellite_alt,
                isSelected: currentType == MapViewType.satellite,
                onTap: () => onTypeSelected(MapViewType.satellite),
              ),
              const SizedBox(width: 12),
              _MapTypeOption(
                type: MapViewType.terrain,
                label: 'Terrain',
                icon: Icons.terrain,
                isSelected: currentType == MapViewType.terrain,
                onTap: () => onTypeSelected(MapViewType.terrain),
              ),
              const SizedBox(width: 12),
              _MapTypeOption(
                type: MapViewType.hybrid,
                label: 'Hybrid',
                icon: Icons.layers,
                isSelected: currentType == MapViewType.hybrid,
                onTap: () => onTypeSelected(MapViewType.hybrid),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MapTypeOption extends StatelessWidget {
  final MapViewType type;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MapTypeOption({
    required this.type,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: colorScheme.primary, width: 2)
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
