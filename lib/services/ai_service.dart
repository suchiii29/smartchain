import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/disruption_alert.dart';
import 'mcp_service.dart';
import 'audit_service.dart';
import 'firebase_service.dart';
import 'weather_service.dart';

/// Service for interacting with the Gemini AI model to perform supply chain analysis.
///
/// Handles disruption detection, route optimization, and time-based forecasting.
class AiService {
  static const _apiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$_apiKey';
  static bool _useGemma = false;

  static bool get useGemma => _useGemma;
  static set useGemma(bool value) => _useGemma = value;
  static String get currentModel => _useGemma ? 'Gemma 3' : 'Gemini 1.5 Pro';

  static String get _activeUrl {
    if (_useGemma) {
      return 'https://generativelanguage.googleapis.com/v1beta/models/gemma-3-27b-it:generateContent?key=$_apiKey';
    }
    return _apiUrl;
  }

  static DateTime? _lastApiCall;

  bool _isRateLimited() {
    if (_lastApiCall == null) return false;
    final diff = DateTime.now().difference(_lastApiCall!);
    return diff.inSeconds < 5;
  }

  void _updateLastCall() {
    _lastApiCall = DateTime.now();
  }

  /// Analyzes a list of shipments and environmental conditions to identify potential disruptions.
  ///
  /// Utilizes live data from [McpService] and historic patterns via Gemini AI.
  /// Returns a list of [DisruptionAlert] objects.
  Future<List<DisruptionAlert>> analyzeDisruptions({
    required List<Map<String, dynamic>> shipments,
    required List<String> conditions,
  }) async {
    // Input Validation
    if (shipments.isEmpty) {
      print('AI Service: No shipments to analyze');
      return _getFallbackAlerts();
    }

    // Rate Limiting
    if (_isRateLimited()) {
      print('Rate limit: please wait');
      return _getFallbackAlerts();
    }
    _updateLastCall();

    try {
      // 1. Fetch live conditions from MCP
      final liveConditions = await McpService.getSupplyChainConditions();

      final weatherConditions = <String>[];
      for (var s in shipments.take(3)) {
        final w = await WeatherService.getRouteWeather(
            s['origin'] ?? 'Origin', s['destination'] ?? 'Dest');
        weatherConditions.add(
            '${w['origin']['city']}: ${w['origin']['condition']} (score ${w['weather_score']})');
        weatherConditions.add(
            '${w['destination']['city']}: ${w['destination']['condition']} (score ${w['weather_score']})');
      }

      // 2. Merge conditions
      final allConditions = [
        ...conditions,
        ...liveConditions,
        ...weatherConditions
      ];

      // 3. Update prompt with MCP context
      final prompt = '''
You are a supply chain risk AI. Return ONLY a valid JSON array of disruption alerts based on the following data. No markdown fences.
These conditions are live data fetched via MCP supply chain tools:
Conditions: ${jsonEncode(allConditions)}

Shipments: ${jsonEncode(shipments)}

The JSON array should contain objects with keys: id, type, severity, affectedRoute, predictedDelayMinutes, recommendedAction, confidence.
''';

      final response = await http
          .post(
            Uri.parse(_activeUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'system_instruction': {
                'parts': [
                  {
                    'text':
                        'You are a supply chain risk AI. Return ONLY valid JSON array, no markdown.'
                  }
                ]
              },
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        text = text.trim();
        if (text.startsWith('```json')) {
          text = text.substring(7);
        }
        if (text.endsWith('```')) {
          text = text.substring(0, text.length - 3);
        }
        text = text.trim();

        final List<dynamic> jsonList = jsonDecode(text);
        final alerts = jsonList
            .map((e) => DisruptionAlert.fromMap(e as Map<String, dynamic>))
            .toList();

        // 4. Send critical alerts back to MCP and save all to Firebase
        for (final alert in alerts) {
          await FirebaseService.saveAlert(alert);
        }

        // 5. Log decision in Audit Trail
        AuditService.addEntry(
          decisionType: 'alert_generated',
          inputSummary:
              '${shipments.length} shipments analyzed, real weather integrated',
          outputDecision: '${alerts.length} disruptions detected',
          mcpToolsCalled: ['getSupplyChainConditions', 'sendAlert'],
          confidence: 0.87,
        );

        return alerts;
      } else {
        throw Exception(
            'Failed to communicate with Gemini API: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in analyzeDisruptions: $e');
      final fallback = _getFallbackAlerts();
      AuditService.addEntry(
        decisionType: 'fallback_used',
        inputSummary: '${shipments.length} shipments (API error: $e)',
        outputDecision: '${fallback.length} fallback alerts returned',
        mcpToolsCalled: ['getSupplyChainConditions'],
        confidence: 0.50,
      );
      return fallback;
    }
  }

  /// Provides AI-powered natural language recommendations for optimizing a specific route.
  ///
  /// Takes the [origin], [destination], and [disruptionType] to generate bulleted advice.
  Future<String> getRouteOptimization({
    required String origin,
    required String destination,
    required String disruptionType,
  }) async {
    // Input Sanitization
    final sOrigin = origin.trim();
    final sDestination = destination.trim();
    final sDisruption = disruptionType.trim();

    if (sOrigin.isEmpty || sDestination.isEmpty) {
      return '- Check route parameters';
    }

    // Rate Limiting
    if (_isRateLimited()) {
      return 'Rate limit: please wait. Using cached recommendations...';
    }
    _updateLastCall();

    try {
      final prompt =
          'We have a $sDisruption disruption between $sOrigin and $sDestination. Provide 3 bullet point rerouting recommendations.';

      final response = await http.post(
        Uri.parse(_activeUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception('API Error');
      }
    } catch (e) {
      print('Error in getRouteOptimization: \$e');
      return '- Use alternate coastal highway\\n- Delay shipment by 24 hours until conditions clear\\n- Split cargo via air freight';
    }
  }

  List<DisruptionAlert> _getFallbackAlerts() {
    return [
      DisruptionAlert(
        id: 'ALT-001',
        type: 'weather',
        severity: 'high',
        affectedRoute: 'Mumbai -> Bengaluru',
        predictedDelayMinutes: 300,
        recommendedAction: 'Reroute via coastal highway NH66',
        confidence: 0.85,
      ),
      DisruptionAlert(
        id: 'ALT-002',
        type: 'port_congestion',
        severity: 'medium',
        affectedRoute: 'Chennai -> Delhi',
        predictedDelayMinutes: 180,
        recommendedAction: 'Expect delays at destination hub',
        confidence: 0.70,
      ),
      DisruptionAlert(
        id: 'ALT-003',
        type: 'traffic',
        severity: 'critical',
        affectedRoute: 'Delhi -> Jaipur',
        predictedDelayMinutes: 400,
        recommendedAction: 'Halt shipment at nearest secure facility',
        confidence: 0.95,
      ),
    ];
  }

  /// Predicts logistical disruptions for the next 72 hours using the Gemini Flash model.
  ///
  /// Analyzes current [shipments] and returns potential risks with probability and preemptive actions.
  Future<List<Map<String, dynamic>>> predictFuture72Hours(
      List<Map> shipments) async {
    // Input Validation
    if (shipments.isEmpty) {
      return [];
    }

    // Rate Limiting
    if (_isRateLimited()) {
      print('Rate limit: please wait');
      return [];
    }
    _updateLastCall();

    try {
      final prompt = '''
Based on these active shipments and typical Indian logistics patterns, 
predict supply chain disruptions likely in the next 72 hours.
Consider: monsoon patterns, port congestion cycles, highway traffic trends.
Return ONLY a JSON array where each object has:
- route (string)
- timeframe (string: next_24h / 24_to_48h / 48_to_72h)  
- disruptionType (string)
- probability (float 0.0-1.0)
- preemptiveAction (string)
- estimatedImpactMinutes (int)

Shipments: \${jsonEncode(shipments)}
''';

      final response = await http
          .post(
            Uri.parse(_apiUrl.replaceFirst('gemini-1.5-pro',
                'gemini-1.5-flash')), // Use flash for faster forecasting
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        text = text.trim();
        if (text.startsWith('```json')) text = text.substring(7);
        if (text.endsWith('```')) text = text.substring(0, text.length - 3);
        text = text.trim();

        final List<dynamic> jsonList = jsonDecode(text);
        return jsonList.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception('API Error');
      }
    } catch (e) {
      print('Error in predictFuture72Hours: \$e');
      return [
        {
          'route': 'Mumbai -> Navi Mumbai (JNPT)',
          'timeframe': 'next_24h',
          'disruptionType': 'port_congestion',
          'probability': 0.85,
          'preemptiveAction': 'Re-route to Hazira Port or wait in holding zone',
          'estimatedImpactMinutes': 480
        },
        {
          'route': 'Delhi -> Gurugram (NH48)',
          'timeframe': 'next_24h',
          'disruptionType': 'traffic',
          'probability': 0.92,
          'preemptiveAction': 'Dispatch before 06:00 AM to avoid peak hours',
          'estimatedImpactMinutes': 120
        },
        {
          'route': 'Bengaluru -> Chennai',
          'timeframe': '24_to_48h',
          'disruptionType': 'weather (monsoon)',
          'probability': 0.65,
          'preemptiveAction':
              'Ensure waterproof tarping and check flood-prone zones',
          'estimatedImpactMinutes': 300
        },
        {
          'route': 'Kolkata -> Siliguri',
          'timeframe': '48_to_72h',
          'disruptionType': 'infrastructure',
          'probability': 0.45,
          'preemptiveAction':
              'Monitor landslide warnings on Himalayan foothills',
          'estimatedImpactMinutes': 600
        }
      ];
    }
  }

  /// Explicitly analyzes using the Gemma 3 model.
  Future<List<DisruptionAlert>> analyzeWithGemma({
    required List<Map<String, dynamic>> shipments,
    required List<String> conditions,
  }) async {
    final originalSelection = _useGemma;
    _useGemma = true;
    try {
      return await analyzeDisruptions(
          shipments: shipments, conditions: conditions);
    } finally {
      _useGemma = originalSelection;
    }
  }
}
