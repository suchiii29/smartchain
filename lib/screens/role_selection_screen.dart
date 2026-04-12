import 'package:flutter/material.dart';
import '../services/role_manager.dart';
import '../main.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  void _selectRole(BuildContext context, String role) {
    RoleManager.currentRole = role;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
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
                color: Color(0xFF1A73E8),
              ),
              const SizedBox(height: 16),
              const Text(
                'SmartChain AI',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Intelligent Supply Chain Platform',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Select Your Portal',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              _buildRoleCard(
                context: context,
                role: 'driver',
                icon: Icons.local_shipping,
                iconColor: const Color(0xFF1A73E8),
                title: 'Driver Portal',
                subtitle: 'View routes and delivery alerts',
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                context: context,
                role: 'manager',
                icon: Icons.dashboard,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Manager Portal',
                subtitle: 'Monitor all shipments and AI analysis',
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                context: context,
                role: 'customer',
                icon: Icons.person,
                iconColor: const Color(0xFF34A853),
                title: 'Customer Portal',
                subtitle: 'Track your orders in real time',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String role,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: () => _selectRole(context, role),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
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
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}
