import 'dart:convert';
import 'package:http/http.dart' as http;

/// A service to interact with the Google Gemini API for AI-powered delay predictions.
class AiService {
  static const String _apiKey = 'AIzaSyAhp4UwexN-ErV-SHXP1T-PUj_tXZdOS7c';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

  /// Predicts the delivery delay based on various route conditions using the Gemini API.
  ///
  /// Takes [origin], [destination], [trafficCondition], [weatherCondition], and [timeOfDay].
  /// Returns a structured JSON map containing:
  /// - riskScore (0-100)
  /// - riskLevel (Low/Medium/High/Critical)
  /// - predictedDelay (in hours)
  /// - reasons (List of strings)
  /// - suggestedAction (String)
  /// - alternativeRoute (String)
  ///
  /// In case of an API error or parsing failure, it gracefully returns fallback values.
  Future<Map<String, dynamic>> predictDelay({
    required String origin,
    required String destination,
    required String trafficCondition,
    required String weatherCondition,
    required String timeOfDay,
  }) async {
    final prompt = '''
You are an AI assistant for a supply chain app (SmartChain).
Please predict the delivery delay based on the following route and conditions.
Origin: $origin
Destination: $destination
Traffic Condition: $trafficCondition
Weather Condition: $weatherCondition
Time of Day: $timeOfDay

Return the response STRICTLY as a JSON object with the following fields:
- riskScore (number between 0-100)
- riskLevel (String: Low, Medium, High, Critical)
- predictedDelay (number: predicted delay in hours)
- reasons (List of strings explaining the delay)
- suggestedAction (String recommendation)
- alternativeRoute (String suggested alternative route)

Do not include any other text or formatting like markdown blocks. Just the raw JSON.
''';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
             'temperature': 0.2,
             'responseMimeType': 'application/json',
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String;
            final Map<String, dynamic> result = jsonDecode(text);
            return _fillDefaultsIfMissing(result);
          }
        }
      }
      return _fallbackPrediction();
    } catch (e) {
      // Handle errors gracefully by returning fallback values
      return _fallbackPrediction();
    }
  }

  /// Ensures all expected fields are present in the parsed response to avoid null errors.
  Map<String, dynamic> _fillDefaultsIfMissing(Map<String, dynamic> result) {
    return {
      'riskScore': result['riskScore'] ?? 0,
      'riskLevel': result['riskLevel'] ?? 'Low',
      'predictedDelay': result['predictedDelay'] ?? 0.0,
      'reasons': result['reasons'] is List 
          ? List<String>.from(result['reasons'])
          : ['No specific reasons analyzed'],
      'suggestedAction': result['suggestedAction'] ?? 'Proceed as planned',
      'alternativeRoute': result['alternativeRoute'] ?? 'No alternative route suggested',
    };
  }

  /// Provides fallback dummy values in case the API call fails or encounters an error.
  Map<String, dynamic> _fallbackPrediction() {
    return {
      'riskScore': 50,
      'riskLevel': 'Medium',
      'predictedDelay': 1.0,
      'reasons': ['Unable to connect to AI service', 'Using historical fallback data'],
      'suggestedAction': 'Monitor shipment closely',
      'alternativeRoute': 'Check local GPS for real-time alternatives',
    };
  }
}
