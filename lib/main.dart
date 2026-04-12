import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_screen.dart';
import 'screens/route_map_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/sustainability_screen.dart';
import 'screens/audit_trail_screen.dart';
import 'screens/forecast_screen.dart';

void main() {
  runApp(const SmartChainApp());
}

class SmartChainApp extends StatelessWidget {
  const SmartChainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartChain AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: GoogleFonts.inter().fontFamily,
        primaryColor: const Color(0xFF1A73E8),
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        cardColor: const Color(0xFF161B22),
        cardTheme: const CardTheme(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.white10),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        useMaterial3: true,
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({Key? key}) : super(key: key);

  @override
  _AppShellState createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    RouteMapScreen(),
    AnalyticsScreen(),
    SustainabilityScreen(),
    AuditTrailScreen(),
    ForecastScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: const Color(0xFF0A0E1A),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: Color(0xFF4FC3F7)),
            selectedLabelTextStyle: const TextStyle(color: Color(0xFF4FC3F7)),
            unselectedIconTheme: const IconThemeData(color: Colors.white54),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white54),
            leading: Column(
              children: const [
                SizedBox(height: 16),
                Icon(Icons.local_shipping, color: Colors.cyan, size: 32),
                SizedBox(height: 8),
                Text('SmartChain', style: TextStyle(color: Colors.cyan, fontSize: 11, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
              ],
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
                tooltip: 'Dashboard',
              ),
              NavigationRailDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: Text('Route Map'),
                tooltip: 'Route Map',
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Analytics'),
                tooltip: 'Analytics',
              ),
              NavigationRailDestination(
                icon: Icon(Icons.eco_outlined, color: Color(0xFF34A853)),
                selectedIcon: Icon(Icons.eco, color: Color(0xFF34A853)),
                label: Text('Carbon'),
                tooltip: 'Carbon',
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: Text('Audit'),
                tooltip: 'Audit',
              ),
              NavigationRailDestination(
                icon: Icon(Icons.radar_outlined),
                selectedIcon: Icon(Icons.radar),
                label: Text('Forecast'),
                tooltip: 'Forecast',
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20.0),
                  child: Text('v1.0.0', style: TextStyle(color: Colors.white24, fontSize: 10)),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Colors.white12),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}