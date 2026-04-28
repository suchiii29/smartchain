import 'package:flutter/material.dart';
import '../main.dart';
import '../theme/app_colors.dart';
import '../services/weather_service.dart';
import '../services/shipment_state_service.dart';
import '../services/route_prediction_service.dart';
import '../services/firebase_service.dart';
import '../models/disruption_alert.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class DriverPortalScreen extends StatefulWidget {
  const DriverPortalScreen({super.key});

  @override
  State<DriverPortalScreen> createState() => _DriverPortalScreenState();
}

class _DriverPortalScreenState extends State<DriverPortalScreen> {
  Map<String, dynamic>? _weatherData;
  bool _hasPredictedDisruption = false;
  bool _isAcceptingRoute = false;
  bool _routeAccepted = false;

  @override
  void initState() {
    super.initState();
    ShipmentStateService.initialize();
    _loadWeather();
    Timer.periodic(const Duration(minutes: 15), (_) async {
      final risks = await RoutePredictionService.checkRouteRisks();
      
      if (risks.isNotEmpty && mounted) {
        _showRouteDeviationAlert(risks.first);
      }
    });
  }

  Future<void> _loadWeather() async {
    final wData = await WeatherService.getRouteWeather('Mumbai', 'Bengaluru');
    if (mounted) {
      setState(() {
        _weatherData = wData;
      });
    }
  }

  void _showRouteDeviationAlert(Map risk) {
    setState(() => _hasPredictedDisruption = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Row(children: [
          Icon(Icons.warning, color: Colors.orange, size: 32),
          SizedBox(width: 8),
          Text('⚠️ Route Disruption Ahead!',
            style: TextStyle(color: Colors.orange)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Prediction:',
              style: TextStyle(color: Colors.blue, 
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Disruption detected ${risk['timeToDisruption']}',
              style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text('Reason: ${risk['reason']}',
              style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Predicted Delay: +${risk['predictedDelay']} mins',
              style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🤖 AI Recommended Alternative:',
                    style: TextStyle(color: Colors.blue,
                      fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(risk['alternativeRoute'],
                    style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('💰 Savings: ₹${_calculateSavings(risk['predictedDelay'])}',
              style: const TextStyle(color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _acceptAlternativeRoute(risk);
            },
            child: const Text('✅ Accept New Route',
              style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('Dismiss',
              style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  String _calculateSavings(int delayMinutes) {
    final saved = delayMinutes * 150;
    if (saved >= 1000) return '${(saved/1000).toStringAsFixed(1)}K';
    return '$saved';
  }

  void _acceptAlternativeRoute(Map risk) {
    FirebaseService.saveAlert(DisruptionAlert(
      id: 'reroute_${DateTime.now().millisecondsSinceEpoch}',
      type: 'route_deviation',
      severity: risk['severity'],
      affectedRoute: risk['route'],
      predictedDelayMinutes: risk['predictedDelay'],
      recommendedAction: risk['alternativeRoute'],
      confidence: 0.92,
    ));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Route updated! Saving ₹${_calculateSavings(risk['predictedDelay'])}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
        ),
        title: const Text(
          "🚛 Driver Dashboard",
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.white),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Info Card
            _buildDriverInfoCard(),
            const SizedBox(height: 20),

            // My Route Today Card
            _buildRouteCard(context),
            const SizedBox(height: 24),

            // Upcoming Stops
            const Text(
              "Upcoming Stops",
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStopItem("Pune Hub", "10:30 AM", "Distance: 150 km"),
            _buildStopItem(
                "Kolhapur Warehouse", "02:15 PM", "Distance: 380 km"),
            _buildStopItem("Belagavi DC", "05:45 PM", "Distance: 510 km"),

            const SizedBox(height: 40),

            // SOS Button
            _buildSOSButton(context),
            const SizedBox(height: 20),

            // Simulate Deviation Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  final shipment = ShipmentStateService.shipments.first;
                  ShipmentStateService.setDriverDeviating(true, '${shipment.origin} → ${shipment.destination}');
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deviation Simulated')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: const Text(
                  "🚨 Simulate Route Deviation",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 24,
            child: Icon(Icons.person, color: AppColors.white),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Driver: Rajesh Kumar",
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Truck: MH-12-AB-1234",
                  style: TextStyle(
                    color: AppColors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "Active",
              style: TextStyle(color: AppColors.success, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context) {
    final shipment = ShipmentStateService.shipments.first;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "My Route Today",
                style: TextStyle(
                  color: AppColors.white70,
                  fontSize: 14,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "CRITICAL",
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primaryLight, size: 20),
              const SizedBox(width: 8),
              Text(
                shipment.origin,
                style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward,
                    color: AppColors.white38, size: 16),
              ),
              Text(
                shipment.destination,
                style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildRouteStat(Icons.route, "1,200 km", "Distance"),
              const SizedBox(width: 32),
              _buildRouteStat(Icons.access_time, "6 hours", "ETA"),
            ],
          ),
          if (_hasPredictedDisruption)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(children: [
                const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🤖 AI Prediction',
                        style: TextStyle(color: Colors.orange,
                          fontWeight: FontWeight.bold, fontSize: 12)),
                      const Text('Disruption predicted 45 mins ahead on NH48',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ]),
            ),
          const SizedBox(height: 20),
          Builder(builder: (context) {
            Color boxColor = Colors.orange;
            IconData icon = Icons.warning_amber_rounded;
            String message = "Loading real weather...";

            if (_weatherData != null) {
              final originData = _weatherData!['origin'];
              final bool isSevere = originData['is_severe'] == true;
              final String condition = originData['condition'];
              final String city = originData['city'];
              final String emoji = WeatherService.getWeatherEmoji(condition);

              if (isSevere) {
                boxColor = AppColors.error;
                icon = Icons.warning_amber_rounded;
                message =
                    "$emoji Real weather: $condition near $city (OpenWeather API)\n Recommended: Take NH66 coastal route";
              } else {
                boxColor = AppColors.success;
                icon = Icons.check_circle_outline;
                message =
                    "$emoji Real weather: $condition near $city (OpenWeather API)\n ✅ Current route NH48 is optimal. No rerouting needed.";
              }
            }

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: boxColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: boxColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: boxColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(color: boxColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _routeAccepted ? null : () async {
                    setState(() => _isAcceptingRoute = true);
                    await Future.delayed(const Duration(milliseconds: 800));
                    
                    await FirebaseDatabase.instance.ref('driver_actions').push().set({
                      'driver': 'Rajesh Kumar',
                      'truck': 'MH-12-AB-1234',
                      'action': 'route_accepted',
                      'route': 'Mumbai → Bengaluru',
                      'newRoute': 'NH66 Coastal Highway',
                      'timestamp': DateTime.now().toIso8601String(),
                      'status': 'rerouted',
                    });
                    
                    ShipmentStateService.setDriverDeviating(false, 'NH66');
                    if (context.mounted) {
                      setState(() {
                         _isAcceptingRoute = false;
                         _routeAccepted = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ New route accepted! Manager notified.'), backgroundColor: Colors.green),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _routeAccepted ? AppColors.success : AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isAcceptingRoute 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_routeAccepted ? "✅ Route Accepted" : "Accept New Route"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await FirebaseDatabase.instance.ref('driver_status').child('rajesh_kumar').set({
                      'status': 'on_route',
                      'route': 'Mumbai → Bengaluru',
                      'timestamp': DateTime.now().toIso8601String(),
                      'location': 'En route via NH48',
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Status updated. Manager can see you live.'), backgroundColor: Colors.blue),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("I'm On Route"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteStat(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.white38, size: 16),
            const SizedBox(width: 4),
            Text(value,
                style: const TextStyle(
                    color: AppColors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label,
            style: const TextStyle(color: AppColors.white38, fontSize: 12)),
      ],
    );
  }

  Widget _buildStopItem(String location, String time, String distance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location,
                    style: const TextStyle(
                        color: AppColors.white, fontWeight: FontWeight.bold)),
                Text(distance,
                    style: const TextStyle(
                        color: AppColors.white38, fontSize: 12)),
              ],
            ),
          ),
          Text(time,
              style: const TextStyle(
                  color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSOSButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.card,
              title: const Text("Emergency SOS",
                  style: TextStyle(color: AppColors.white)),
              content: const Text(
                "SOS sent to manager. Help is on the way.",
                style: TextStyle(color: AppColors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
        child: const Text(
          "🆘 Emergency SOS",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
