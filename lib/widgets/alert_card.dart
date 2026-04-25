import 'package:flutter/material.dart';
import '../models/disruption_alert.dart';
import '../theme/app_colors.dart';

class AlertCard extends StatelessWidget {
  final DisruptionAlert alert;
  final VoidCallback? onTap;

  const AlertCard({super.key, required this.alert, this.onTap});

  Color get _severityColor {
    switch (alert.severity.toLowerCase()) {
      case 'critical': return AppColors.error;
      case 'high': return AppColors.warning;
      case 'medium': return Colors.amber;
      case 'low': return AppColors.success;
      default: return AppColors.primary;
    }
  }

  IconData get _typeIcon {
    switch (alert.type.toLowerCase()) {
      case 'weather': return Icons.thunderstorm;
      case 'traffic': return Icons.traffic;
      case 'port_congestion': return Icons.anchor;
      case 'customs': return Icons.policy;
      case 'mechanical': return Icons.build;
      default: return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Alert: ${alert.type} for ${alert.affectedRoute}, Severity: ${alert.severity}, Recommendation: ${alert.recommendedAction}',
      child: Card(
        color: AppColors.cardAlt,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _severityColor.withValues(alpha: 0.3)),
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _severityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_typeIcon, color: _severityColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.affectedRoute,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            alert.type.toUpperCase().replaceAll('_', ' '),
                            style: const TextStyle(color: AppColors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _severityColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        alert.severity.toUpperCase(),
                        style: TextStyle(
                          color: _severityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  alert.recommendedAction,
                  style: const TextStyle(color: AppColors.white, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '+${alert.predictedDelayMinutes} min delay',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${(alert.confidence * 100).toStringAsFixed(0)}% confidence',
                      style: const TextStyle(color: AppColors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
