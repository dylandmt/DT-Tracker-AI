import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dt_tracker_ai/core/errors/failures.dart';
import 'package:dt_tracker_ai/core/usecases/usecase.dart';
import 'package:dt_tracker_ai/features/vehicles/domain/usecases/delete_vehicle.dart';
import 'package:dt_tracker_ai/features/vehicles/domain/usecases/get_vehicles.dart';
import 'package:dt_tracker_ai/features/vehicles/domain/usecases/watch_vehicles.dart';
import 'package:dt_tracker_ai/features/vehicles/presentation/bloc/vehicles_bloc.dart';

class MockDeleteVehicle extends Mock implements DeleteVehicle {}

class MockGetVehicles extends Mock implements GetVehicles {}

class MockWatchVehicles extends Mock implements WatchVehicles {}

void main() {
  late MockDeleteVehicle deleteVehicle;
  late VehiclesBloc buildBloc;

  setUp(() {
    deleteVehicle = MockDeleteVehicle();
    buildBloc = VehiclesBloc(
      getVehicles: MockGetVehicles(),
      watchVehicles: MockWatchVehicles(),
      deleteVehicle: deleteVehicle,
    );
  });

  tearDown(() => buildBloc.close());

  blocTest<VehiclesBloc, VehiclesState>(
    'emits deleting then deleted when vehicle deletion succeeds',
    setUp: () {
      when(
        () => deleteVehicle(const IdParams(id: 'vehicle-1')),
      ).thenAnswer((_) async => const Right<Failure, void>(null));
    },
    build: () => buildBloc,
    act: (bloc) =>
        bloc.add(const DeleteVehicleRequested(vehicleId: 'vehicle-1')),
    expect: () => const [
      VehiclesState(status: VehiclesStatus.deleting, vehicles: []),
      VehiclesState(status: VehiclesStatus.deleted, vehicles: []),
    ],
    verify: (_) {
      verify(() => deleteVehicle(const IdParams(id: 'vehicle-1'))).called(1);
    },
  );

  blocTest<VehiclesBloc, VehiclesState>(
    'emits an error and keeps the detail page open when deletion fails',
    setUp: () {
      when(() => deleteVehicle(const IdParams(id: 'vehicle-1'))).thenAnswer(
        (_) async => const Left<Failure, void>(
          ServerFailure(message: 'Unable to unlink tracker'),
        ),
      );
    },
    build: () => buildBloc,
    act: (bloc) =>
        bloc.add(const DeleteVehicleRequested(vehicleId: 'vehicle-1')),
    expect: () => const [
      VehiclesState(status: VehiclesStatus.deleting, vehicles: []),
      VehiclesState(
        status: VehiclesStatus.error,
        vehicles: [],
        errorMessage: 'Unable to unlink tracker',
      ),
    ],
  );
}
