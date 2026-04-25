import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';
import 'screens/route_map_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/sustainability_screen.dart';
import 'screens/audit_trail_screen.dart';
import 'screens/forecast_screen.dart';
import 'screens/role_selection_screen.dart';
import 'theme/app_colors.dart';
import 'constants/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  runApp(const SmartChainApp());
}

class SmartChainApp extends StatelessWidget {
  const SmartChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: GoogleFonts.inter().fontFamily,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.surface,
        cardColor: AppColors.card,
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: AppColors.white.withValues(alpha: 0.1)),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
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
            backgroundColor: AppColors.surfaceDark,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: AppColors.primaryLight),
            selectedLabelTextStyle: const TextStyle(color: AppColors.primaryLight),
            unselectedIconTheme: const IconThemeData(color: AppColors.white38),
            unselectedLabelTextStyle: const TextStyle(color: AppColors.white38),
            leading: const Column(
              children: [
                SizedBox(height: 16),
                Icon(Icons.local_shipping, color: AppColors.primaryLight, size: 32),
                SizedBox(height: 8),
                Text('SmartChain', style: TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold)),
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
              NavigationRailDestination(
                icon: Icon(Icons.eco_outlined, color: AppColors.success),
                selectedIcon: Icon(Icons.eco, color: AppColors.success),
                label: Text('Carbon'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: Text('Audit'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.radar_outlined),
                selectedIcon: Icon(Icons.radar),
                label: Text('Forecast'),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text('v1.0.0', style: TextStyle(color: AppColors.white.withValues(alpha: 0.24), fontSize: 10)),
                ),
              ),
            ),
          ),
          VerticalDivider(thickness: 1, width: 1, color: AppColors.white.withValues(alpha: 0.12)),
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