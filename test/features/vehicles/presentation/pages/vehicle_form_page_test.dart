import 'package:dt_tracker_ai/core/permissions/permission_handler.dart';
import 'package:dt_tracker_ai/core/theme/app_theme.dart';
import 'package:dt_tracker_ai/features/vehicles/domain/entities/vehicle.dart';
import 'package:dt_tracker_ai/features/vehicles/presentation/bloc/vehicle_form_bloc.dart';
import 'package:dt_tracker_ai/features/vehicles/presentation/pages/vehicle_form_page.dart';
import 'package:dt_tracker_ai/features/vehicles/presentation/widgets/vehicle_image_picker.dart';
import 'package:dt_tracker_ai/injection_container.dart';
import 'package:dt_tracker_ai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockVehicleFormBloc extends Mock implements VehicleFormBloc {}

class _MockPermissionHandler extends Mock implements AppPermissionHandler {}

void main() {
  setUpAll(
    () => registerFallbackValue(
      const SubmitVehicleForm(name: '', plateNumber: ''),
    ),
  );

  setUp(() async {
    await sl.reset();
    sl.registerLazySingleton<AppPermissionHandler>(_MockPermissionHandler.new);
  });

  tearDown(() async => sl.reset());

  Widget subject(_MockVehicleFormBloc bloc, {String? vehicleId}) =>
      BlocProvider<VehicleFormBloc>.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: VehicleFormPage(vehicleId: vehicleId),
        ),
      );

  void stubBloc(_MockVehicleFormBloc bloc, VehicleFormState state) {
    when(() => bloc.state).thenReturn(state);
    when(() => bloc.stream).thenAnswer((_) => Stream<VehicleFormState>.empty());
    when(() => bloc.add(any())).thenReturn(null);
  }

  testWidgets('add vehicle shows information instead of a photo picker', (
    tester,
  ) async {
    final bloc = _MockVehicleFormBloc();
    stubBloc(bloc, VehicleFormState.initial());

    await tester.pumpWidget(subject(bloc));

    expect(find.text('Add Vehicle'), findsOneWidget);
    expect(
      find.text('You can add photos after creating the vehicle.'),
      findsOneWidget,
    );
    expect(find.byType(VehicleImagePicker), findsNothing);
    expect(find.text('Create Vehicle'), findsOneWidget);
  });

  testWidgets('edit vehicle shows its existing photo gallery', (tester) async {
    final bloc = _MockVehicleFormBloc();
    final vehicle = _vehicle(imageUrls: const ['pending-image']);
    final state = VehicleFormState(
      status: VehicleFormStatus.loaded,
      vehicle: vehicle,
      isEditing: true,
    );
    stubBloc(bloc, state);

    await tester.pumpWidget(subject(bloc, vehicleId: vehicle.id));

    expect(find.byType(VehicleImagePicker), findsOneWidget);
    expect(find.text('(1/5)'), findsOneWidget);
    expect(find.text('Add photo'), findsOneWidget);
  });

  testWidgets('edit vehicle gallery shows an empty photo state', (
    tester,
  ) async {
    final bloc = _MockVehicleFormBloc();
    final vehicle = _vehicle();
    final state = VehicleFormState(
      status: VehicleFormStatus.loaded,
      vehicle: vehicle,
      isEditing: true,
    );
    stubBloc(bloc, state);

    await tester.pumpWidget(subject(bloc, vehicleId: vehicle.id));

    expect(find.text('No photos yet'), findsOneWidget);
    expect(find.text('(0/5)'), findsOneWidget);
  });

  testWidgets(
    'photo gallery keeps an add slot disabled at the five photo limit',
    (tester) async {
      final bloc = _MockVehicleFormBloc();
      final vehicle = _vehicle(
        imageUrls: List<String>.generate(5, (index) => 'pending-$index'),
      );
      final state = VehicleFormState(
        status: VehicleFormStatus.loaded,
        vehicle: vehicle,
        isEditing: true,
      );
      stubBloc(bloc, state);

      await tester.pumpWidget(subject(bloc, vehicleId: vehicle.id));

      expect(find.text('(5/5)'), findsOneWidget);
      final addInk = find.ancestor(
        of: find.text('Add photo'),
        matching: find.byType(InkWell),
      );
      expect(tester.widget<InkWell>(addInk.first).onTap, isNull);
    },
  );
}

VehicleEntity _vehicle({List<String> imageUrls = const []}) => VehicleEntity(
  id: 'vehicle-1',
  name: 'Cuervo',
  plateNumber: 'NZY998A',
  imageUrls: imageUrls,
  trackerId: '123456789012345',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
