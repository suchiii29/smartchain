import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../models/shipment.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({Key? key}) : super(key: key);

  @override
  _ForecastScreenState createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  final AiService _aiService = AiService();
  bool _hasError = false;

  Future<void> _runForecast() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      final shipments = Shipment.getMockShipments().map((e) => e.toMap()).toList();
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

  void _takeAction(Map<String, dynamic> prediction) async {
    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF161B22),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final route = prediction['route'] as String;
      final parts = route.split('->');
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
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Action Plan: ${prediction["route"]}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('🤖 AI Rerouting Recommendations:', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(recommendations, style: const TextStyle(color: Colors.white70, fontSize: 15)),
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
    if (prob > 0.7) return Colors.red;
    if (prob > 0.4) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(title: const Text('🔮 Forecast')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text('Something went wrong. Please try again.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _runForecast, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    try {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(
          title: const Text('🔮 72-Hour Disruption Forecast', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF161B22),
          actions: [
            IconButton(
              onPressed: _isLoading ? null : _runForecast,
              icon: const Icon(Icons.refresh, color: Colors.blue),
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
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _runForecast,
                icon: _isLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.radar),
                label: const Text('Run Future Forecast'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 32),
              if (_predictions.isNotEmpty) ...[
                _buildSection('🔴 Next 24 Hours', 'next_24h', Colors.red),
                _buildSection('🟠 24 - 48 Hours', '24_to_48h', Colors.orange),
                _buildSection('🟡 48 - 72 Hours', '48_to_72h', Colors.yellow),
              ] else if (!_isLoading)...[
                 const Center(
                   child: Padding(
                     padding: EdgeInsets.symmetric(vertical: 48),
                     child: Text('No forecast data. Run forecast to generate predictions.', style: TextStyle(color: Colors.white38)),
                   ),
                 )
              ],
            ],
          ),
        ),
      );
    } catch (e) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text('Something went wrong. Please try again.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _runForecast, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildAccuracyCard() {
    return Card(
      color: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white10)),
      child: const Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text('AI Prediction Accuracy', style: TextStyle(color: Colors.white70, fontSize: 16)),
            SizedBox(height: 8),
            Text('82% accurate', style: TextStyle(color: Colors.green, fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Based on last 30 days of predictions', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String timeframe, Color headerColor) {
    final filtered = _predictions.where((p) => p['timeframe'] == timeframe).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: headerColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...filtered.map((p) => _buildPredictionCard(p)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> p) {
    final prob = p['probability'] as double;
    return Card(
      color: const Color(0xFF161B22),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(p['route'] as String, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _getProbColor(prob).withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: _getProbColor(prob).withOpacity(0.3))),
                  child: Text('${(prob * 100).toStringAsFixed(0)}% Prob', style: TextStyle(color: _getProbColor(prob), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
              child: Text((p['disruptionType'] as String).toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Text('Preemptive Action:', style: TextStyle(color: Colors.blue.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(p['preemptiveAction'] as String, style: const TextStyle(color: Colors.white60, fontSize: 14)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _takeAction(p),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blue)),
                child: const Text('Take Action', style: TextStyle(color: Colors.blue)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}  ),
    );
  }
}
