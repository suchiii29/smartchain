import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_web/models/disruption_alert.dart';

void main() {
  group('DisruptionAlert Model Tests', () {
    final sampleMap = {
      'id': 'ALT-001',
      'type': 'weather',
      'severity': 'high',
      'affectedRoute': 'Mumbai -> Bengaluru',
      'predictedDelayMinutes': 300,
      'recommendedAction': 'Reroute via coastal highway',
      'confidence': 0.85,
    };

    test('fromMap should correctly parse all fields', () {
      final alert = DisruptionAlert.fromMap(sampleMap);

      expect(alert.id, 'ALT-001');
      expect(alert.type, 'weather');
      expect(alert.severity, 'high');
      expect(alert.affectedRoute, 'Mumbai -> Bengaluru');
      expect(alert.predictedDelayMinutes, 300);
      expect(alert.recommendedAction, 'Reroute via coastal highway');
      expect(alert.confidence, 0.85);
    });

    test('toMap roundtrip should produce identical object', () {
      final alert1 = DisruptionAlert.fromMap(sampleMap);
      final map = alert1.toMap();
      final alert2 = DisruptionAlert.fromMap(map);

      expect(alert1.id, alert2.id);
      expect(alert1.type, alert2.type);
      expect(alert1.severity, alert2.severity);
      expect(alert1.affectedRoute, alert2.affectedRoute);
      expect(alert1.predictedDelayMinutes, alert2.predictedDelayMinutes);
      expect(alert1.recommendedAction, alert2.recommendedAction);
      expect(alert1.confidence, alert2.confidence);
    });

    test('severity should be valid', () {
      final validSeverities = ['low', 'medium', 'high', 'critical'];
      final alert = DisruptionAlert.fromMap(sampleMap);
      
      expect(validSeverities.contains(alert.severity.toLowerCase()), true);
    });
  });
}
