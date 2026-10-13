import 'package:dartz/dartz.dart';
import 'package:dt_tracker_ai/core/errors/failures.dart';
import 'package:dt_tracker_ai/core/theme/app_theme.dart';
import 'package:dt_tracker_ai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dt_tracker_ai/features/home/presentation/pages/home_dashboard_page.dart';
import 'package:dt_tracker_ai/features/vehicles/domain/repositories/vehicle_repository.dart';
import 'package:dt_tracker_ai/features/vehicles/domain/entities/vehicle.dart';
import 'package:dt_tracker_ai/features/vehicles/domain/usecases/get_vehicles.dart';
import 'package:dt_tracker_ai/injection_container.dart';
import 'package:dt_tracker_ai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends Mock implements AuthBloc {}

class _MockVehicleRepository extends Mock implements VehicleRepository {}

void main() {
  late _MockAuthBloc authBloc;
  late _MockVehicleRepository vehicleRepository;

  setUp(() async {
    await sl.reset();
    authBloc = _MockAuthBloc();
    vehicleRepository = _MockVehicleRepository();
    when(() => authBloc.state).thenReturn(AuthState.initial());
    when(
      () => authBloc.stream,
    ).thenAnswer((_) => Stream<AuthState>.value(AuthState.initial()));
    when(
      () => vehicleRepository.getVehicles(),
    ).thenAnswer((_) async => const Right<Failure, List<VehicleEntity>>([]));
    sl.registerLazySingleton<GetVehicles>(() => GetVehicles(vehicleRepository));
  });

  tearDown(() async => sl.reset());

  testWidgets('shows the approved empty vehicle state when no vehicles exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeDashboardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add Vehicle'), findsOneWidget);
  });
}
