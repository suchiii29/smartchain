import '../models/shipment.dart';
import '../models/route_condition.dart';

/// Service for managing logistics routes and shipment status across the network.
class RouteService {
  /// Returns the full list of active shipments in the system.
  List<Shipment> getActiveShipments() {
    return Shipment.getMockShipments();
  }

  /// Returns current environmental or logistical conditions affecting the network.
  List<RouteCondition> getCurrentConditions() {
    return RouteCondition.getMockConditions();
  }

  /// Returns a subset of shipments filtered by their current [status].
  List<Shipment> getShipmentsByStatus(String status) {
    return Shipment.getMockShipments()
        .where((s) => s.status == status)
        .toList();
  }

  /// Returns a statistical summary map of the current state of all shipments.
  Map<String, dynamic> getNetworkSummary() {
    final all = Shipment.getMockShipments();
    final onTime = all.where((s) => s.status == 'on_time').length;
    final delayed = all.where((s) => s.status == 'delayed').length;
    final critical = all.where((s) => s.status == 'critical').length;
    final avgDelay = all.isEmpty
        ? 0
        : all.map((s) => s.delayMinutes).reduce((a, b) => a + b) ~/
            all.length;

    return {
      'total': all.length,
      'onTime': onTime,
      'delayed': delayed,
      'critical': critical,
      'averageDelayMinutes': avgDelay,
      'onTimePercent':
          ((onTime / all.length) * 100).toStringAsFixed(1),
    };
  }

  /// Returns latitude and longitude coordinates for major Indian logistics hubs.
  Map<String, List<double>> getCityCoordinates() {
    return {
      'Mumbai': [19.07, 72.87],
      'Delhi': [28.67, 77.22],
      'Bengaluru': [12.97, 77.59],
      'Chennai': [13.08, 80.27],
      'Kolkata': [22.57, 88.36],
      'Hyderabad': [17.38, 78.48],
      'Pune': [18.52, 73.85],
      'Jaipur': [26.91, 75.78],
      'Ahmedabad': [23.02, 72.57],
    };
  }
}
