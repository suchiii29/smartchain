class Shipment {
  final String id;
  final String origin;
  final String destination;
  final String status; // on_time/delayed/critical
  final String carrier;
  final String cargoType;
  final DateTime eta;
  final int delayMinutes;
  final double carbonKg;
  final String vehicleType;

  Shipment({
    required this.id,
    required this.origin,
    required this.destination,
    required this.status,
    required this.carrier,
    required this.cargoType,
    required this.eta,
    required this.delayMinutes,
    required this.carbonKg,
    required this.vehicleType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'origin': origin,
      'destination': destination,
      'status': status,
      'carrier': carrier,
      'cargoType': cargoType,
      'eta': eta.toIso8601String(),
      'delayMinutes': delayMinutes,
      'carbonKg': carbonKg,
      'vehicleType': vehicleType,
    };
  }

  static List<Shipment> getMockShipments() {
    final now = DateTime.now();
    return [
      Shipment(
        id: 'SHP-001',
        origin: 'Mumbai',
        destination: 'Bengaluru',
        status: 'critical',
        carrier: 'BlueDart Logistics',
        cargoType: 'Electronics',
        eta: now.add(const Duration(days: 1, hours: 2)),
        delayMinutes: 150,
        carbonKg: 180.0,
        vehicleType: 'truck',
      ),
      Shipment(
        id: 'SHP-002',
        origin: 'Chennai',
        destination: 'Delhi',
        status: 'delayed',
        carrier: 'Safexpress',
        cargoType: 'Pharmaceuticals',
        eta: now.add(const Duration(days: 2, hours: 5)),
        delayMinutes: 60,
        carbonKg: 105.0,
        vehicleType: 'rail',
      ),
      Shipment(
        id: 'SHP-003',
        origin: 'Kolkata',
        destination: 'Hyderabad',
        status: 'on_time',
        carrier: 'Delhivery',
        cargoType: 'Textiles',
        eta: now.add(const Duration(days: 1, hours: 14)),
        delayMinutes: 0,
        carbonKg: 210.0,
        vehicleType: 'truck',
      ),
      Shipment(
        id: 'SHP-004',
        origin: 'Delhi',
        destination: 'Jaipur',
        status: 'delayed',
        carrier: 'FedEx India',
        cargoType: 'FMCG',
        eta: now.add(const Duration(hours: 12)),
        delayMinutes: 45,
        carbonKg: 87.0,
        vehicleType: 'truck',
      ),
      Shipment(
        id: 'SHP-005',
        origin: 'Pune',
        destination: 'Ahmedabad',
        status: 'on_time',
        carrier: 'TCI Express',
        cargoType: 'Auto Parts',
        eta: now.add(const Duration(days: 1)),
        delayMinutes: 0,
        carbonKg: 32.5,
        vehicleType: 'rail',
      ),
      Shipment(
        id: 'SHP-006',
        origin: 'Bengaluru',
        destination: 'Chennai',
        status: 'critical',
        carrier: 'VRL Logistics',
        cargoType: 'Semiconductors',
        eta: now.add(const Duration(hours: 8)),
        delayMinutes: 200,
        carbonKg: 540.0,
        vehicleType: 'air',
      ),
      Shipment(
        id: 'SHP-007',
        origin: 'Ahmedabad',
        destination: 'Mumbai',
        status: 'on_time',
        carrier: 'Bluedart Logistics',
        cargoType: 'Chemicals',
        eta: now.add(const Duration(hours: 10)),
        delayMinutes: 0,
        carbonKg: 138.0,
        vehicleType: 'truck',
      ),
      Shipment(
        id: 'SHP-008',
        origin: 'Hyderabad',
        destination: 'Kolkata',
        status: 'delayed',
        carrier: 'Safexpress',
        cargoType: 'Medical Equipment',
        eta: now.add(const Duration(days: 2, hours: 1)),
        delayMinutes: 90,
        carbonKg: 72.0,
        vehicleType: 'rail',
      ),
    ];
  }
}
