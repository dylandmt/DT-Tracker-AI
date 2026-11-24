import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'dt_design_tokens.dart';

enum DTVehicleStatus { online, offline, moving, idle, alert }

class DTAppScaffold extends StatelessWidget {
  const DTAppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.useAmbientBackground = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool useAmbientBackground;

  @override
  Widget build(BuildContext context) {
    final asset = Theme.of(context).brightness == Brightness.dark
        ? DTAssets.darkAmbient
        : DTAssets.lightAmbient;
    return Scaffold(
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: useAmbientBackground
          ? Stack(
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: SvgPicture.asset(asset, fit: BoxFit.cover),
                  ),
                ),
                body,
              ],
            )
          : body,
    );
  }
}

class DTGlassCard extends StatelessWidget {
  const DTGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DTSpacing.md),
    this.onTap,
    this.onLongPress,
    this.borderRadius = const BorderRadius.all(DTRadius.lg),
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.dtColors;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final card = AnimatedContainer(
      duration: reduceMotion ? Duration.zero : DTMotion.normal,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: .94),
        borderRadius: borderRadius,
        border: Border.all(color: colors.border.withValues(alpha: .85)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: .18)
                : colors.primaryDeep.withValues(alpha: .05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null && onLongPress == null) {
      return Semantics(
        label: semanticLabel,
        container: semanticLabel != null,
        child: card,
      );
    }
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: borderRadius,
          child: card,
        ),
      ),
    );
  }
}

class DTMetricTile extends StatelessWidget {
  const DTMetricTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.compact = false,
  });

  final Widget icon;
  final String value;
  final String label;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return DTGlassCard(
      semanticLabel: '$label: $value',
      padding: EdgeInsets.symmetric(
        horizontal: DTSpacing.sm,
        vertical: compact ? DTSpacing.sm : DTSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTheme(
            data: IconThemeData(color: accent, size: compact ? 20 : 22),
            child: icon,
          ),
          SizedBox(height: compact ? DTSpacing.xs : DTSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: compact ? 15 : null,
            ),
          ),
          const SizedBox(height: DTSpacing.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class DTStatusPill extends StatelessWidget {
  const DTStatusPill({super.key, required this.status, required this.label});

  final DTVehicleStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.dtColors;
    final color = switch (status) {
      DTVehicleStatus.online => colors.online,
      DTVehicleStatus.offline => colors.offline,
      DTVehicleStatus.moving => colors.moving,
      DTVehicleStatus.idle => colors.idle,
      DTVehicleStatus.alert => colors.alert,
    };
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DTSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .14),
          borderRadius: const BorderRadius.all(DTRadius.pill),
          border: Border.all(color: color.withValues(alpha: .3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: DTSpacing.xs),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class DTVehicleSelector extends StatelessWidget {
  const DTVehicleSelector({
    super.key,
    required this.label,
    required this.onTap,
    this.leading,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget? leading;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled,
    label: label,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: const BorderRadius.all(DTRadius.md),
        child: Ink(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: DTSpacing.md),
          decoration: BoxDecoration(
            color: context.dtColors.surfaceRaised.withValues(alpha: .82),
            borderRadius: const BorderRadius.all(DTRadius.md),
            border: Border.all(color: context.dtColors.border),
          ),
          child: Row(
            children: [
              leading ?? const Icon(Icons.directions_car_outlined),
              const SizedBox(width: DTSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
      ),
    ),
  );
}

class DTVehicleTile extends StatelessWidget {
  const DTVehicleTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusLabel,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final DTVehicleStatus status;
  final String statusLabel;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DTGlassCard(
    onTap: onTap,
    semanticLabel: '$title, $subtitle, $statusLabel',
    child: Row(
      children: [
        leading ?? const Icon(Icons.directions_car_outlined, size: 28),
        const SizedBox(width: DTSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: DTSpacing.xxs),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: DTSpacing.xs),
              DTStatusPill(status: status, label: statusLabel),
            ],
          ),
        ),
        trailing ?? const Icon(Icons.chevron_right),
      ],
    ),
  );
}

class DTActionTile extends StatelessWidget {
  const DTActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.color,
    this.compact = false,
    this.showTrailing = true,
  });

  final Widget icon;
  final String label;
  final String? subtitle;
  final Color? color;
  final VoidCallback onTap;
  final bool compact;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return DTGlassCard(
      onTap: onTap,
      semanticLabel: label,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? DTSpacing.xs : DTSpacing.sm,
        vertical: DTSpacing.xs,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showSubtitle =
              subtitle != null && (!compact || constraints.maxWidth >= 176);
          return Row(
            children: [
              Container(
                width: compact ? 40 : 44,
                height: compact ? 40 : 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: IconTheme(
                  data: IconThemeData(color: accent, size: compact ? 20 : 24),
                  child: icon,
                ),
              ),
              const SizedBox(width: DTSpacing.xs),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (showSubtitle)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (showTrailing)
                Icon(
                  Icons.chevron_right,
                  size: compact ? 18 : 20,
                  color: context.dtColors.muted,
                ),
            ],
          );
        },
      ),
    );
  }
}

class DTSegmentedTabs extends StatelessWidget {
  const DTSegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  }) : assert(labels.length > 1),
       assert(selectedIndex >= 0 && selectedIndex < labels.length);

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label: 'Segmented controls',
      child: Container(
        padding: const EdgeInsets.all(DTSpacing.xxs),
        decoration: BoxDecoration(
          color: context.dtColors.surfaceRaised,
          borderRadius: const BorderRadius.all(DTRadius.pill),
        ),
        child: Row(
          children: List.generate(labels.length, (index) {
            final selected = index == selectedIndex;
            return Expanded(
              child: Semantics(
                button: true,
                selected: selected,
                child: InkWell(
                  onTap: () => onSelected(index),
                  borderRadius: const BorderRadius.all(DTRadius.pill),
                  child: AnimatedContainer(
                    duration: reduceMotion ? Duration.zero : DTMotion.fast,
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(minHeight: 40),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      borderRadius: const BorderRadius.all(DTRadius.pill),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: .24),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      labels[index],
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected
                            ? Theme.of(context).colorScheme.onPrimary
                            : context.dtColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class DTDateRangeSelector extends StatelessWidget {
  const DTDateRangeSelector({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(alignment: Alignment.center),
    ),
  );
}

class DTMapActionButton extends StatelessWidget {
  const DTMapActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
    this.size = 48,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        child: Material(
          color: selected ? scheme.primary : scheme.surface,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: .2),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: IconTheme(
                data: IconThemeData(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ),
                child: Center(child: icon),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DTMapVehicleMarker extends StatelessWidget {
  const DTMapVehicleMarker({super.key, required this.label, this.size = 88});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    image: true,
    child: SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(child: SvgPicture.asset(DTAssets.mapMarkerHalo)),
          Icon(
            Icons.directions_car,
            color: Theme.of(context).colorScheme.onPrimary,
            size: size * .25,
          ),
        ],
      ),
    ),
  );
}

class DTVehicleBottomSheet extends StatelessWidget {
  const DTVehicleBottomSheet({
    super.key,
    required this.child,
    this.showHandle = false,
    this.padding = const EdgeInsets.fromLTRB(
      DTSpacing.md,
      DTSpacing.xs,
      DTSpacing.md,
      DTSpacing.xl,
    ),
  });

  final Widget child;
  final bool showHandle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: DTRadius.xl),
        border: Border(top: BorderSide(color: context.dtColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: showHandle
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: DTSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.dtColors.muted.withValues(alpha: .55),
                    borderRadius: const BorderRadius.all(DTRadius.pill),
                  ),
                ),
                child,
              ],
            )
          : child,
    ),
  );
}

class DTNavigationDestination {
  const DTNavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class DTBottomNavigation extends StatelessWidget {
  const DTBottomNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : assert(destinations.length == 5);

  final List<DTNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
    destinations: destinations
        .map(
          (destination) => NavigationDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: destination.label,
          ),
        )
        .toList(),
  );
}
