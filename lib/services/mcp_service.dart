import 'dart:convert';
import 'package:http/http.dart' as http;

class McpService {
  static const _baseUrl = 'http://localhost:3001';
  static bool _isMcpConnected = false;

  static bool get isConnected => _isMcpConnected;

  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(Uri.parse('\$_baseUrl/conditions')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        _isMcpConnected = true;
        return true;
      }
    } catch (e) {
      // Ignored for connection check
    }
    _isMcpConnected = false;
    return false;
  }

  static Future<List<String>> getSupplyChainConditions() async {
    try {
      final response = await http.get(Uri.parse('\$_baseUrl/conditions')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e['description'] as String).toList();
      }
    } catch (e) {
      print('Error fetching MCP conditions: \$e');
    }
    
    // Fallback conditions
    return [
      'Heavy rainfall warning for Mumbai region affecting port operations.',
      'Partial highway closure on NH48 due to road maintenance.',
      'Customs clearance delays at Chennai port.',
    ];
  }

  static Future<void> sendAlert(Map<String, dynamic> alert) async {
    try {
      await http.post(
        Uri.parse('\$_baseUrl/alerts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(alert),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Silently ignore errors
    }
  }
}
