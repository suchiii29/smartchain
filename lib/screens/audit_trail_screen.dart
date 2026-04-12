import 'package:flutter/material.dart';
import '../services/audit_service.dart';
import '../models/audit_entry.dart';

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
      case 'alert_generated': return Colors.blue;
      case 'route_change': return Colors.orange;
      case 'risk_updated': return Colors.purple;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(title: const Text('🔍 Audit Trail')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text('Something went wrong. Please try again.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => setState(() => _hasError = false), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    try {
      final entries = AuditService.entries;

      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(
          title: const Text('🔍 Decision Audit Trail', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF161B22),
        ),
        body: entries.isEmpty
            ? const Center(
                child: Text(
                  'No AI decisions logged yet. Run AI Analysis to start.',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                                  color: Colors.white12,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Decision card
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Card(
                              color: const Color(0xFF161B22),
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.white10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            entry.decisionType.toUpperCase().replaceAll('_', ' '),
                                            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Text(
                                          _getTimeAgo(entry.timestamp),
                                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'AI Model: ${entry.aiModel}',
                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          const TextSpan(text: 'Input: ', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                                          TextSpan(text: entry.inputSummary, style: const TextStyle(color: Colors.white70)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          const TextSpan(text: 'Decision: ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          TextSpan(text: entry.outputDecision, style: const TextStyle(color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'MCP Tools: ${entry.mcpToolsCalled.join(", ")}',
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: entry.confidence,
                                              backgroundColor: Colors.white12,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                entry.confidence > 0.8 ? Colors.green : Colors.orange,
                                              ),
                                              minHeight: 6,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${(entry.confidence * 100).toStringAsFixed(0)}% Confidence',
                                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
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
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text('Something went wrong. Please try again.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => setState(() => _hasError = false), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
  }
}
