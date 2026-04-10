import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/disruption_alert.dart';
import 'mcp_service.dart';

class AiService {
  static const _apiKey = 'YOUR_KEY';
  static const _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=\$_apiKey';

  Future<List<DisruptionAlert>> analyzeDisruptions({
    required List<Map<String, dynamic>> shipments,
    required List<String> conditions,
  }) async {
    try {
      // 1. Fetch live conditions from MCP
      final liveConditions = await McpService.getSupplyChainConditions();
      
      // 2. Merge conditions
      final allConditions = [...conditions, ...liveConditions];

      // 3. Update prompt with MCP context
      final prompt = '''
You are a supply chain risk AI. Return ONLY a valid JSON array of disruption alerts based on the following data. No markdown fences.
These conditions are live data fetched via MCP supply chain tools:
Conditions: \${jsonEncode(allConditions)}

Shipments: \${jsonEncode(shipments)}

The JSON array should contain objects with keys: id, type, severity, affectedRoute, predictedDelayMinutes, recommendedAction, confidence.
''';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': 'You are a supply chain risk AI. Return ONLY valid JSON array, no markdown.'}
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
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var text = data['candidates'][0]['content']['parts'][0]['text'] as String;
        
        text = text.trim();
        if (text.startsWith('```json')) {
          text = text.substring(7);
        }
        if (text.endsWith('```')) {
          text = text.substring(0, text.length - 3);
        }
        text = text.trim();

        final List<dynamic> jsonList = jsonDecode(text);
        final alerts = jsonList.map((e) => DisruptionAlert.fromMap(e as Map<String, dynamic>)).toList();

        // 4. Send critical alerts back to MCP
        for (final alert in alerts) {
          if (alert.severity == 'critical') {
            await McpService.sendAlert(alert.toMap());
          }
        }

        return alerts;
      } else {
        throw Exception('Failed to communicate with Gemini API: \${response.statusCode}');
      }
    } catch (e) {
      print('Error in analyzeDisruptions: \$e');
      return _getFallbackAlerts();
    }
  }

  Future<String> getRouteOptimization({
    required String origin,
    required String destination,
    required String disruptionType,
  }) async {
    try {
      final prompt = 'We have a \$disruptionType disruption between \$origin and \$destination. Provide 3 bullet point rerouting recommendations.';
      
      final response = await http.post(
        Uri.parse(_apiUrl),
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
}
