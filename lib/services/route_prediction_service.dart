import '../services/ai_service.dart';
import '../services/weather_service.dart';
import '../services/ml_service.dart';

class RoutePredictionService {
  static final List<Map<String,dynamic>> _monitoredRoutes = [
    {
      'route': 'Mumbai→Bengaluru',
      'waypoints': [
        {'city': 'Mumbai', 'lat': 19.07, 'lng': 72.87},
        {'city': 'Pune', 'lat': 18.52, 'lng': 73.85},
        {'city': 'Kolhapur', 'lat': 16.70, 'lng': 74.24},
        {'city': 'Bengaluru', 'lat': 12.97, 'lng': 77.59},
      ],
      'currentStatus': 'on_route',
      'predictedDisruption': null,
    },
  ];
  
  // Check all routes for potential disruptions
  static Future<List<Map<String,dynamic>>> checkRouteRisks() async {
    List<Map<String,dynamic>> risks = [];
    
    for (var route in _monitoredRoutes) {
      // Get real weather for next waypoint
      final weather = await WeatherService.getRouteWeather(
        route['waypoints'][0]['city'],
        route['waypoints'][1]['city'],
      );
      
      // ML model predicts if route will be blocked
      final mlPrediction = await MlService.predictDelay(
        route: route['route'],
        distanceKm: 1200,
        weatherScore: weather['weather_score'],
        trafficScore: 5.0,
      );
      
      // If high risk, flag it
      if (mlPrediction['risk_level'] == 'high' || 
          mlPrediction['risk_level'] == 'critical') {
        risks.add({
          'route': route['route'],
          'reason': 'Weather disruption predicted',
          'severity': mlPrediction['risk_level'],
          'predictedDelay': mlPrediction['predicted_delay_minutes'],
          'alternativeRoute': await _getAlternativeRoute(route['route']),
          'timeToDisruption': '45 mins ahead',
        });
      }
    }
    
    return risks;
  }
  
  static Future<String> _getAlternativeRoute(String route) async {
    final parts = route.split('→');
    final origin = parts[0].trim();
    final destination = parts.length > 1 ? parts[1].trim() : '';

    // Call Gemini AI for alternative route
    final suggestion = await AiService().getRouteOptimization(
      origin: origin,
      destination: destination,
      disruptionType: 'weather_blockage',
    );
    return suggestion;
  }
}
