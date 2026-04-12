import 'package:flutter/material.dart';
import '../models/shipment.dart';
import '../services/ai_service.dart';

class SustainabilityScreen extends StatefulWidget {
  const SustainabilityScreen({Key? key}) : super(key: key);

  @override
  _SustainabilityScreenState createState() => _SustainabilityScreenState();
}

class _SustainabilityScreenState extends State<SustainabilityScreen> {
  bool _hasError = false;

  void _optimizeRoute(Shipment shipment) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Optimizing route...'), duration: Duration(seconds: 1)),
      );
      final result = await _aiService.getRouteOptimization(
        origin: shipment.origin,
        destination: shipment.destination,
        disruptionType: 'carbon_reduction',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Optimization: $result'), duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(title: const Text('🌱 Sustainability')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text('Something went wrong. Please try again.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => setState(() => _hasError = false), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    try {
      double totalCarbon = _shipments.fold(0, (sum, s) => sum + s.carbonKg);
      Color statusColor = totalCarbon < 300 ? Colors.green : (totalCarbon <= 600 ? Colors.orange : Colors.red);
      double progress = totalCarbon / 800.0;
      if (progress > 1.0) progress = 1.0;

      double truckTotal = _shipments.where((s) => s.vehicleType == 'truck').fold(0, (sum, s) => sum + s.carbonKg);
      double railTotal = _shipments.where((s) => s.vehicleType == 'rail').fold(0, (sum, s) => sum + s.carbonKg);
      double airTotal = _shipments.where((s) => s.vehicleType == 'air').fold(0, (sum, s) => sum + s.carbonKg);

      var sortedShipments = List<Shipment>.from(_shipments)
        ..sort((a, b) => b.carbonKg.compareTo(a.carbonKg));
      var top3 = sortedShipments.take(3).toList();

      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(
          title: const Text('🌱 Carbon & Sustainability', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF161B22),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Today's Carbon Footprint", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                color: const Color(0xFF161B22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        totalCarbon.toStringAsFixed(1),
                        style: TextStyle(color: statusColor, fontSize: 40, fontWeight: FontWeight.bold),
                      ),
                      const Text('kg CO₂ emitted today', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: progress,
                        color: statusColor,
                        backgroundColor: Colors.white12,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text('Target: 800kg', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Vehicle Type Breakdown", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildVehicleStat(Icons.local_shipping, 'Truck', truckTotal, Colors.blue)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildVehicleStat(Icons.train, 'Rail', railTotal, Colors.orange)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildVehicleStat(Icons.flight, 'Air', airTotal, Colors.teal)),
                ],
              ),
              const SizedBox(height: 24),
              const Text("High Carbon Routes", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                color: const Color(0xFF161B22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: top3.length,
                  itemBuilder: (ctx, i) {
                    final s = top3[i];
                    return ListTile(
                      title: Text('${s.origin} → ${s.destination}', style: const TextStyle(color: Colors.white)),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                            child: Text(s.vehicleType.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                          ),
                          const SizedBox(width: 8),
                          Text('${s.carbonKg.toStringAsFixed(1)} kg', style: const TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _optimizeRoute(s),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Optimize', style: TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                ),
              ),
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
              ElevatedButton(onPressed: () => setState(() => _hasError = false), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildVehicleStat(IconData icon, String label, double amount, Color color) {
    return Card(
      color: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text('${amount.toStringAsFixed(1)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
