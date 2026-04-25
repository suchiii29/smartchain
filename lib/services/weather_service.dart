import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class WeatherService {
  static const String _apiKey =
      'f85489cd6c9e05a3962635928d7a4cb2'; // Mock key for demo purposes
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Get weather for major Indian logistics cities
  static Future<Map<String, dynamic>> getRouteWeather(
      String origin, String destination) async {
    try {
      // Get origin weather
      final originResponse = await http.get(Uri.parse(
          '$_baseUrl/weather?q=$origin,IN&appid=$_apiKey&units=metric'));

      // Get destination weather
      final destResponse = await http.get(Uri.parse(
          '$_baseUrl/weather?q=$destination,IN&appid=$_apiKey&units=metric'));

      if (originResponse.statusCode == 200 && destResponse.statusCode == 200) {
        final originData = jsonDecode(originResponse.body);
        final destData = jsonDecode(destResponse.body);

        return {
          'origin': {
            'city': origin,
            'temp': originData['main']['temp'],
            'condition': originData['weather'][0]['main'],
            'description': originData['weather'][0]['description'],
            'humidity': originData['main']['humidity'],
            'wind_speed': originData['wind']['speed'],
            'is_severe': ['Rain', 'Thunderstorm', 'Snow', 'Fog']
                .contains(originData['weather'][0]['main']),
          },
          'destination': {
            'city': destination,
            'temp': destData['main']['temp'],
            'condition': destData['weather'][0]['main'],
            'description': destData['weather'][0]['description'],
            'humidity': destData['main']['humidity'],
            'wind_speed': destData['wind']['speed'],
            'is_severe': ['Rain', 'Thunderstorm', 'Snow', 'Fog']
                .contains(destData['weather'][0]['main']),
          },
          'weather_score': _calculateWeatherScore(originData, destData),
        };
      }
    } catch (e) {
      debugPrint('Weather API error: $e');
    }
    // Fallback mock data
    return {
      'origin': {
        'city': origin,
        'condition': 'Clear',
        'is_severe': false,
        'temp': 32.0,
        'description': 'clear sky'
      },
      'destination': {
        'city': destination,
        'condition': 'Clear',
        'is_severe': false,
        'temp': 30.0,
        'description': 'clear sky'
      },
      'weather_score': 3.0,
    };
  }

  static double _calculateWeatherScore(originData, destData) {
    double score = 0;
    for (final data in [originData, destData]) {
      final condition = data['weather'][0]['main'];
      if (condition == 'Thunderstorm')
        score += 4;
      else if (condition == 'Rain')
        score += 3;
      else if (condition == 'Fog')
        score += 2;
      else if (condition == 'Clouds') score += 1;
    }
    return score.clamp(0, 10);
  }

  static String getWeatherEmoji(String condition) {
    switch (condition) {
      case 'Rain':
        return '🌧️';
      case 'Thunderstorm':
        return '⛈️';
      case 'Clear':
        return '☀️';
      case 'Clouds':
        return '☁️';
      case 'Fog':
        return '🌫️';
      case 'Snow':
        return '❄️';
      default:
        return '🌤️';
    }
  }
}
