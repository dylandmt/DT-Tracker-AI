import 'package:dt_tracker_ai/core/theme/app_theme.dart';
import 'package:dt_tracker_ai/features/map/domain/entities/vehicle_location.dart';
import 'package:dt_tracker_ai/features/map/presentation/widgets/vehicle_info_card.dart';
import 'package:dt_tracker_ai/features/map/presentation/widgets/vehicle_list_panel.dart';
import 'package:dt_tracker_ai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final onlineVehicle = _vehicle(
    id: 'online',
    name: 'Cuervo',
    plate: 'NZY998A',
    online: true,
    speed: 42,
  );
  final offlineVehicle = _vehicle(
    id: 'offline',
    name: 'Falcon',
    plate: 'ABC123',
    online: false,
    speed: 0,
  );

  Widget subject(Widget child, {bool dark = true}) => MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('vehicle selector searches and filters real status values', (
    tester,
  ) async {
    VehicleLocationEntity? selected;
    await tester.pumpWidget(
      subject(
        VehicleListPanel(
          vehicles: [onlineVehicle, offlineVehicle],
          onVehicleSelected: (vehicle) => selected = vehicle,
        ),
      ),
    );

    expect(find.text('Cuervo'), findsOneWidget);
    expect(find.text('Falcon'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-220, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Offline').first);
    await tester.pumpAndSettle();
    expect(find.text('Cuervo'), findsNothing);
    expect(find.text('Falcon'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ABC123');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Falcon'));
    expect(selected, offlineVehicle);
  });

  testWidgets('vehicle selector renders its empty state in light mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        VehicleListPanel(vehicles: const [], onVehicleSelected: (_) {}),
        dark: false,
      ),
    );

    expect(find.text('No vehicles with trackers'), findsOneWidget);
  });

  testWidgets(
    'vehicle sheet opens intermediate and supports compact and expanded snaps',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var historyRequests = 0;
      final stages = <VehicleSheetStage>[];
      await tester.pumpWidget(
        subject(
          Stack(
            children: [
              Positioned.fill(
                child: VehicleInfoCard(
                  vehicle: onlineVehicle,
                  onViewHistory: () => historyRequests += 1,
                  onNavigate: () {},
                  onGeofences: () {},
                  onAlerts: () {},
                  onShare: () {},
                  onLiveTracking: () {},
                  onStageChanged: stages.add,
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.text('History'), findsOneWidget);
      expect(find.text('Tracker'), findsWidgets);
      await tester.dragFrom(const Offset(200, 520), const Offset(0, 420));
      await tester.pumpAndSettle();
      expect(find.text('History'), findsNothing);
      expect(find.text('42 km/h'), findsOneWidget);

      await tester.dragFrom(const Offset(200, 700), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Share location'), findsOneWidget);
      expect(stages, contains(VehicleSheetStage.expanded));
      await tester.tap(find.text('History'));
      expect(historyRequests, 1);
    },
  );

  testWidgets('vehicle sheet returns to intermediate when vehicle changes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final stages = <VehicleSheetStage>[];

    await tester.pumpWidget(
      subject(
        Stack(
          children: [
            Positioned.fill(
              child: VehicleInfoCard(
                key: ValueKey(onlineVehicle.vehicleId),
                vehicle: onlineVehicle,
                onStageChanged: stages.add,
              ),
            ),
          ],
        ),
      ),
    );
    await tester.dragFrom(const Offset(200, 520), const Offset(0, 420));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      subject(
        Stack(
          children: [
            Positioned.fill(
              child: VehicleInfoCard(
                key: ValueKey(offlineVehicle.vehicleId),
                vehicle: offlineVehicle,
                onStageChanged: stages.add,
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
  });
}

VehicleLocationEntity _vehicle({
  required String id,
  required String name,
  required String plate,
  required bool online,
  required double speed,
}) => VehicleLocationEntity(
  vehicleId: id,
  vehicleName: name,
  plateNumber: plate,
  trackerId: '123456789012345',
  latitude: 19.4,
  longitude: -99.1,
  speed: speed,
  battery: 82,
  isOnline: online,
  lastUpdate: DateTime.utc(2026, 10, 12, 12),
);
