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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'decisionType': decisionType,
      'aiModel': aiModel,
      'inputSummary': inputSummary,
      'outputDecision': outputDecision,
      'mcpToolsCalled': mcpToolsCalled,
      'confidence': confidence,
    };
  }

  factory AuditEntry.fromMap(Map<String, dynamic> map) {
    return AuditEntry(
      id: map['id'] ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
      decisionType: map['decisionType'] ?? '',
      aiModel: map['aiModel'] ?? '',
      inputSummary: map['inputSummary'] ?? '',
      outputDecision: map['outputDecision'] ?? '',
      mcpToolsCalled: List<String>.from(map['mcpToolsCalled'] ?? []),
      confidence: (map['confidence'] ?? 0.0).toDouble(),
    );
  }
}
