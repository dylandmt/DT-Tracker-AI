import 'package:dt_tracker_ai/core/theme/app_theme.dart';
import 'package:dt_tracker_ai/features/vehicles/domain/entities/tracker_info.dart';
import 'package:dt_tracker_ai/features/vehicles/domain/entities/vehicle.dart';
import 'package:dt_tracker_ai/features/vehicles/presentation/widgets/tracker_status_card.dart';
import 'package:dt_tracker_ai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final linkedVehicle = _vehicle(trackerId: '123456789012345');

  Widget subject(Widget child, {bool dark = false}) => MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );

  testWidgets('shows link action when vehicle has no tracker', (tester) async {
    var links = 0;
    await tester.pumpWidget(
      subject(
        TrackerStatusCard(vehicle: _vehicle(), onLinkTracker: () => links += 1),
      ),
    );

    expect(find.text('No GPS Tracker'), findsOneWidget);
    await tester.tap(find.text('Link GPS Tracker'));
    expect(links, 1);
  });

  testWidgets('shows linked tracker telemetry in dark mode', (tester) async {
    await tester.pumpWidget(
      subject(
        TrackerStatusCard(
          vehicle: linkedVehicle,
          trackerStatus: TrackerStatusEntity(
            imei: linkedVehicle.trackerId!,
            online: true,
            battery: 81,
            speed: 43.2,
            lastUpdate: DateTime.now(),
          ),
        ),
        dark: true,
      ),
    );

    expect(find.text('Online'), findsOneWidget);
    expect(find.text('81%'), findsOneWidget);
    expect(find.textContaining('43.2'), findsOneWidget);
    expect(find.text('Unlink Tracker'), findsOneWidget);
  });
}

VehicleEntity _vehicle({String? trackerId}) => VehicleEntity(
  id: 'vehicle-1',
  name: 'Cuervo',
  plateNumber: 'NZY998A',
  trackerId: trackerId,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
