import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';


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
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return DashboardScreen();
          }
          return LoginScreen();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _signup() async {
    setState(() => _isLoading = true);
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: ${e.toString()}')),
      );
    }
    setState(() => _isLoading = false);
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


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 SmartChain Dashboard'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Bar
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('🚛', '24', 'Active Trucks'),
                _buildStatCard('📦', '156', 'Shipments'),
                _buildStatCard('⚠️', '3', 'Alerts'),
                _buildStatCard('✅', '94%', 'On-Time'),
              ],
            ),
          ),

          // Map
          Expanded(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(20.5937, 78.9629), // India center
                initialZoom: 5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.smartchain.app',
                ),
                MarkerLayer(
                  markers: [
                    // Mumbai Truck
                    Marker(
                      point: const LatLng(19.0760, 72.8777),
                      child: const Icon(Icons.local_shipping, 
                          color: Colors.blue, size: 40),
                    ),
                    // Delhi Truck
                    Marker(
                      point: const LatLng(28.7041, 77.1025),
                      child: const Icon(Icons.local_shipping, 
                          color: Colors.green, size: 40),
                    ),
                    // Bangalore Truck
                    Marker(
                      point: const LatLng(12.9716, 77.5946),
                      child: const Icon(Icons.local_shipping, 
                          color: Colors.orange, size: 40),
                    ),
                    // Chennai Truck
                    Marker(
                      point: const LatLng(13.0827, 80.2707),
                      child: const Icon(Icons.local_shipping, 
                          color: Colors.red, size: 40),
                    ),
                    // Kolkata Truck
                    Marker(
                      point: const LatLng(22.5726, 88.3639),
                      child: const Icon(Icons.local_shipping, 
                          color: Colors.purple, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),

          
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🚛 Live Truck Locations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildTruckInfo('MH-12-AB-1234', 'Mumbai → Delhi', 'On Time', Colors.green),
                _buildTruckInfo('KA-01-CD-5678', 'Bangalore → Chennai', 'Delayed', Colors.red),
                _buildTruckInfo('WB-22-EF-9012', 'Kolkata → Mumbai', 'In Transit', Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 30)),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTruckInfo(String truckId, String route, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(truckId, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(route, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(status,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}