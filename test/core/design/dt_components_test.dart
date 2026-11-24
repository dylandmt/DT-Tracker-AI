import 'package:dt_tracker_ai/core/design/dt_components.dart';
import 'package:dt_tracker_ai/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject(Widget child, {bool dark = false}) => MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('renders semantic vehicle status colors in both themes', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        const DTStatusPill(status: DTVehicleStatus.online, label: 'Online'),
      ),
    );
    expect(find.text('Online'), findsOneWidget);

    await tester.pumpWidget(
      buildSubject(
        const DTStatusPill(status: DTVehicleStatus.offline, label: 'Offline'),
        dark: true,
      ),
    );
    expect(find.text('Offline'), findsOneWidget);
  });

  testWidgets('vehicle selector and action tile invoke callbacks', (
    tester,
  ) async {
    var selections = 0;
    var actions = 0;
    await tester.pumpWidget(
      buildSubject(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DTVehicleSelector(label: 'CUERVO', onTap: () => selections += 1),
            DTActionTile(
              icon: const Icon(Icons.location_searching),
              label: 'Real time',
              onTap: () => actions += 1,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('CUERVO'));
    await tester.tap(find.text('Real time'));
    expect(selections, 1);
    expect(actions, 1);
  });

  testWidgets('compact action tiles preserve the title on narrow layouts', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        SizedBox(
          width: 150,
          height: 76,
          child: DTActionTile(
            icon: const Icon(Icons.fence_outlined),
            label: 'Geofences',
            subtitle: 'Zones and alerts',
            compact: true,
            showTrailing: false,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Geofences'), findsOneWidget);
    expect(find.text('Zones and alerts'), findsNothing);
  });

  testWidgets('compact metric tiles remain legible in a three-column width', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        SizedBox(
          width: 104,
          child: DTMetricTile(
            icon: const Icon(Icons.battery_full_outlined),
            value: '95%',
            label: 'Battery',
            compact: true,
          ),
        ),
      ),
    );

    expect(find.text('95%'), findsOneWidget);
    expect(find.text('Battery'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'segmented tabs and five destination navigation report selection',
    (tester) async {
      var selectedTab = 0;
      var selectedDestination = 0;
      await tester.pumpWidget(
        buildSubject(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DTSegmentedTabs(
                labels: const ['Day', 'Week', 'Month', 'Custom'],
                selectedIndex: 0,
                onSelected: (value) => selectedTab = value,
              ),
              SizedBox(
                height: 80,
                child: DTBottomNavigation(
                  selectedIndex: 0,
                  onDestinationSelected: (value) => selectedDestination = value,
                  destinations: const [
                    DTNavigationDestination(
                      label: 'Home',
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                    ),
                    DTNavigationDestination(
                      label: 'Map',
                      icon: Icons.map_outlined,
                      selectedIcon: Icons.map,
                    ),
                    DTNavigationDestination(
                      label: 'Vehicles',
                      icon: Icons.directions_car_outlined,
                      selectedIcon: Icons.directions_car,
                    ),
                    DTNavigationDestination(
                      label: 'Statistics',
                      icon: Icons.bar_chart_outlined,
                      selectedIcon: Icons.bar_chart,
                    ),
                    DTNavigationDestination(
                      label: 'Settings',
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Week'));
      await tester.tap(find.text('Statistics'));
      expect(selectedTab, 1);
      expect(selectedDestination, 3);
    },
  );
}
