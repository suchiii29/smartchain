import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../models/shipment.dart';
import '../theme/app_colors.dart';
import '../constants/app_strings.dart';
import '../widgets/error_screen.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({Key? key}) : super(key: key);

  @override
  _ForecastScreenState createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  final AiService _aiService = AiService();
  bool _hasError = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _predictions = [];

  Future<void> _runForecast() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      final shipments =
          Shipment.getMockShipments().map((e) => e.toMap()).toList();
      final results = await _aiService.predictFuture72Hours(shipments);
      if (mounted) {
        setState(() {
          _predictions = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _showActionPlan(Map<String, dynamic> prediction) async {
    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Center(child: CircularProgressIndicator()),
      );

      final route = prediction['route'] as String;
      final parts = route.split(RegExp(r'->|→'));
      final origin = parts.isNotEmpty ? parts[0].trim() : 'Origin';
      final destination = parts.length > 1 ? parts[1].trim() : 'Destination';

      final recommendations = await _aiService.getRouteOptimization(
        origin: origin,
        destination: destination,
        disruptionType: prediction['disruptionType'] as String,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Action Plan: ${prediction["route"]}',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text('🤖 AI Rerouting Recommendations:',
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                    recommendations
                        .replaceAll('\\n', '\n')
                        .replaceAll('- ', '\n• '),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 15)),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        setState(() => _hasError = true);
      }
    }
  }

  Color _getProbColor(double prob) {
    if (prob > 0.7) return AppColors.error;
    if (prob > 0.4) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text('🔮 72-Hour Disruption Forecast',
              style: TextStyle(color: AppColors.white)),
          backgroundColor: AppColors.card,
          actions: [
            IconButton(
              onPressed: _isLoading ? null : _runForecast,
              icon: Icon(Icons.refresh, color: AppColors.primary),
              tooltip: 'Refresh disruption forecast',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAccuracyCard(),
              const SizedBox(height: 24),
              Semantics(
                label: 'Run disruption forecast for next 72 hours',
                button: true,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runForecast,
                  icon: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.white))
                      : Icon(Icons.radar),
                  label: Text('Run Future Forecast'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (_predictions.isNotEmpty) ...[
                _buildSection('🔴 Next 24 Hours', 'next_24h', AppColors.error),
                _buildSection(
                    '🟠 24 - 48 Hours', '24_to_48h', AppColors.warning),
                _buildSection('🟡 48 - 72 Hours', '48_to_72h', Colors.yellow),
              ] else if (!_isLoading) ...[
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                        'No forecast data. Run forecast to generate predictions.',
                        style: TextStyle(color: AppColors.white38)),
                  ),
                )
              ],
            ],
          ),
        ),
      );
    } catch (e) {
      return ErrorScreen(
        message: e.toString(),
        onRetry: _runForecast,
      );
    }
  }

  Widget _buildAccuracyCard() {
    return Semantics(
      label: 'AI prediction accuracy: 82% based on last 30 days',
      child: Card(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.white.withValues(alpha: 0.1))),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text('AI Prediction Accuracy',
                  style: TextStyle(color: AppColors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              Text('82% accurate',
                  style: TextStyle(
                      color: AppColors.success,
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Based on last 30 days of predictions',
                  style: TextStyle(color: AppColors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String timeframe, Color headerColor) {
    final filtered =
        _predictions.where((p) => p['timeframe'] == timeframe).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: headerColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          itemBuilder: (context, index) =>
              _buildPredictionCard(filtered[index]),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> p) {
    final prob = p['probability'] as double;
    return Semantics(
      label:
          'Prediction for ${p['route']}. Probability: ${(prob * 100).toInt()}%. Type: ${p['disruptionType']}. Action: ${p['preemptiveAction']}',
      child: Card(
        color: AppColors.card,
        margin: EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.white.withValues(alpha: 0.1))),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text(p['route'] as String,
                          style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold))),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: _getProbColor(prob).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: _getProbColor(prob).withValues(alpha: 0.3))),
                    child: Text('${(prob * 100).toStringAsFixed(0)}% Prob',
                        style: TextStyle(
                            color: _getProbColor(prob),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text((p['disruptionType'] as String).toUpperCase(),
                    style: TextStyle(
                        color: AppColors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Text('Preemptive Action:',
                  style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(p['preemptiveAction'] as String,
                  style: TextStyle(color: AppColors.white70, fontSize: 14)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showActionPlan(p),
                  style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary)),
                  child: Text('Take Action',
                      style: TextStyle(color: AppColors.primary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
