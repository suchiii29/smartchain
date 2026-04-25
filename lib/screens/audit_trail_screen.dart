import 'package:flutter/material.dart';
import '../services/audit_service.dart';
import '../models/audit_entry.dart';
import '../theme/app_colors.dart';
import '../constants/app_strings.dart';
import '../widgets/error_screen.dart';

class AuditTrailScreen extends StatefulWidget {
  const AuditTrailScreen({Key? key}) : super(key: key);

  @override
  _AuditTrailScreenState createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends State<AuditTrailScreen> {
  bool _hasError = false;

  String _getTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'alert_generated':
        return AppColors.primary;
      case 'route_change':
        return AppColors.warning;
      case 'risk_updated':
        return AppColors.accent;
      default:
        return AppColors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final entries = AuditService.entries;

      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text('🔍 Audit Trail (${entries.length})',
              style: const TextStyle(color: AppColors.white)),
          backgroundColor: AppColors.card,
          iconTheme: const IconThemeData(color: AppColors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.white),
              onPressed: () {
                setState(() {});
              },
            ),
          ],
        ),
        body: entries.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history, color: Colors.white24, size: 64),
                    const SizedBox(height: 16),
                    const Text('No audit entries yet',
                        style: TextStyle(color: Colors.white54, fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text('Go to Dashboard and click Run AI Analysis',
                        style: TextStyle(color: Colors.white38)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary),
                      child: const Text('Refresh',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final color = _getTypeColor(entry.decisionType);

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Timeline decoration
                        Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            if (index != entries.length - 1)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color:
                                      AppColors.white.withValues(alpha: 0.12),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Decision card
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Semantics(
                              label:
                                  'Audit entry: ${entry.decisionType.replaceAll('_', ' ')}. AI Model: ${entry.aiModel}. Decision: ${entry.outputDecision}. Confidence: ${(entry.confidence * 100).toInt()}%',
                              child: Card(
                                color: AppColors.card,
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: AppColors.white
                                          .withValues(alpha: 0.1)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color:
                                                  color.withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              entry.decisionType
                                                  .toUpperCase()
                                                  .replaceAll('_', ' '),
                                              style: TextStyle(
                                                  color: color,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Text(
                                            _getTimeAgo(entry.timestamp),
                                            style: const TextStyle(
                                                color: AppColors.white70,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'AI Model: ${entry.aiModel}',
                                        style: const TextStyle(
                                            color: AppColors.white70,
                                            fontSize: 12),
                                      ),
                                      const SizedBox(height: 8),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            const TextSpan(
                                                text: 'Input: ',
                                                style: TextStyle(
                                                    color: AppColors.white,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            TextSpan(
                                                text: entry.inputSummary,
                                                style: const TextStyle(
                                                    color: AppColors.white70)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            const TextSpan(
                                                text: 'Decision: ',
                                                style: TextStyle(
                                                    color: AppColors.white,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            TextSpan(
                                                text: entry.outputDecision,
                                                style: const TextStyle(
                                                    color: AppColors.white)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'MCP Tools: ${entry.mcpToolsCalled.join(", ")}',
                                        style: const TextStyle(
                                            color: AppColors.white70,
                                            fontSize: 11),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: entry.confidence,
                                                backgroundColor: AppColors.white
                                                    .withValues(alpha: 0.12),
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  entry.confidence > 0.8
                                                      ? AppColors.success
                                                      : AppColors.warning,
                                                ),
                                                minHeight: 6,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '${(entry.confidence * 100).toStringAsFixed(0)}% Confidence',
                                            style: const TextStyle(
                                                color: AppColors.white70,
                                                fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      );
    } catch (e) {
      return ErrorScreen(message: e.toString());
    }
  }
}
