import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/disruption_alert.dart';
import '../models/audit_entry.dart';

class FirebaseService {
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  static Future<void> saveAlert(DisruptionAlert alert) async {
    try {
      await _db.child('alerts').push().set({
        'id': alert.id,
        'type': alert.type,
        'severity': alert.severity,
        'affectedRoute': alert.affectedRoute,
        'predictedDelayMinutes': alert.predictedDelayMinutes,
        'recommendedAction': alert.recommendedAction,
        'confidence': alert.confidence,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Firebase saveAlert error: $e');
    }
  }

  static Future<void> saveAuditEntry(AuditEntry entry) async {
    try {
      await _db.child('audit').push().set({
        'id': entry.id,
        'timestamp': entry.timestamp.toIso8601String(),
        'decisionType': entry.decisionType,
        'aiModel': entry.aiModel,
        'inputSummary': entry.inputSummary,
        'outputDecision': entry.outputDecision,
        'mcpToolsCalled': entry.mcpToolsCalled,
        'confidence': entry.confidence,
      });
    } catch (e) {
      debugPrint('Firebase saveAuditEntry error: $e');
    }
  }

  static Future<List<Map>> getRecentAlerts() async {
    try {
      final snapshot = await _db
          .child('alerts')
          .orderByChild('timestamp')
          .limitToLast(10)
          .get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data.values
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (e) {
      debugPrint('Firebase getRecentAlerts error: $e');
    }
    return [];
  }

  static Future<void> saveShipmentStatus(
      String shipmentId, String status) async {
    try {
      await _db.child('shipments/$shipmentId').update({
        'status': status,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Firebase saveShipmentStatus error: $e');
    }
  }

  static Future<void> saveShipmentUpdate(
      String shipmentId, String status, int delayMinutes) async {
    try {
      await _db.child('shipments').child(shipmentId).set({
        'status': status,
        'delayMinutes': delayMinutes,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Firebase error: $e');
    }
  }

  static Future<void> saveMlPrediction(
      String route, int predictedDelay, String riskLevel) async {
    try {
      await _db.child('ml_predictions').push().set({
        'route': route,
        'predictedDelayMinutes': predictedDelay,
        'riskLevel': riskLevel,
        'timestamp': DateTime.now().toIso8601String(),
        'model': 'RandomForestRegressor',
      });
    } catch (e) {
      debugPrint('Firebase error: $e');
    }
  }

  static Stream<DatabaseEvent> getAlertsStream() {
    return _db
        .child('alerts')
        .orderByChild('timestamp')
        .limitToLast(10)
        .onValue;
  }
}
