import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'services/ai_service.dart';

FirebaseOptions firebaseOptions = const FirebaseOptions(
  apiKey: "AIzaSyBANd8ntKan8ITMMiBHs7lRnYfDXCl2Ssw",
  authDomain: "smartchain-491709.firebaseapp.com",
  databaseURL: "https://smartchain-491709-default-rtdb.firebaseio.com",
  projectId: "smartchain-491709",
  storageBucket: "smartchain-491709.firebasestorage.app",
  messagingSenderId: "450920355073",
  appId: "1:450920355073:web:71adf3f489d0f91f48b700",
  measurementId: "G-2VKBK69TYL"
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  print(' Firebase initialized!');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartChain',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _signup() async {
    setState(() => _isLoading = true);
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: ${e.toString()}')),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📦 SmartChain Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_shipping, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text('SmartChain',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('AI-Powered Supply Chain Platform',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 40),
              TextField(
                controller: _email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(onPressed: _login, child: const Text('Login')),
                        const SizedBox(width: 10),
                        ElevatedButton(onPressed: _signup, child: const Text('Sign Up')),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class Shipment {
  final String id;
  final String origin;
  final String destination;
  final String traffic;
  final String weather;
  final String time;
  Map<String, dynamic>? aiPrediction;

  Shipment({
    required this.id,
    required this.origin,
    required this.destination,
    required this.traffic,
    required this.weather,
    required this.time,
    this.aiPrediction,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AiService _aiService = AiService();
  bool _isLoading = false;

  final List<Shipment> _shipments = [
    Shipment(id: 'SHP-1001', origin: 'Mumbai', destination: 'Delhi', traffic: 'Heavy', weather: 'Clear', time: 'Morning'),
    Shipment(id: 'SHP-1002', origin: 'Bangalore', destination: 'Chennai', traffic: 'Moderate', weather: 'Rainy', time: 'Afternoon'),
    Shipment(id: 'SHP-1003', origin: 'Kolkata', destination: 'Pune', traffic: 'Low', weather: 'Windy', time: 'Evening'),
    Shipment(id: 'SHP-1004', origin: 'Hyderabad', destination: 'Ahmedabad', traffic: 'Heavy', weather: 'Stormy', time: 'Night'),
    Shipment(id: 'SHP-1005', origin: 'Jaipur', destination: 'Surat', traffic: 'Low', weather: 'Clear', time: 'Morning'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchPredictions();
  }

  Future<void> _fetchPredictions() async {
    setState(() {
      _isLoading = true;
    });

    for (var shipment in _shipments) {
      shipment.aiPrediction = await _aiService.predictDelay(
        origin: shipment.origin,
        destination: shipment.destination,
        trafficCondition: shipment.traffic,
        weatherCondition: shipment.weather,
        timeOfDay: shipment.time,
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int get _highRiskCount {
    return _shipments.where((s) => s.aiPrediction?['riskLevel'] == 'High' || s.aiPrediction?['riskLevel'] == 'Critical').length;
  }

  String get _onTimePercentage {
    if (_shipments.isEmpty) return '0%';
    int onTime = _shipments.where((s) {
      final delay = s.aiPrediction?['predictedDelay'] ?? 0;
      return (delay is num && delay < 1.0);
    }).length;
    return '${((onTime / _shipments.length) * 100).toStringAsFixed(0)}%';
  }

  Color _getRiskColor(int score) {
    if (score >= 75) return Colors.red;
    if (score >= 50) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 SmartChain Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _fetchPredictions,
        icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
        label: const Text('Refresh Predictions'),
      ),
      body: Column(
        children: [
          // Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Total Shipments', _shipments.length.toString(), Icons.local_shipping, colorScheme.primary),
                _buildStatCard('High Risk', _highRiskCount.toString(), Icons.warning, Colors.orange),
                _buildStatCard('On-Time', _onTimePercentage, Icons.check_circle, Colors.green),
              ],
            ),
          ),
          
          // WebMCP Status Badge
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.smart_toy, color: Colors.green),
                    SizedBox(width: 8),
                    Text('WebMCP Enabled', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Available AI Agent Tools:', style: TextStyle(fontSize: 13, color: Colors.green.shade800)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildToolChip('get_shipment_status'),
                    _buildToolChip('report_delay'),
                    _buildToolChip('get_ai_prediction'),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
                ? const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Crunching AI delay predictions...', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _shipments.length,
                    itemBuilder: (context, index) {
                      final shipment = _shipments[index];
                      final prediction = shipment.aiPrediction ?? {};
                      
                      final riskScoreDynamic = prediction['riskScore'] ?? 0;
                      final riskScore = riskScoreDynamic is int ? riskScoreDynamic : (riskScoreDynamic as num).toInt();
                      
                      final riskLevel = prediction['riskLevel'] ?? 'Unknown';
                      
                      final predictedDelayDynamic = prediction['predictedDelay'] ?? 0;
                      final predictedDelay = predictedDelayDynamic is num ? predictedDelayDynamic.toDouble() : 0.0;
                      
                      final action = prediction['suggestedAction'] ?? 'None';
                      final riskColor = _getRiskColor(riskScore);

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(shipment.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: riskColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: riskColor.withOpacity(0.5)),
                                    ),
                                    child: Text('$riskLevel Risk ($riskScore%)', 
                                      style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.route, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text('${shipment.origin} → ${shipment.destination}', style: const TextStyle(fontSize: 15)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.timer, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text('Predicted Delay: ${predictedDelay.toStringAsFixed(1)} hrs', 
                                    style: TextStyle(color: predictedDelay > 0 ? Colors.red[700] : Colors.green[700], fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.lightbulb, size: 18, color: Colors.amber),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text('Action: $action', style: TextStyle(fontSize: 13, color: Colors.grey[800], fontStyle: FontStyle.italic))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildToolChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Text(name, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.black87)),
    );
  }
}