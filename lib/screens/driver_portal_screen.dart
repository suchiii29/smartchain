import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/weather_service.dart';

class DriverPortalScreen extends StatefulWidget {
  const DriverPortalScreen({super.key});

  @override
  State<DriverPortalScreen> createState() => _DriverPortalScreenState();
}

class _DriverPortalScreenState extends State<DriverPortalScreen> {
  Map<String, dynamic>? _weatherData;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final wData = await WeatherService.getRouteWeather('Mumbai', 'Bengaluru');
    if (mounted) {
      setState(() {
        _weatherData = wData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
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
            onPressed: () => Navigator.of(context)
                .pushReplacementNamed('/'), // Assuming '/' is role selection
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
          const Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                "Mumbai",
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward,
                    color: AppColors.white38, size: 16),
              ),
              Text(
                "Bengaluru",
                style: TextStyle(
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
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Accept New Route"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
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
