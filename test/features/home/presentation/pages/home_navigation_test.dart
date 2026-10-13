import 'package:dartz/dartz.dart';
import 'package:dt_tracker_ai/core/errors/failures.dart';
import 'package:dt_tracker_ai/core/theme/app_theme.dart';
import 'package:dt_tracker_ai/features/home/presentation/pages/home_page.dart';
import 'package:dt_tracker_ai/features/vehicles/domain/entities/vehicle.dart';
import 'package:dt_tracker_ai/features/vehicles/domain/repositories/vehicle_repository.dart';
import 'package:dt_tracker_ai/features/vehicles/domain/usecases/get_vehicles.dart';
import 'package:dt_tracker_ai/injection_container.dart';
import 'package:dt_tracker_ai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockVehicleRepository extends Mock implements VehicleRepository {}

void main() {
  late _MockVehicleRepository repository;

  setUp(() async {
    await sl.reset();
    repository = _MockVehicleRepository();
    when(
      () => repository.getVehicles(),
    ).thenAnswer((_) async => const Right<Failure, List<VehicleEntity>>([]));
    sl.registerLazySingleton<GetVehicles>(() => GetVehicles(repository));
  });

  tearDown(() async => sl.reset());

  testWidgets('switches through the official five destinations', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home/dashboard',
      routes: [
        _route('/home/dashboard', 'dashboard'),
        _route('/home/map', 'map-screen'),
        _route('/home/vehicles', 'vehicles-screen'),
        _route('/statistics', 'statistics-screen'),
        _route('/home/settings', 'settings-screen'),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();
    expect(find.text('statistics-screen'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('settings-screen'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      4,
    );
  });
}

GoRoute _route(String path, String label) => GoRoute(
  path: path,
  builder: (_, _) => HomePage(child: Center(child: Text(label))),
);
