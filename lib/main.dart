import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/route_map_screen.dart';
import 'screens/analytics_screen.dart';

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
        primaryColor: const Color(0xFF4FC3F7),
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        useMaterial3: true,
      ),
      home: const AppShell(),
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
              ),
              NavigationRailDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: Text('Route Map'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Analytics'),
              ),
            ],
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