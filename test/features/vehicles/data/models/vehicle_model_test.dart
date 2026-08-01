import 'package:flutter_test/flutter_test.dart';
import 'package:dt_tracker_ai/features/vehicles/data/models/vehicle_model.dart';

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
}
