import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for interacting with the Model Context Protocol (MCP) server.
/// 
/// Facilitates communication with local supply chain tools and live condition monitoring.
class McpService {
  static const _baseUrl = 'http://localhost:3001';
  static bool _isMcpConnected = false;

  /// Returns whether the MCP server is currently reachable.
  static bool get isConnected => _isMcpConnected;

  /// Checks the connectivity to the MCP server.
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/conditions')).timeout(const Duration(seconds: 3));
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

  /// Fetches live supply chain conditions from the MCP server.
  /// 
  /// Returns a list of environmental and logistical descriptions.
  static Future<List<String>> getSupplyChainConditions() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/conditions')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e['description'] as String).toList();
      }
    } catch (e) {
      print('Error fetching MCP conditions: $e');
    }
    
    // Fallback conditions
    return [
      'Heavy rainfall warning for Mumbai region affecting port operations.',
      'Partial highway closure on NH48 due to road maintenance.',
      'Customs clearance delays at Chennai port.',
    ];
  }

  /// Sends a generated disruption alert back to the MCP server for external processing.
  static Future<void> sendAlert(Map<String, dynamic> alert) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/alerts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(alert),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Silently ignore errors
    }
  }

  static Future<List<Map<String,dynamic>>> getTrafficConditions() async {
    // In production this would call Google Traffic API
    // For prototype, returns realistic Indian traffic data
    return [
      {
        'highway': 'NH48',
        'location': 'Mumbai-Pune Expressway',
        'severity': 'high',
        'description': 'Heavy traffic near Khopoli - 45min delay',
        'affected_routes': ['Mumbai → Bengaluru', 'Mumbai → Pune'],
      },
      {
        'highway': 'NH44', 
        'location': 'Hyderabad outer ring road',
        'severity': 'medium',
        'description': 'Moderate congestion near Shamshabad',
        'affected_routes': ['Hyderabad → Bengaluru'],
      },
      {
        'highway': 'NH19',
        'location': 'Delhi-Agra Highway',
        'severity': 'low', 
        'description': 'Light traffic, normal flow',
        'affected_routes': ['Delhi → Jaipur'],
      },
    ];
  }
}
