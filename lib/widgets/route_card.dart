import 'package:flutter/material.dart';
import '../models/shipment.dart';
import '../theme/app_colors.dart';

class RouteCard extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback? onTap;

  const RouteCard({super.key, required this.shipment, this.onTap});

  Color get _statusColor {
    switch (shipment.status) {
      case 'on_time': return AppColors.success;
      case 'delayed': return AppColors.warning;
      case 'critical': return AppColors.error;
      default: return AppColors.white38;
    }
  }

  String get _statusLabel {
    switch (shipment.status) {
      case 'on_time': return 'ON TIME';
      case 'delayed': return 'DELAYED';
      case 'critical': return 'CRITICAL';
      default: return shipment.status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final etaFormatted =
        '${shipment.eta.day}/${shipment.eta.month} ${shipment.eta.hour.toString().padLeft(2, '0')}:${shipment.eta.minute.toString().padLeft(2, '0')}';

    return Card(
      color: AppColors.cardAlt,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _statusColor.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_shipping, color: _statusColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${shipment.origin}  →  ${shipment.destination}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _infoChip(Icons.badge, shipment.id, AppColors.white70),
                  const SizedBox(width: 10),
                  _infoChip(Icons.category, shipment.cargoType, AppColors.white70),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoChip(Icons.business, shipment.carrier, AppColors.white38),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: AppColors.white38),
                      const SizedBox(width: 4),
                      Text(
                        'ETA $etaFormatted',
                        style: const TextStyle(color: AppColors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              if (shipment.delayMinutes > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+${shipment.delayMinutes} min delay',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
