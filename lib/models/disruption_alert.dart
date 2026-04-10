class DisruptionAlert {
  final String id;
  final String type; // weather/traffic/port_congestion/customs/mechanical
  final String severity; // low/medium/high/critical
  final String affectedRoute;
  final int predictedDelayMinutes;
  final String recommendedAction;
  final double confidence;

  DisruptionAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.affectedRoute,
    required this.predictedDelayMinutes,
    required this.recommendedAction,
    required this.confidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'severity': severity,
      'affectedRoute': affectedRoute,
      'predictedDelayMinutes': predictedDelayMinutes,
      'recommendedAction': recommendedAction,
      'confidence': confidence,
    };
  }

  factory DisruptionAlert.fromMap(Map<String, dynamic> map) {
    return DisruptionAlert(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      severity: map['severity'] ?? '',
      affectedRoute: map['affectedRoute'] ?? '',
      predictedDelayMinutes: map['predictedDelayMinutes']?.toInt() ?? 0,
      recommendedAction: map['recommendedAction'] ?? '',
      confidence: map['confidence']?.toDouble() ?? 0.0,
    );
  }
}
