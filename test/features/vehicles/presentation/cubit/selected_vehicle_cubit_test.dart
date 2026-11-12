import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dt_tracker_ai/core/errors/failures.dart';
import 'package:dt_tracker_ai/core/usecases/usecase.dart';
import 'package:dt_tracker_ai/features/vehicles/domain/entities/vehicle.dart';
import 'package:dt_tracker_ai/features/vehicles/domain/usecases/watch_vehicles.dart';
import 'package:dt_tracker_ai/features/vehicles/presentation/cubit/selected_vehicle_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockWatchVehicles extends Mock implements WatchVehicles {}

class _MockPreferences extends Mock implements SharedPreferences {}

void main() {
  final vehicleA = _vehicle('a');
  final vehicleB = _vehicle('b');
  late _MockFirebaseAuth auth;
  late _MockWatchVehicles watchVehicles;
  late _MockPreferences preferences;
  late StreamController<User?> authEvents;
  late StreamController<Either<Failure, List<VehicleEntity>>> vehicleEvents;

  setUp(() {
    auth = _MockFirebaseAuth();
    watchVehicles = _MockWatchVehicles();
    preferences = _MockPreferences();
    authEvents = StreamController<User?>.broadcast();
    vehicleEvents =
        StreamController<Either<Failure, List<VehicleEntity>>>.broadcast();
    when(() => auth.currentUser).thenReturn(null);
    when(() => auth.authStateChanges()).thenAnswer((_) => authEvents.stream);
    when(
      () => watchVehicles(const NoParams()),
    ).thenAnswer((_) => vehicleEvents.stream);
    when(() => preferences.getString(any())).thenReturn(null);
    when(
      () => preferences.setString(any(), any()),
    ).thenAnswer((_) async => true);
    when(() => preferences.remove(any())).thenAnswer((_) async => true);
  });

  tearDown(() async {
    await authEvents.close();
    await vehicleEvents.close();
  });

  test(
    'restores by stable id and retains it when the list order changes',
    () async {
      final user = _user('user-a');
      when(
        () => preferences.getString('selected_vehicle_id_user-a'),
      ).thenReturn('b');
      final cubit = _cubit(auth, watchVehicles, preferences);
      authEvents.add(user);
      await _settle();
      vehicleEvents.add(Right([vehicleA, vehicleB]));
      await _settle();
      expect(cubit.state.selectedVehicle?.id, 'b');

      vehicleEvents.add(Right([vehicleB, vehicleA]));
      await _settle();
      expect(cubit.state.selectedVehicle?.id, 'b');
      await cubit.close();
    },
  );

  test(
    'uses and persists a valid fallback when the active vehicle disappears',
    () async {
      final cubit = _cubit(auth, watchVehicles, preferences);
      authEvents.add(_user('user-a'));
      await _settle();
      vehicleEvents.add(Right([vehicleA, vehicleB]));
      await _settle();
      clearInteractions(preferences);
      cubit.selectVehicle('b');
      vehicleEvents.add(Right([vehicleA]));
      await _settle();

      expect(cubit.state.selectedVehicle?.id, 'a');
      verify(
        () => preferences.setString('selected_vehicle_id_user-a', 'a'),
      ).called(1);
      await cubit.close();
    },
  );

  test('does not share active selection between authenticated users', () async {
    final cubit = _cubit(auth, watchVehicles, preferences);
    authEvents.add(_user('user-a'));
    await _settle();
    vehicleEvents.add(Right([vehicleA, vehicleB]));
    await _settle();
    cubit.selectVehicle('b');

    when(
      () => preferences.getString('selected_vehicle_id_user-b'),
    ).thenReturn('a');
    authEvents.add(_user('user-b'));
    await _settle();
    vehicleEvents.add(Right([vehicleA, vehicleB]));
    await _settle();
    expect(cubit.state.selectedVehicle?.id, 'a');
    await cubit.close();
  });
}

SelectedVehicleCubit _cubit(
  FirebaseAuth auth,
  WatchVehicles watchVehicles,
  SharedPreferences preferences,
) => SelectedVehicleCubit(
  firebaseAuth: auth,
  watchVehicles: watchVehicles,
  preferences: preferences,
);

_MockUser _user(String uid) {
  final user = _MockUser();
  when(() => user.uid).thenReturn(uid);
  return user;
}

VehicleEntity _vehicle(String id) => VehicleEntity(
  id: id,
  name: id,
  plateNumber: id,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);
