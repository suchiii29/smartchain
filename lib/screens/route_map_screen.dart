import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RouteMapScreen extends StatefulWidget {
  const RouteMapScreen({Key? key}) : super(key: key);

  @override
  _RouteMapScreenState createState() => _RouteMapScreenState();
}

  bool _hasError = false;

  void _showCityDetails(String city) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
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
              Text(city, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Active Shipments: 3', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text('Risk Level: ', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  Text('LOW', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
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
    if (_hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
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
                    Polyline(points: [_cities['Mumbai']!, _cities['Bengaluru']!], color: Colors.red, strokeWidth: 4.0),
                    Polyline(points: [_cities['Chennai']!, _cities['Delhi']!], color: Colors.orange, strokeWidth: 4.0),
                    Polyline(points: [_cities['Kolkata']!, _cities['Hyderabad']!], color: Colors.green, strokeWidth: 4.0),
                    Polyline(points: [_cities['Delhi']!, _cities['Jaipur']!], color: Colors.orange, strokeWidth: 4.0),
                    Polyline(points: [_cities['Pune']!, _cities['Ahmedabad']!], color: Colors.green, strokeWidth: 4.0),
                  ],
                ),
                MarkerLayer(
                  markers: _cities.entries.map((e) => Marker(
                    point: e.value,
                    width: 100,
                    height: 40,
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () => _showCityDetails(e.key),
                      child: const Icon(Icons.location_on, color: Colors.blue, size: 24),
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
                color: const Color(0xFF1A1F2E).withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Route Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildLegendItem(Colors.green, 'On Time'),
                  _buildLegendItem(Colors.orange, 'Delayed'),
                  _buildLegendItem(Colors.red, 'Critical'),
                ],
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('2 critical routes detected by AI', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        },
        label: const Text('Analyze Routes', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.analytics, color: Colors.white),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 16, height: 4, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
