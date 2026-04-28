import '../models/shipment.dart';
import '../models/disruption_alert.dart';

class ShipmentStateService {
  // Shared shipments list across all portals
  static List<Shipment> _shipments = [];
  static List<DisruptionAlert> _activeAlerts = [];
  static String _driverCurrentRoute = 'Mumbai → Bengaluru';
  static bool _driverDeviating = false;
  static DateTime? _lastUpdated;
  
  // Initialize with mock data
  static void initialize() {
    if (_shipments.isEmpty) {
      _shipments = Shipment.getMockShipments();
      _lastUpdated = DateTime.now();
    }
  }
  
  // Getters
  static List<Shipment> get shipments => _shipments;
  static List<DisruptionAlert> get alerts => _activeAlerts;
  static bool get driverDeviating => _driverDeviating;
  static String get driverRoute => _driverCurrentRoute;
  
  // Update from any portal
  static void updateAlerts(List<DisruptionAlert> alerts) {
    _activeAlerts = alerts;
    _lastUpdated = DateTime.now();
  }
  
  static void setDriverDeviating(bool value, String route) {
    _driverDeviating = value;
    _driverCurrentRoute = route;
  }
  
  static void updateShipmentStatus(
    String id, String status) {
    final index = _shipments.indexWhere((s) => s.id == id);
    if (index != -1) {
      _shipments[index] = Shipment(
        id: _shipments[index].id,
        origin: _shipments[index].origin,
        destination: _shipments[index].destination,
        status: status,
        carrier: _shipments[index].carrier,
        cargoType: _shipments[index].cargoType,
        eta: _shipments[index].eta,
        delayMinutes: _shipments[index].delayMinutes,
        carbonKg: _shipments[index].carbonKg,
        vehicleType: _shipments[index].vehicleType,
      );
    }
  }
  
  // Manager gets notified when driver deviates
  static bool get hasManagerAlert => _driverDeviating;
  
  static String get managerAlertMessage => 
    _driverDeviating 
      ? '🚨 Driver deviated from $_driverCurrentRoute'
      : '';
}
