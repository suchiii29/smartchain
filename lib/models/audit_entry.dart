class AuditEntry {
  final String id;
  final DateTime timestamp;
  final String decisionType; // route_change, alert_generated, risk_updated
  final String aiModel; // "Gemini 1.5 Pro"
  final String inputSummary;
  final String outputDecision;
  final List<String> mcpToolsCalled;
  final double confidence;

  AuditEntry({
    required this.id,
    required this.timestamp,
    required this.decisionType,
    required this.aiModel,
    required this.inputSummary,
    required this.outputDecision,
    required this.mcpToolsCalled,
    required this.confidence,
  });
}
