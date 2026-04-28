import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../theme/app_colors.dart';
import '../services/ai_service.dart';
import '../services/firebase_service.dart';
import '../services/shipment_state_service.dart';

class RouteMapScreen extends StatefulWidget {
  const RouteMapScreen({Key? key}) : super(key: key);

  @override
  _RouteMapScreenState createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> with TickerProviderStateMixin {
  List<Map<String,dynamic>> _routes = [];
  Map<String, LatLng> _cities = {};
  bool _isAnalyzing = false;
  bool _showAlternateRoute = false;
  String? _alternateRouteFor;
  final MapController _mapController = MapController();
  final AiService _aiService = AiService();
  StreamSubscription? _alertsSub;

  @override
  void initState() {
    super.initState();
    _cities = {
      'Mumbai': const LatLng(19.07, 72.87),
      'Bengaluru': const LatLng(12.97, 77.59),
      'Chennai': const LatLng(13.08, 80.27),
      'Delhi': const LatLng(28.67, 77.22),
      'Kolkata': const LatLng(22.57, 88.36),
      'Hyderabad': const LatLng(17.38, 78.48),
      'Pune': const LatLng(18.52, 73.85),
      'Jaipur': const LatLng(26.91, 75.78),
      'Ahmedabad': const LatLng(23.02, 72.57),
    };
    _loadRoutes();
    
    _alertsSub = FirebaseService.getAlertsStream().listen((event) {
      // Background realtime updates hook
    });
  }

  @override
  void dispose() {
    _alertsSub?.cancel();
    super.dispose();
  }

  void _loadRoutes() {
    ShipmentStateService.initialize();
    final shipments = ShipmentStateService.shipments.take(5).toList();
    _routes = shipments.map((s) {
      return {
        'name': '${s.origin} → ${s.destination}',
        'origin': s.origin,
        'destination': s.destination,
        'status': 'On Time',
        'color': Colors.green,
        'delay': s.delayMinutes,
        'cargo': s.cargoType,
        'id': s.id,
      };
    }).where((r) => _cities.containsKey(r['origin']) && _cities.containsKey(r['destination'])).toList();
    
    setState(() {});
  }

  Future<void> _analyzeRoutes() async {
    setState(() => _isAnalyzing = true);
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        if (_routes.isNotEmpty) {
          _routes[0]['status'] = 'Critical';
          _routes[0]['color'] = Colors.red;
          if (_routes.length > 1) {
            _routes[1]['status'] = 'Delayed';
            _routes[1]['color'] = Colors.orange;
          }
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Analysis complete: 1 critical, 1 delayed routes'),
          backgroundColor: Colors.green,
        ),
      );
      
      final critical = _routes.where((r) => r['status'] == 'Critical').toList();
      if (critical.isNotEmpty) {
        final origin = _cities[critical.first['origin']];
        if (origin != null) {
          _mapController.move(origin, 7);
        }
      }
    }
  }

  Future<void> _showAlternateRouteForRoute(String routeName) async {
    setState(() {
      _showAlternateRoute = true;
      _alternateRouteFor = routeName;
    });

    final route = _routes.firstWhere((r) => r['name'] == routeName);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final delay = route['delay'] ?? 180;
        final savedDelay = (delay * 0.6).round();
        final savingsRupees = savedDelay * 150;
        final savingsText = savingsRupees >= 1000
            ? '₹${(savingsRupees / 1000).toStringAsFixed(1)}K'
            : '₹$savingsRupees';

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🤖 AI Route Comparison',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.check, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'AI Route: Saves ${savedDelay}min',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Text('💰 Saves: $savingsText',
                  style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      for (var r in _routes) {
                        if (r['name'] == routeName) {
                          r['color'] = Colors.blue;
                          r['status'] = 'Rerouted';
                        }
                      }
                      _showAlternateRoute = false;
                    });
                    
                    if (route['id'] != null) {
                      FirebaseService.saveShipmentStatus(route['id'], 'rerouted');
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Route updated! Saving $savingsText'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('✅ Apply This Route',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onRouteTap(String routeName) {
    final route = _routes.firstWhere((r) => r['name'] == routeName, orElse: () => {});
    if (route.isEmpty) return;
    
    final origin = _cities[route['origin']];
    if (origin != null) {
      _mapController.move(origin, 7);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isCritical = route['status'] == 'Critical';
        final isDelayed = route['status'] == 'Delayed';
        final statusColor = route['color'] as Color? ?? Colors.green;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(route['name'],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: statusColor.withValues(alpha: 0.6)),
                    ),
                    child: Text(route['status'],
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (route['cargo'] != null)
                Text('${route['cargo']}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 16),

              if (isCritical || isDelayed) ...[
                const Text('🤖 AI Recommendation:',
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 4),
                const Text(
                    'Reroute via alternate highway to avoid disruption zone.',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAlternateRouteForRoute(routeName);
                      },
                      icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                      label: const Text('⚡ Apply AI Reroute',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.bar_chart, color: Colors.white70, size: 18),
                      label: const Text('📊 Details', style: TextStyle(color: Colors.white70)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                ]),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text('Route operating normally.',
                            style: TextStyle(color: Colors.green, fontSize: 13))),
                  ]),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
  
  void _showDisruptionMarkerPopup(Map<String, dynamic> route) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: Row(children: [
          const Icon(Icons.warning_amber, color: Colors.red, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Disruption: ${route['name']}',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Text('Type: ', style: TextStyle(color: Colors.white54)),
              Text('Weather / Traffic',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🤖 AI detected this disruption early',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showAlternateRouteForRoute(route['name'] as String);
            },
            child: const Text('⚡ Reroute Now', style: TextStyle(color: Color(0xFF1A73E8))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 16, height: 4, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      final onTimeCount = _routes.where((r) => r['status'] == 'On Time').length;
      final delayedCount = _routes.where((r) => r['status'] == 'Delayed').length;
      final criticalCount = _routes.where((r) => r['status'] == 'Critical').length;
      final reroutedCount = _routes.where((r) => r['status'] == 'Rerouted').length;
      final totalValueAtRisk = _routes
          .where((r) => r['status'] != 'On Time')
          .fold<int>(0, (sum, r) => sum + (((r['delay'] ?? 0) as int) * 150));
      final valueText = totalValueAtRisk >= 100000
          ? '₹${(totalValueAtRisk / 100000).toStringAsFixed(1)}L'
          : (totalValueAtRisk >= 1000
              ? '₹${(totalValueAtRisk / 1000).toStringAsFixed(0)}K'
              : '₹$totalValueAtRisk');

      List<Polyline> lines = [];
      for (var r in _routes) {
        final origin = _cities[r['origin']]!;
        final dest = _cities[r['destination']]!;
        lines.add(Polyline(
          points: [origin, dest],
          color: r['color'] as Color,
          strokeWidth: r['status'] == 'Critical' ? 5.0 : 4.0,
        ));
      }
      
      if (_showAlternateRoute && _alternateRouteFor != null) {
        final altRoutes = _routes.where((r) => r['name'] == _alternateRouteFor).toList();
        for (var r in altRoutes) {
          final origin = _cities[r['origin']]!;
          final dest = _cities[r['destination']]!;
          final midLat = (origin.latitude + dest.latitude) / 2 + 1.0;
          final midLng = (origin.longitude + dest.longitude) / 2 - 1.5;
          
          lines.add(Polyline(
            points: [origin, LatLng(midLat, midLng), dest],
            color: Colors.blue,
            strokeWidth: 4.0,
            pattern: StrokePattern.dashed(segments: [5.0, 10.0]),
          ));
        }
      }

      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(
          title: const Text('Auto-Reroute Flow', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF161B22),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(20.5, 78.9),
                initialZoom: 5.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.smartchain',
                ),
                PolylineLayer(
                  polylines: lines,
                ),
                MarkerLayer(
                  markers: _cities.entries.map((e) {
                    return Marker(
                      point: e.value,
                      width: 120,
                      height: 50,
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () {
                          final matching = _routes.where((r) => r['origin'] == e.key || r['destination'] == e.key).toList();
                          if (matching.isNotEmpty) {
                            _onRouteTap(matching.first['name'] as String);
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, color: AppColors.primary, size: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF161B22).withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                MarkerLayer(
                  markers: _routes.where((r) => r['status'] == 'Critical').map((r) {
                    final origin = _cities[r['origin']]!;
                    final dest = _cities[r['destination']]!;
                    final mid = LatLng((origin.latitude + dest.latitude) / 2, (origin.longitude + dest.longitude) / 2);
                    return Marker(
                      point: mid,
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showDisruptionMarkerPopup(r),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2),
                            ],
                          ),
                          child: const Icon(Icons.warning_amber, color: Colors.white, size: 22),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            if (_isAnalyzing)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF1A73E8)),
                      SizedBox(height: 16),
                      Text('🤖 AI Analyzing Routes...', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            Positioned(
              top: 40,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Route Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildLegendItem(Colors.green, 'On Time'),
                    _buildLegendItem(Colors.orange, 'Delayed'),
                    _buildLegendItem(Colors.red, 'Critical'),
                    _buildLegendItem(Colors.blue, 'AI Rerouted'),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.cloud, color: Colors.blue, size: 16), SizedBox(width: 4), Text('Weather: Live', style: TextStyle(color: Colors.white70, fontSize: 11))]),
                    SizedBox(height: 8),
                    Row(children: [Icon(Icons.psychology, color: Colors.green, size: 16), SizedBox(width: 4), Text('ML: Active', style: TextStyle(color: Colors.white70, fontSize: 11))]),
                    SizedBox(height: 8),
                    Row(children: [Icon(Icons.auto_awesome, color: Colors.purple, size: 16), SizedBox(width: 4), Text('Gemini: Ready', style: TextStyle(color: Colors.white70, fontSize: 11))]),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Routes: ${_routes.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('🟢 On Time: $onTimeCount', style: const TextStyle(color: Colors.green, fontSize: 12)),
                    Text('🟠 Delayed: $delayedCount', style: const TextStyle(color: Colors.orange, fontSize: 12)),
                    Text('🔴 Critical: $criticalCount', style: const TextStyle(color: Colors.red, fontSize: 12)),
                    if (reroutedCount > 0) Text('🔵 Rerouted: $reroutedCount', style: const TextStyle(color: Colors.blue, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('💰 At Risk: $valueText', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isAnalyzing ? null : _analyzeRoutes,
          label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Routes', style: const TextStyle(color: Colors.white)),
          icon: _isAnalyzing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome, color: Colors.white),
          backgroundColor: const Color(0xFF1A73E8),
          tooltip: 'Run AI analysis on all routes',
        ),
      );
    } catch (e) {
      return Scaffold(body: Center(child: Text("Error: $e", style: const TextStyle(color: Colors.red))));
    }
  }
}
