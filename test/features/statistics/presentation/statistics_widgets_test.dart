import 'package:dt_tracker_ai/core/theme/app_theme.dart';
import 'package:dt_tracker_ai/features/statistics/domain/entities/statistics.dart';
import 'package:dt_tracker_ai/features/statistics/presentation/bloc/statistics_bloc.dart';
import 'package:dt_tracker_ai/features/statistics/presentation/pages/daily_statistics_page.dart';
import 'package:dt_tracker_ai/features/statistics/presentation/pages/statistics_page.dart';
import 'package:dt_tracker_ai/features/vehicles/domain/entities/vehicle.dart';
import 'package:dt_tracker_ai/features/vehicles/presentation/cubit/selected_vehicle_cubit.dart';
import 'package:dt_tracker_ai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStatisticsBloc extends Mock implements StatisticsBloc {}

class _MockSelectedVehicleCubit extends Mock implements SelectedVehicleCubit {}

void main() {
  setUpAll(
    () => registerFallbackValue(
      StatisticsRequested(
        vehicle: null,
        from: DateTime.utc(2026, 10, 6),
        to: DateTime.utc(2026, 10, 12),
      ),
    ),
  );

  final vehicle = VehicleEntity(
    id: 'vehicle-1',
    name: 'Cuervo',
    plateNumber: 'NZY998A',
    trackerId: '123456789012345',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  final summary = StatisticsSummary(
    distanceKm: 120.5,
    averageDailyDistanceKm: 17.2,
    averageSpeedKmh: 42.4,
    maxSpeedKmh: 91,
    movingMinutes: 245,
  );
  final statistics = VehicleStatistics(
    vehicleId: vehicle.id,
    from: DateTime.utc(2026, 10, 6),
    to: DateTime.utc(2026, 10, 12),
    summary: summary,
    days: [DailyStatistics(date: DateTime.utc(2026, 10, 6), summary: summary)],
  );

  Widget subject(
    Widget child, {
    bool dark = false,
    TextScaler textScaler = TextScaler.noScaling,
  }) => MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
  );

  Widget withSelection(Widget child) {
    final cubit = _MockSelectedVehicleCubit();
    when(() => cubit.state).thenReturn(
      SelectedVehicleState(
        status: SelectedVehicleStatus.ready,
        vehicles: [vehicle],
        selectedVehicle: vehicle,
        userId: 'user-1',
      ),
    );
    when(
      () => cubit.stream,
    ).thenAnswer((_) => const Stream<SelectedVehicleState>.empty());
    return BlocProvider<SelectedVehicleCubit>.value(value: cubit, child: child);
  }

  testWidgets('weekly statistics renders real metric units in light mode', (
    tester,
  ) async {
    final bloc = _MockStatisticsBloc();
    final state = StatisticsState(
      status: StatisticsStatus.loaded,
      vehicles: [vehicle],
      selectedVehicle: vehicle,
      from: statistics.from,
      to: statistics.to,
      statistics: statistics,
    );
    when(() => bloc.state).thenReturn(state);
    when(() => bloc.stream).thenAnswer((_) => Stream<StatisticsState>.empty());
    when(() => bloc.add(any())).thenReturn(null);

    await tester.pumpWidget(
      BlocProvider<StatisticsBloc>.value(
        value: bloc,
        child: withSelection(subject(const StatisticsPage())),
      ),
    );

    expect(find.text('120.5 km'), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('42.4 km/h'), 300);
    expect(find.text('42.4 km/h'), findsOneWidget);
  });

  testWidgets(
    'speed chart supports empty data and touch selection in dark mode',
    (tester) async {
      await tester.pumpWidget(
        subject(const DTSpeedChart(samples: []), dark: true),
      );
      expect(find.text('No speed records.'), findsOneWidget);

      await tester.pumpWidget(
        subject(
          DTSpeedChart(
            samples: [
              SpeedSample(timestamp: DateTime.utc(2026, 10, 12), speedKmh: 10),
              SpeedSample(
                timestamp: DateTime.utc(2026, 10, 12, 12),
                speedKmh: 80,
              ),
            ],
          ),
          dark: true,
        ),
      );
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(find.textContaining('km/h'), findsWidgets);
    },
  );

  testWidgets(
    'metric tiles do not overflow on compact scaled light and dark layouts',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final bloc = _MockStatisticsBloc();
      final state = StatisticsState(
        status: StatisticsStatus.loaded,
        vehicles: [vehicle],
        selectedVehicle: vehicle,
        from: statistics.from,
        to: statistics.to,
        statistics: VehicleStatistics(
          vehicleId: vehicle.id,
          from: statistics.from,
          to: statistics.to,
          summary: const StatisticsSummary(
            distanceKm: 99999.9,
            averageDailyDistanceKm: 99999.9,
            averageSpeedKmh: 999.9,
            maxSpeedKmh: 999,
            movingMinutes: 99999,
          ),
          days: statistics.days,
        ),
      );
      when(() => bloc.state).thenReturn(state);
      when(
        () => bloc.stream,
      ).thenAnswer((_) => Stream<StatisticsState>.empty());
      when(() => bloc.add(any())).thenReturn(null);

      await tester.pumpWidget(
        BlocProvider<StatisticsBloc>.value(
          value: bloc,
          child: withSelection(
            subject(
              const StatisticsPage(),
              textScaler: const TextScaler.linear(1.3),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        BlocProvider<StatisticsBloc>.value(
          value: bloc,
          child: withSelection(
            subject(
              const StatisticsPage(),
              dark: true,
              textScaler: const TextScaler.linear(1.3),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  test('speed chart uses stable readable upper bounds', () {
    expect(SpeedChartAxis.upperBound(0), 40);
    expect(SpeedChartAxis.upperBound(83), 120);
  });
}
