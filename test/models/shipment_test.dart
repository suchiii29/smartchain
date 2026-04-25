import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_web/models/shipment.dart';

void main() {
  group('Shipment Model Tests', () {
    test('getMockShipments should return exactly 8 shipments', () {
      final shipments = Shipment.getMockShipments();
      expect(shipments.length, 8);
    });

    test('toMap should contain all required fields', () {
      final shipment = Shipment.getMockShipments().first;
      final map = shipment.toMap();

      expect(map.containsKey('id'), true);
      expect(map.containsKey('origin'), true);
      expect(map.containsKey('destination'), true);
      expect(map.containsKey('status'), true);
      expect(map.containsKey('carrier'), true);
      expect(map.containsKey('cargoType'), true);
      expect(map.containsKey('eta'), true);
      expect(map.containsKey('delayMinutes'), true);
      expect(map.containsKey('carbonKg'), true);
      expect(map.containsKey('vehicleType'), true);
    });

    test('Shipment status should be valid', () {
      final shipments = Shipment.getMockShipments();
      final validStatuses = ['on_time', 'delayed', 'critical'];

      for (var shipment in shipments) {
        expect(validStatuses.contains(shipment.status), true, 
          reason: 'Shipment ${shipment.id} has invalid status: ${shipment.status}');
      }
    });
  });
}
