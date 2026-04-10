import 'package:flutter/material.dart';
import '../models/disruption_alert.dart';
import '../models/shipment.dart';
import '../models/route_condition.dart';
import '../services/ai_service.dart';
import '../widgets/alert_card.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  _AlertsScreenState createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final AiService _aiService = AiService();
  List<DisruptionAlert> _alerts = [];
  bool _isLoading = false;
  String _filterSeverity = 'all';

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    final shipments = Shipment.getMockShipments();
    final conditions = RouteCondition.getMockConditions();
    final alerts = await _aiService.analyzeDisruptions(
      shipments: shipments.map((e) => e.toMap()).toList(),
      conditions: conditions.map((e) => e.description).toList(),
    );
    setState(() {
      _alerts = alerts;
      _isLoading = false;
    });
  }

  List<DisruptionAlert> get _filteredAlerts {
    if (_filterSeverity == 'all') return _alerts;
    return _alerts.where((a) => a.severity == _filterSeverity).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F2E),
        title: const Text('⚠️ Disruption Alerts', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAlerts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['all', 'critical', 'high', 'medium', 'low'].map((severity) {
                  final isSelected = _filterSeverity == severity;
                  final chipColor = _severityColor(severity);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        severity.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : chipColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _filterSeverity = severity),
                      backgroundColor: const Color(0xFF1A1F2E),
                      selectedColor: chipColor.withOpacity(0.3),
                      checkmarkColor: chipColor,
                      side: BorderSide(color: isSelected ? chipColor : Colors.white12),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Fetching AI alerts...', style: TextStyle(color: Colors.white54)),
                    ],
                  ))
                : _filteredAlerts.isEmpty
                    ? Center(
                        child: Text(
                          'No alerts for this severity.',
                          style: TextStyle(color: Colors.white38, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _filteredAlerts.length,
                        itemBuilder: (ctx, i) => AlertCard(alert: _filteredAlerts[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.yellow;
      case 'low': return Colors.green;
      default: return Colors.blue;
    }
  }
}
