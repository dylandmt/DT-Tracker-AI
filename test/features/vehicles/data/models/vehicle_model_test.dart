import 'package:flutter_test/flutter_test.dart';
import 'package:dt_tracker_ai/features/vehicles/data/models/vehicle_model.dart';
import 'package:dt_tracker_ai/features/vehicles/domain/entities/vehicle.dart';

void main() {
  group('VehicleModel.toJson', () {
    test('omits unlinked tracker fields', () {
      final vehicle = VehicleModel.create(
        id: 'vehicle-id',
        name: 'Test vehicle',
        plateNumber: 'ABC-123',
      );

      final json = vehicle.toJson();

      expect(json, isNot(contains('trackerId')));
      expect(json, isNot(contains('trackerLinkedAt')));
    });

    test('omits tracker fields from updates', () {
      final vehicle = VehicleModel.create(
        id: 'vehicle-id',
        name: 'Test vehicle',
        plateNumber: 'ABC-123',
      );

      final json = vehicle.toUpdateJson();

      expect(json, isNot(contains('trackerId')));
      expect(json, isNot(contains('trackerLinkedAt')));
    });
  });

  group('VehicleModel.fromJson', () {
    test('reads development plan metadata when present', () {
      final vehicle = VehicleModel.fromJson({
        'name': 'Test vehicle',
        'plateNumber': 'ABC-123',
        'entitlement': {'tier': 'essential', 'grandfatheredGeofenceLimit': 3},
      }, 'vehicle-id');

      expect(vehicle.plan, VehiclePlan.essential);
      expect(vehicle.geofenceLimit, 3);
    });

    test('keeps plan metadata absent for existing vehicles', () {
      final vehicle = VehicleModel.fromJson({
        'name': 'Test vehicle',
        'plateNumber': 'ABC-123',
      }, 'vehicle-id');

      expect(vehicle.plan, isNull);
      expect(vehicle.geofenceLimit, isNull);
    });
  });
}
