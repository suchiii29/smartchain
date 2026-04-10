class RouteCondition {
  final String conditionType;
  final String description;
  final String location;
  final String impactLevel;

  RouteCondition({
    required this.conditionType,
    required this.description,
    required this.location,
    required this.impactLevel,
  });

  static List<RouteCondition> getMockConditions() {
    return [
      RouteCondition(
        conditionType: 'Weather',
        description: 'Heavy rainfall warnings and potential waterlogging.',
        location: 'Western Ghats / Mumbai-Pune Expressway',
        impactLevel: 'High',
      ),
      RouteCondition(
        conditionType: 'Port Congestion',
        description: 'Vessel berthing delays due to increased inbound cargo volume.',
        location: 'Chennai Port',
        impactLevel: 'Medium',
      ),
      RouteCondition(
        conditionType: 'Traffic',
        description: 'Major highway closure due to road maintenance and accident clearance.',
        location: 'NH48 near Delhi-Jaipur route',
        impactLevel: 'Critical',
      ),
      RouteCondition(
        conditionType: 'Traffic',
        description: 'Border checkpoint delays.',
        location: 'Karnataka-Tamil Nadu border',
        impactLevel: 'Low',
      ),
      RouteCondition(
        conditionType: 'Customs',
        description: 'System outage causing clearance backlog.',
        location: 'JNPT Mumbai',
        impactLevel: 'High',
      ),
    ];
  }
}
