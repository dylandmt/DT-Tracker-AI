import 'package:dt_tracker_ai/core/theme/app_theme.dart';
import 'package:dt_tracker_ai/features/vehicles/domain/entities/vehicle.dart';
import 'package:dt_tracker_ai/features/vehicles/presentation/bloc/vehicles_bloc.dart';
import 'package:dt_tracker_ai/features/vehicles/presentation/pages/vehicles_page.dart';
import 'package:dt_tracker_ai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockVehiclesBloc extends Mock implements VehiclesBloc {}

void main() {
  setUpAll(() => registerFallbackValue(const StartWatchingVehicles()));

  final cuervo = _vehicle('cuervo', 'Cuervo', 'NZY998A');
  final falcon = _vehicle('falcon', 'Falcon', 'ABC123');

  Widget subject(VehiclesState state) {
    final bloc = _MockVehiclesBloc();
    when(() => bloc.state).thenReturn(state);
    when(() => bloc.stream).thenAnswer((_) => Stream<VehiclesState>.empty());
    when(() => bloc.add(any())).thenReturn(null);
    return BlocProvider<VehiclesBloc>.value(
      value: bloc,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const VehiclesPage(),
      ),
    );
  }

  testWidgets('renders compact cards and filters locally by plate', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        VehiclesState(
          status: VehiclesStatus.loaded,
          vehicles: [cuervo, falcon],
        ),
      ),
    );

    expect(find.text('Cuervo'), findsOneWidget);
    expect(find.text('Falcon'), findsOneWidget);
    expect(find.text('GPS'), findsOneWidget);
    expect(find.text('No GPS'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ABC123');
    await tester.pump();
    expect(find.text('Cuervo'), findsNothing);
    expect(find.text('Falcon'), findsOneWidget);
  });

  testWidgets('renders the empty state and add action', (tester) async {
    await tester.pumpWidget(
      subject(const VehiclesState(status: VehiclesStatus.loaded, vehicles: [])),
    );

    expect(find.text('No Vehicles Yet'), findsOneWidget);
    expect(find.text('Add Vehicle'), findsWidgets);
  });
}

VehicleEntity _vehicle(String id, String name, String plate) => VehicleEntity(
  id: id,
  name: name,
  plateNumber: plate,
  brand: 'Toyota',
  model: 'Corolla',
  year: 2024,
  trackerId: id == 'cuervo' ? '123456789012345' : null,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
