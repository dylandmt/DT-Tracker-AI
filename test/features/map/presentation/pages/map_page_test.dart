import 'package:dt_tracker_ai/core/permissions/permission_handler.dart';
import 'package:dt_tracker_ai/core/permissions/permission_status.dart';
import 'package:dt_tracker_ai/core/theme/app_theme.dart';
import 'package:dt_tracker_ai/features/geofences/presentation/bloc/geofence_bloc.dart';
import 'package:dt_tracker_ai/features/map/domain/entities/vehicle_location.dart';
import 'package:dt_tracker_ai/features/map/domain/repositories/map_repository.dart';
import 'package:dt_tracker_ai/features/map/domain/usecases/get_trip_history.dart';
import 'package:dt_tracker_ai/features/map/domain/usecases/get_vehicle_locations.dart';
import 'package:dt_tracker_ai/features/map/presentation/bloc/map_bloc.dart';
import 'package:dt_tracker_ai/features/map/presentation/pages/map_page.dart';
import 'package:dt_tracker_ai/features/map/presentation/widgets/vehicle_info_card.dart';
import 'package:dt_tracker_ai/features/map/presentation/widgets/vehicle_list_panel.dart';
import 'package:dt_tracker_ai/features/vehicles/presentation/cubit/selected_vehicle_cubit.dart';
import 'package:dt_tracker_ai/injection_container.dart';
import 'package:dt_tracker_ai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';

class _MockPermissionHandler extends Mock implements AppPermissionHandler {}

class _MockMapRepository extends Mock implements MapRepository {}

class _MockGeofenceBloc extends Mock implements GeofenceBloc {}

class _MockSelectedVehicleCubit extends Mock implements SelectedVehicleCubit {}

void main() {
  testWidgets(
    'marker and list open details without a change in the active vehicle',
    (tester) async {
      final permissions = _MockPermissionHandler();
      when(
        () => permissions.checkPermission(AppPermission.location),
      ).thenAnswer((_) async => AppPermissionStatus.denied);
      sl.registerSingleton<AppPermissionHandler>(permissions);
      addTearDown(() => sl.unregister<AppPermissionHandler>());

      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const geolocator = MethodChannel('flutter.baseflow.com/geolocator');
      messenger.setMockMethodCallHandler(geolocator, (_) async => true);
      addTearDown(() => messenger.setMockMethodCallHandler(geolocator, null));
      // Keep the native map view from initializing in the widget test.
      messenger.setMockMethodCallHandler(
        SystemChannels.platform_views,
        (_) async => null,
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          SystemChannels.platform_views,
          null,
        ),
      );

      final repository = _MockMapRepository();
      when(
        () => repository.watchVehicleLocations(),
      ).thenAnswer((_) => const Stream.empty());
      final mapBloc = MapBloc(
        getVehicleLocations: GetVehicleLocations(repository),
        watchVehicleLocations: WatchVehicleLocations(repository),
        getTripHistory: GetTripHistory(repository),
        getDayTripPoints: GetDayTripPoints(repository),
      );
      addTearDown(mapBloc.close);
      final geofences = _MockGeofenceBloc();
      when(() => geofences.state).thenReturn(GeofenceState.initial());
      when(() => geofences.stream).thenAnswer((_) => const Stream.empty());
      final activeVehicle = _MockSelectedVehicleCubit();
      when(() => activeVehicle.state).thenReturn(const SelectedVehicleState());
      when(() => activeVehicle.stream).thenAnswer((_) => const Stream.empty());

      final vehicle = VehicleLocationEntity(
        vehicleId: 'vehicle',
        vehicleName: 'Cuervo',
        plateNumber: 'ABC123',
        speed: 0,
        battery: 80,
        isOnline: true,
        trackerId: '123456789012345',
        latitude: 19.4,
        longitude: -99.1,
        lastUpdate: DateTime.utc(2026, 10, 12),
      );
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<MapBloc>.value(value: mapBloc),
            BlocProvider<GeofenceBloc>.value(value: geofences),
            BlocProvider<SelectedVehicleCubit>.value(value: activeVehicle),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const MapPage(),
          ),
        ),
      );
      mapBloc.add(LocationsUpdated([vehicle]));
      await tester.pumpAndSettle();

      final map = find.byType(GoogleMap);
      final sheet = find.byType(VehicleInfoCard);
      tester.widget<GoogleMap>(map).markers.single.onTap!();
      await tester.pumpAndSettle();
      expect(sheet, findsOneWidget);
      expect(tester.widget<VehicleInfoCard>(sheet).vehicle, vehicle);

      tester.widget<GoogleMap>(map).onTap!(const LatLng(19.5, -99.1));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);

      await tester.tap(find.byTooltip('Vehicles'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cuervo'));
      await tester.pumpAndSettle();
      expect(find.byType(VehicleListPanel), findsNothing);
      expect(sheet, findsOneWidget);
      expect(tester.widget<VehicleInfoCard>(sheet).vehicle, vehicle);

      final refreshed = vehicle.copyWithLocation(speed: 42);
      mapBloc.add(LocationsUpdated([refreshed]));
      await tester.pumpAndSettle();
      expect(tester.widget<VehicleInfoCard>(sheet).vehicle, refreshed);
      verify(() => activeVehicle.selectVehicle(vehicle.vehicleId)).called(2);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
