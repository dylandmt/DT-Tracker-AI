import 'package:dt_tracker_ai/features/map/presentation/utils/map_panel_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('opening the vehicle list suppresses selected vehicle details', () {
    final coordinator = MapPanelCoordinator();

    coordinator.openVehicleList();

    expect(coordinator.vehicleListVisible, isTrue);
    expect(coordinator.shouldShowVehicleSheet(true), isFalse);
  });

  test(
    'closing the vehicle list without selection keeps details suppressed',
    () {
      final coordinator = MapPanelCoordinator()..openVehicleList();

      coordinator.closeVehicleList();

      expect(coordinator.vehicleListVisible, isFalse);
      expect(coordinator.shouldShowVehicleSheet(true), isFalse);
    },
  );

  test('selecting from the list closes it and restores details', () {
    final coordinator = MapPanelCoordinator()..openVehicleList();

    coordinator.selectVehicle();

    expect(coordinator.vehicleListVisible, isFalse);
    expect(coordinator.shouldShowVehicleSheet(true), isTrue);
  });

  test('selecting a marker closes a visible list and restores details', () {
    final coordinator = MapPanelCoordinator()..openVehicleList();

    coordinator.selectMarker();

    expect(coordinator.vehicleListVisible, isFalse);
    expect(coordinator.shouldShowVehicleSheet(true), isTrue);
  });
}
