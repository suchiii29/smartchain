import 'package:flutter/material.dart';
import '../services/role_manager.dart';
import '../main.dart';
import '../theme/app_colors.dart';
import '../constants/app_strings.dart';
import '../widgets/error_screen.dart';
import 'driver_portal_screen.dart';
import 'customer_portal_screen.dart';


class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _selectRole(BuildContext context, String role) {
    RoleManager.currentRole = role;
    
    Widget nextScreen;
    switch (role) {
      case 'driver':
        nextScreen = const DriverPortalScreen();
        break;
      case 'customer':
        nextScreen = const CustomerPortalScreen();
        break;
      case 'manager':
      default:
        nextScreen = const AppShell();
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_shipping,
                  size: 60,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Intelligent Supply Chain Platform',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.white70,
                  ),
                ),
                const SizedBox(height: 48),
                const Text(
                  'Select Your Portal',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                _buildRoleCard(
                  context: context,
                  role: 'driver',
                  icon: Icons.local_shipping,
                  iconColor: AppColors.primary,
                  title: 'Driver Portal',
                  subtitle: 'View routes and delivery alerts',
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  context: context,
                  role: 'manager',
                  icon: Icons.dashboard,
                  iconColor: AppColors.accent,
                  title: 'Manager Portal',
                  subtitle: 'Monitor all shipments and AI analysis',
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  context: context,
                  role: 'customer',
                  icon: Icons.person,
                  iconColor: AppColors.success,
                  title: 'Customer Portal',
                  subtitle: 'Track your orders in real time',
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return ErrorScreen(message: e.toString());
    }
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String role,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Semantics(
      label: 'Select $title: $subtitle',
      button: true,
      child: InkWell(
        onTap: () => _selectRole(context, role),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 40, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: AppColors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
