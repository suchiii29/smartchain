import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';
import '../constants/app_strings.dart';
import '../widgets/error_screen.dart';

class RouteMapScreen extends StatefulWidget {
  const RouteMapScreen({Key? key}) : super(key: key);

  @override
  _RouteMapScreenState createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  final Map<String, LatLng> _cities = {
    'Mumbai': const LatLng(19.0760, 72.8777),
    'Bengaluru': const LatLng(12.9716, 77.5946),
    'Chennai': const LatLng(13.0827, 80.2707),
    'Delhi': const LatLng(28.6139, 77.2090),
    'Kolkata': const LatLng(22.5726, 88.3639),
    'Hyderabad': const LatLng(17.3850, 78.4867),
    'Jaipur': const LatLng(26.9124, 75.7873),
    'Pune': const LatLng(18.5204, 73.8567),
    'Ahmedabad': const LatLng(23.0225, 72.5714),
  };

  bool _hasError = false;

  void _showCityDetails(String city) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(city, style: const TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Active Shipments: 3', style: TextStyle(color: AppColors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              const Row(
                children: [
                   Text('Risk Level: ', style: TextStyle(color: AppColors.white70, fontSize: 16)),
                   Text('LOW', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        body: Stack(
          children: [
            FlutterMap(
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
                  polylines: [
                    Polyline(points: [_cities['Mumbai']!, _cities['Bengaluru']!], color: AppColors.error, strokeWidth: 4.0),
                    Polyline(points: [_cities['Chennai']!, _cities['Delhi']!], color: AppColors.warning, strokeWidth: 4.0),
                    Polyline(points: [_cities['Kolkata']!, _cities['Hyderabad']!], color: AppColors.success, strokeWidth: 4.0),
                    Polyline(points: [_cities['Delhi']!, _cities['Jaipur']!], color: AppColors.warning, strokeWidth: 4.0),
                    Polyline(points: [_cities['Pune']!, _cities['Ahmedabad']!], color: AppColors.success, strokeWidth: 4.0),
                  ],
                ),
                MarkerLayer(
                  markers: _cities.entries.map((e) => Marker(
                    point: e.value,
                    width: 100,
                    height: 40,
                    alignment: Alignment.center,
                    child: Semantics(
                      label: 'Marker for ${e.key} city. Tap for logistics details.',
                      button: true,
                      child: GestureDetector(
                        onTap: () => _showCityDetails(e.key),
                        child: const Icon(Icons.location_on, color: AppColors.primary, size: 24),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
            Positioned(
            top: 40,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardAlt.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Route Status', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildLegendItem(AppColors.success, 'On Time'),
                  _buildLegendItem(AppColors.warning, 'Delayed'),
                  _buildLegendItem(AppColors.error, 'Critical'),
                ],
              ),
            ),
          )
        ],
      ),
      floatingActionButton: Semantics(
        label: 'Analyze detected routes for disruption risks',
        child: FloatingActionButton.extended(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('2 critical routes detected by AI', style: TextStyle(color: AppColors.white)),
                backgroundColor: AppColors.error,
              ),
            );
          },
          label: const Text('Analyze Routes', style: TextStyle(color: AppColors.white)),
          icon: const Icon(Icons.analytics, color: AppColors.white),
          backgroundColor: AppColors.primary,
          tooltip: 'Analyze current logistics routes',
        ),
      ),
    );
  } catch (e) {
      debugPrint(e.toString());
      return ErrorScreen(message: e.toString());
    }
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 16, height: 4, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppColors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
