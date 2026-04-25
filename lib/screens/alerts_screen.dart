import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../models/disruption_alert.dart';
import '../models/shipment.dart';
import '../models/route_condition.dart';
import '../widgets/alert_card.dart';
import '../theme/app_colors.dart';
import '../constants/app_strings.dart';
import '../widgets/error_screen.dart';

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
    if (mounted) setState(() => _isLoading = true);
    try {
      final shipments = Shipment.getMockShipments();
      final conditions = RouteCondition.getMockConditions();
      final results = await _aiService.analyzeDisruptions(
        shipments: shipments.map((e) => e.toMap()).toList(),
        conditions: conditions.map((e) => e.description).toList(),
      );
      if (mounted) {
        setState(() {
          _alerts = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<DisruptionAlert> get _filteredAlerts {
    if (_filterSeverity == 'all') return _alerts;
    return _alerts.where((a) => a.severity.toLowerCase() == _filterSeverity.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: AppColors.surfaceDark,
        appBar: AppBar(
          backgroundColor: AppColors.cardAlt,
          title: const Text('⚠️ Disruption Alerts', style: TextStyle(color: AppColors.white)),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.white),
              onPressed: _loadAlerts,
              tooltip: 'Refresh disruption alerts',
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
                      child: Semantics(
                        label: 'Filter by ${severity.toUpperCase()} severity',
                        button: true,
                        selected: isSelected,
                        child: FilterChip(
                          label: Text(
                            severity.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? AppColors.white : chipColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _filterSeverity = severity),
                          backgroundColor: AppColors.cardAlt,
                          selectedColor: chipColor.withValues(alpha: 0.3),
                          checkmarkColor: chipColor,
                          side: BorderSide(color: isSelected ? chipColor : AppColors.white38.withValues(alpha: 0.1)),
                        ),
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
                        Text('Fetching AI alerts...', style: TextStyle(color: AppColors.white70)),
                      ],
                    ))
                  : _filteredAlerts.isEmpty
                      ? const Center(
                          child: Text(
                            'No alerts for this severity.',
                            style: TextStyle(color: AppColors.white38, fontSize: 16),
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
    } catch (e) {
      return ErrorScreen(
        message: e.toString(),
        onRetry: _loadAlerts,
      );
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return AppColors.error;
      case 'high': return AppColors.warning;
      case 'medium': return Colors.yellow;
      case 'low': return AppColors.success;
      default: return AppColors.primary;
    }
  }
}
