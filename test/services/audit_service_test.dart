import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_web/services/audit_service.dart';

void main() {
  group('AuditService Tests', () {
    test('addEntry should increase entries count and maintain order', () {
      final initialCount = AuditService.entries.length;
      
      AuditService.addEntry(
        decisionType: 'test_decision',
        inputSummary: 'test input',
        outputDecision: 'test output',
        mcpToolsCalled: ['tool1'],
        confidence: 0.99,
      );

      expect(AuditService.entries.length, initialCount + 1);
      expect(AuditService.entries.first.decisionType, 'test_decision');
    });

    test('entries should be in reverse chronological order', () {
      AuditService.addEntry(
        decisionType: 'older',
        inputSummary: '...',
        outputDecision: '...',
        mcpToolsCalled: [],
        confidence: 0.5,
      );
      
      final olderTimestamp = AuditService.entries.first.timestamp;

      // Wait a tiny bit or just add another
      AuditService.addEntry(
        decisionType: 'newer',
        inputSummary: '...',
        outputDecision: '...',
        mcpToolsCalled: [],
        confidence: 0.6,
      );

      expect(AuditService.entries.first.decisionType, 'newer');
      expect(AuditService.entries[1].decisionType, 'older');
      expect(AuditService.entries.first.timestamp.isAfter(olderTimestamp) || 
             AuditService.entries.first.timestamp.isAtSameMomentAs(olderTimestamp), true);
    });
  });
}
