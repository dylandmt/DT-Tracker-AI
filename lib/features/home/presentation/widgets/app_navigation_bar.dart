import 'package:flutter/material.dart';

import '../../../../core/design/dt_components.dart';
import '../../../../core/utils/extensions.dart';

/// Navigation destinations for the app
enum AppDestination { home, map, vehicles, statistics, settings }

/// App bottom navigation bar using Material 3 NavigationBar
class AppNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DTBottomNavigation(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        DTNavigationDestination(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: context.l10n.home,
        ),
        DTNavigationDestination(
          icon: Icons.map_outlined,
          selectedIcon: Icons.map,
          label: context.l10n.map,
        ),
        DTNavigationDestination(
          icon: Icons.directions_car_outlined,
          selectedIcon: Icons.directions_car,
          label: context.l10n.vehicles,
        ),
        DTNavigationDestination(
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart,
          label: context.l10n.statistics,
        ),
        DTNavigationDestination(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: context.l10n.settings,
        ),
      ],
    );
  }
}
