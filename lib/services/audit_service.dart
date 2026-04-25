import '../models/audit_entry.dart';

class AuditService {
  static final List<AuditEntry> _entries = [];

  static void addEntry({
    required String decisionType,
    required String inputSummary,
    required String outputDecision,
    required List<String> mcpToolsCalled,
    required double confidence,
  }) {
    final entry = AuditEntry(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      decisionType: decisionType,
      aiModel: 'Gemini 1.5 Pro',
      inputSummary: inputSummary,
      outputDecision: outputDecision,
      mcpToolsCalled: mcpToolsCalled,
      confidence: confidence,
    );
    _entries.insert(0, entry);
  }

  static List<AuditEntry> get entries => List.from(_entries);
  static int get count => _entries.length;
  static void clear() => _entries.clear();
}
