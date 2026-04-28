import 'package:flutter/material.dart';
import '../models/shipment.dart';
import '../services/ai_service.dart';
import '../theme/app_colors.dart';
import '../constants/app_strings.dart';
import '../widgets/error_screen.dart';

class SustainabilityScreen extends StatefulWidget {
  const SustainabilityScreen({Key? key}) : super(key: key);

  @override
  _SustainabilityScreenState createState() => _SustainabilityScreenState();
}

class _SustainabilityScreenState extends State<SustainabilityScreen> {
  bool _hasError = false;
  final AiService _aiService = AiService();
  List<Shipment> _shipments = [];
  String? _optimizationResult;
  String? _optimizingShipmentId;

  @override
  void initState() {
    super.initState();
    _shipments = Shipment.getMockShipments();
  }

  void _optimizeRoute(Shipment shipment) async {
    try {
      setState(() => _optimizingShipmentId = shipment.id);
      final result = await _aiService.getRouteOptimization(
        origin: shipment.origin == 'Bengaluru' && shipment.destination == 'Chennai' ? 'Bengaluru' : shipment.origin,
        destination: shipment.origin == 'Bengaluru' && shipment.destination == 'Chennai' ? 'Chennai' : shipment.destination,
        disruptionType: shipment.origin == 'Bengaluru' && shipment.destination == 'Chennai' ? 'carbon_reduction_air' : 'carbon_reduction_${shipment.vehicleType}',
      );
      if (mounted) {
        setState(() {
          _optimizationResult = result;
          _optimizingShipmentId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _optimizingShipmentId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      double totalCarbon = _shipments.fold(0, (sum, s) => sum + s.carbonKg);
      Color statusColor = totalCarbon < 300
          ? AppColors.success
          : (totalCarbon <= 600 ? AppColors.warning : AppColors.error);
      double progress = totalCarbon / 800.0;
      if (progress > 1.0) progress = 1.0;

      double truckTotal = _shipments
          .where((s) => s.vehicleType == 'truck')
          .fold(0, (sum, s) => sum + s.carbonKg);
      double railTotal = _shipments
          .where((s) => s.vehicleType == 'rail')
          .fold(0, (sum, s) => sum + s.carbonKg);
      double airTotal = _shipments
          .where((s) => s.vehicleType == 'air')
          .fold(0, (sum, s) => sum + s.carbonKg);

      var sortedShipments = List<Shipment>.from(_shipments)
        ..sort((a, b) => b.carbonKg.compareTo(a.carbonKg));
      var top3 = sortedShipments.take(3).toList();

      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('🌱 Carbon & Sustainability',
              style: TextStyle(color: AppColors.white)),
          backgroundColor: AppColors.card,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Today's Carbon Footprint",
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Semantics(
                label:
                    "Today's carbon footprint: ${totalCarbon.toStringAsFixed(1)} kg CO2 emitted. Target is 800 kg.",
                child: Card(
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: AppColors.white.withValues(alpha: 0.1))),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          totalCarbon.toStringAsFixed(1),
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 40,
                              fontWeight: FontWeight.bold),
                        ),
                        const Text('kg CO₂ emitted today',
                            style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        const Text('⚠️ 70% above daily target',
                          style: TextStyle(color: Colors.orange, fontSize: 13)),
                        const Text('Switching 2 truck routes to rail saves 487 kg CO₂',
                          style: TextStyle(color: Colors.green, fontSize: 12)),
                        const SizedBox(height: 20),
                        LinearProgressIndicator(
                          value: progress,
                          color: statusColor,
                          backgroundColor:
                              AppColors.white.withValues(alpha: 0.12),
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('Target: 800kg',
                              style: TextStyle(
                                  color: AppColors.white.withValues(alpha: 0.7),
                                  fontSize: 13)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Vehicle Type Breakdown",
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: _buildVehicleStat(Icons.local_shipping, 'Truck',
                          truckTotal, AppColors.primary)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildVehicleStat(
                          Icons.train, 'Rail', railTotal, AppColors.warning)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildVehicleStat(
                          Icons.flight, 'Air', airTotal, Colors.teal)),
                ],
              ),
              const SizedBox(height: 24),
              const Text("High Carbon Routes",
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                color: AppColors.card,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: AppColors.white.withValues(alpha: 0.1))),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: top3.length,
                  itemBuilder: (ctx, i) {
                    final s = top3[i];
                    return Semantics(
                      label:
                          'High carbon route: ${s.origin} to ${s.destination}. Vehicle: ${s.vehicleType}. Carbon: ${s.carbonKg.toStringAsFixed(1)} kg',
                      child: ListTile(
                        title: Text('${s.origin} → ${s.destination}',
                            style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold)),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AppColors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text(s.vehicleType.toUpperCase(),
                                  style: const TextStyle(
                                      color: AppColors.white70, fontSize: 11)),
                            ),
                            const SizedBox(width: 8),
                            Text('${s.carbonKg.toStringAsFixed(1)} kg',
                                style: const TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: _optimizingShipmentId == s.id
                              ? null
                              : () => _optimizeRoute(s),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success),
                          child: _optimizingShipmentId == s.id
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.white))
                              : const Text('Optimize',
                                  style: TextStyle(color: AppColors.white)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_optimizationResult != null) ...[
                const SizedBox(height: 24),
                const Text("AI Optimization Plan",
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: AppColors.success.withValues(alpha: 0.5))),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _optimizationResult!
                          .replaceAll('\\n', '\n')
                          .replaceAll('- ', '\n• '),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } catch (e) {
      return ErrorScreen(message: e.toString());
    }
  }

  Widget _buildVehicleStat(
      IconData icon, String label, double amount, Color color) {
    return Card(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.white.withValues(alpha: 0.1))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: AppColors.white70)),
            const SizedBox(height: 4),
            Text('${amount.toStringAsFixed(1)} kg',
                style: const TextStyle(
                    color: AppColors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
