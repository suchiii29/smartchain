import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../theme/app_colors.dart';
import '../services/shipment_state_service.dart';

class CustomerPortalScreen extends StatefulWidget {
  const CustomerPortalScreen({super.key});

  @override
  State<CustomerPortalScreen> createState() => _CustomerPortalScreenState();
}

class _CustomerPortalScreenState extends State<CustomerPortalScreen> {
  double _truckPosition = 0.1;
  Timer? _timer;
  final TextEditingController _issueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ShipmentStateService.initialize();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _truckPosition += 0.05;
          if (_truckPosition > 0.9) _truckPosition = 0.1;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _issueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          "📦 Track Your Order",
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.white),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Tracking Card
            _buildOrderTrackingCard(),
            const SizedBox(height: 24),

            // Progress Tracker
            const Text(
              "Delivery Progress",
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildProgressTracker(),
            const SizedBox(height: 32),

            // Delivery Info
            _buildDeliveryInfo(),
            const SizedBox(height: 24),

            // AI Update Card
            _buildAIUpdateCard(),
            const SizedBox(height: 40),

            // Action Buttons
            Row(
              children: [
                Expanded(child: _buildSupportButton(context)),
                const SizedBox(width: 12),
                Expanded(child: _buildReportIssueButton(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTrackingCard() {
    final shipment = ShipmentStateService.shipments.first;
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order ID: ${shipment.id}",
                    style: const TextStyle(color: AppColors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shipment.cargoType,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _buildPulsingStatus(),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: AppColors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("FROM",
                        style:
                            TextStyle(color: AppColors.white38, fontSize: 10)),
                    Text(shipment.origin,
                        style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Icon(Icons.map, color: AppColors.white38, size: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("TO",
                        style:
                            TextStyle(color: AppColors.white38, fontSize: 10)),
                    Text(shipment.destination,
                        style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingStatus() {
    final shipment = ShipmentStateService.shipments.first;
    Color statusColor = AppColors.success;
    String statusText = "ON TIME";

    if (shipment.status == 'delayed') {
      statusColor = AppColors.warning;
      statusText = "DELAYED";
    } else if (shipment.status == 'critical') {
      statusColor = AppColors.error;
      statusText = "CRITICAL";
    }

    return Row(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.4, end: 1.0),
          duration: const Duration(milliseconds: 1000),
          builder: (context, value, child) {
            return Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: value),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: value * 0.5),
                    blurRadius: 4,
                    spreadRadius: 2,
                  ),
                ],
              ),
            );
          },
          onEnd: () {},
        ),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTracker() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildProgressStep(Icons.check_circle, "Placed", true),
                _buildProgressLine(true),
                _buildProgressStep(Icons.check_circle, "Picked", true),
                _buildProgressLine(true),
                _buildProgressStep(Icons.sync, "Transit", true,
                    isCurrent: true),
                _buildProgressLine(false),
                _buildProgressStep(
                    Icons.local_shipping_outlined, "Delivery", false),
                _buildProgressLine(false),
                _buildProgressStep(Icons.inventory_2_outlined, "Done", false),
              ],
            ),
            AnimatedPositioned(
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              left: (constraints.maxWidth - 28) * _truckPosition,
              top: -12,
              child: const Icon(Icons.local_shipping,
                  color: AppColors.primaryLight, size: 28),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressStep(IconData icon, String label, bool isCompleted,
      {bool isCurrent = false}) {
    return Column(
      children: [
        Icon(
          icon,
          color: isCompleted ? AppColors.success : AppColors.white38,
          size: isCurrent ? 28 : 24,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isCompleted ? AppColors.white : AppColors.white38,
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isCompleted
            ? AppColors.success
            : AppColors.white.withValues(alpha: 0.12),
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Estimated Delivery",
                style: TextStyle(color: AppColors.white70, fontSize: 14),
              ),
              Icon(Icons.event, color: AppColors.primaryLight, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Text(
                "Today by 6:00 PM",
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.error, size: 16),
                SizedBox(width: 8),
                Text(
                  "Delayed by 3 hours due to weather",
                  style: TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIUpdateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.accent.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("🤖", style: TextStyle(fontSize: 24)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI Update",
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Your package is on an optimized route. Expected to arrive on time despite weather conditions.",
                  style: TextStyle(
                      color: AppColors.white70, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF161B22),
            title: const Text('📞 Contact Support',
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  leading: Icon(Icons.phone, color: Colors.green),
                  title: Text('Call: 1800-SMART-AI',
                      style: TextStyle(color: Colors.white)),
                ),
                const ListTile(
                  leading: Icon(Icons.email, color: Colors.blue),
                  title: Text('support@smartchain.ai',
                      style: TextStyle(color: Colors.white)),
                ),
                const ListTile(
                  leading: Icon(Icons.chat, color: Colors.purple),
                  title: Text('Live Chat (Available 24/7)',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:
                    const Text('Close', style: TextStyle(color: Colors.blue)),
              )
            ],
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primaryLight),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        "Contact\nSupport",
        textAlign: TextAlign.center,
        style: TextStyle(
            color: AppColors.primaryLight,
            fontSize: 14,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildReportIssueButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF161B22),
            title: const Text('⚠️ Report Issue',
                style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: _issueController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Describe the issue...',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38)),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white70)),
              ),
              TextButton(
                onPressed: () async {
                  if (_issueController.text.isNotEmpty) {
                    try {
                      await FirebaseDatabase.instance
                          .ref()
                          .child('issues')
                          .push()
                          .set({
                        'orderId': 'ORD-2024-001',
                        'description': _issueController.text,
                        'timestamp': DateTime.now().toIso8601String(),
                      });
                    } catch (e) {
                      debugPrint('Database error: $e');
                    }
                  }
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Issue reported successfully')),
                    );
                    _issueController.clear();
                  }
                },
                child: const Text('Submit',
                    style: TextStyle(color: AppColors.error)),
              )
            ],
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.error.withValues(alpha: 0.2),
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        "Report\nIssue",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}
