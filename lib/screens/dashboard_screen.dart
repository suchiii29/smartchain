import 'package:flutter/material.dart';
import '../models/shipment.dart';
import '../models/disruption_alert.dart';
import '../services/ai_service.dart';
import '../services/mcp_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AiService _aiService = AiService();
  bool _isLoading = false;
  bool _mcpConnected = false;
  List<DisruptionAlert> _alerts = [];
  List<Shipment> _shipments = [];

  @override
  void initState() {
    super.initState();
    _shipments = Shipment.getMockShipments();
    _checkMcp();
  }

  Future<void> _checkMcp() async {
    final connected = await McpService.checkConnection();
    if (mounted) {
      setState(() {
        _mcpConnected = connected;
      });
    }
  }

  Future<void> _runAiAnalysis() async {
    setState(() {
      _isLoading = true;
      _alerts = [];
    });

    final alerts = await _aiService.analyzeDisruptions(
      shipments: _shipments.map((e) => e.toMap()).toList(),
      conditions: [], // Live conditions fetched inside AiService via MCP
    );

    if (mounted) {
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    }
  }

  void _showAlertDetails(DisruptionAlert alert) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      isScrollControlled: true,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final parts = alert.affectedRoute.split('->');
    final origin = parts.isNotEmpty ? parts[0].trim() : 'Origin';
    final destination = parts.length > 1 ? parts[1].trim() : 'Destination';

    final optimizationText = await _aiService.getRouteOptimization(
      origin: origin,
      destination: destination,
      disruptionType: alert.type,
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading spinner

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
               Text('Alert: ${alert.id}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
               const SizedBox(height: 10),
               Text('Type: ${alert.type.toUpperCase()}', style: const TextStyle(color: Colors.white70)),
               Text('Severity: ${alert.severity.toUpperCase()}', style: TextStyle(color: _getSeverityColor(alert.severity), fontWeight: FontWeight.bold)),
               Text('Predicted Delay: ${alert.predictedDelayMinutes} mins', style: const TextStyle(color: Colors.orange)),
               const SizedBox(height: 20),
               const Text('🤖 AI Route Optimization:', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
               const SizedBox(height: 10),
               Text(optimizationText, style: const TextStyle(color: Colors.white70)),
               const SizedBox(height: 20),
            ],
          ),
        );
      }
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.amber;
      case 'low': return Colors.green;
      default: return Colors.blue;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'on_time': return Colors.green;
      case 'delayed': return Colors.orange;
      case 'critical': return Colors.red;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final delayedCount = _shipments.where((s) => s.status != 'on_time').length;
    final avgDelay = _shipments.isEmpty ? 0 : 
      _shipments.map((s) => s.delayMinutes).reduce((a, b) => a + b) / _shipments.length;
    final onTimePercentage = _shipments.isEmpty ? 0 : 
      ((_shipments.length - delayedCount) / _shipments.length * 100);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F2E),
        title: const Row(
          children: [
            Icon(Icons.local_shipping, color: Colors.blue),
            SizedBox(width: 8),
            Text('SmartChain AI', style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _mcpConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _mcpConnected ? Colors.green : Colors.red),
              ),
              child: Row(
                children: [
                  Text('MCP', style: TextStyle(color: _mcpConnected ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(width: 4),
                  Icon(_mcpConnected ? Icons.circle : Icons.circle_outlined, color: _mcpConnected ? Colors.green : Colors.red, size: 10),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _runAiAnalysis,
              icon: _isLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Icon(Icons.analytics, color: Colors.white),
              label: const Text('Run AI Analysis', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Cards row
            Row(
              children: [
                Expanded(child: _buildKpiCard('Total Shipments', _shipments.length.toString(), Icons.inventory, Colors.blue)),
                const SizedBox(width: 10),
                Expanded(child: _buildKpiCard('On-Time %', '$onTimePercentage%', Icons.check_circle, Colors.green)),
                const SizedBox(width: 10),
                Expanded(child: _buildKpiCard('Active Alerts', _alerts.length.toString(), Icons.warning, Colors.orange)),
                const SizedBox(width: 10),
                Expanded(child: _buildKpiCard('Avg Delay', '$avgDelay m', Icons.timer, Colors.red)),
              ],
            ),
            const SizedBox(height: 30),

            // AI Alerts Section
            if (_isLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Analyzing supply chain risks via MCP & Gemini...", style: TextStyle(color: Colors.white70))
                    ],
                  ),
                ),
              )
            ] else if (_alerts.isNotEmpty) ...[
              const Text('🤖 AI Disruption Alerts', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _alerts.length,
                itemBuilder: (ctx, i) {
                  final alert = _alerts[i];
                  return Card(
                    color: const Color(0xFF1A1F2E),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      onTap: () => _showAlertDetails(alert),
                      leading: CircleAvatar(
                        backgroundColor: _getSeverityColor(alert.severity).withOpacity(0.2),
                        child: Icon(Icons.warning, color: _getSeverityColor(alert.severity)),
                      ),
                      title: Text(alert.affectedRoute, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(alert.recommendedAction, style: const TextStyle(color: Colors.white70)),
                      trailing: Text('+${alert.predictedDelayMinutes}m', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],

            // Active Shipments Table
            const Text('📦 Active Shipments', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _shipments.length,
                separatorBuilder: (ctx, i) => const Divider(color: Colors.white10, height: 1),
                itemBuilder: (ctx, i) {
                  final shipment = _shipments[i];
                  final color = _getStatusColor(shipment.status);
                  return ListTile(
                    title: Text('${shipment.origin} → ${shipment.destination}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    subtitle: Row(
                      children: [
                        Text(shipment.id, style: const TextStyle(fontFamily: 'monospace', color: Colors.white54, fontSize: 12)),
                        const SizedBox(width: 8),
                        Text('• ${shipment.cargoType}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(shipment.status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
