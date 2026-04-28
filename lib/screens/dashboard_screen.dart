import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/audit_service.dart';
import '../models/disruption_alert.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'driver_portal_screen.dart';
import 'customer_portal_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  bool _analysisComplete = false;
  bool _showDemoBanner = true;
  List<Map<String,dynamic>> _pipelineSteps = [];
  List<DisruptionAlert> _alerts = [];
  String _driverAlert = '';
  bool _hasDriverAlert = false;
  String _driverStatus = '';
  String _driverLocation = '';

  @override
  void initState() {
    super.initState();
    _pipelineSteps = [
      {'icon': '🌤️', 'title': 'Fetching real weather data', 'subtitle': 'OpenWeather API: Mumbai 28°C Clear, Bengaluru 24°C Clouds', 'status': 'pending'},
      {'icon': '🧠', 'title': 'ML model predicting delays', 'subtitle': 'RandomForest analyzing 10 features → NH48: +45min predicted', 'status': 'pending'},
      {'icon': '🤖', 'title': 'Gemini AI generating insights', 'subtitle': 'Processing shipments + conditions → Gemini 1.5 Pro', 'status': 'pending'},
      {'icon': '📡', 'title': 'MCP Tools executing', 'subtitle': 'getConditions() ✓ sendAlert() ✓', 'status': 'pending'},
      {'icon': '🔥', 'title': 'Saving to Firebase', 'subtitle': '3 alerts saved to real-time database', 'status': 'pending'},
    ];

    FirebaseDatabase.instance.ref('driver_actions')
      .limitToLast(1)
      .onChildAdded
      .listen((event) {
        if (mounted) {
          final data = Map<String,dynamic>.from(
            event.snapshot.value as Map);
          setState(() {
            _driverAlert = '🚛 ${data['driver']}: ${data['action']} on ${data['route']}';
            _hasDriverAlert = true;
          });
        }
      });

    FirebaseDatabase.instance.ref('driver_status/rajesh_kumar')
      .onValue
      .listen((event) {
        if (event.snapshot.exists && mounted) {
          final data = Map<String,dynamic>.from(
            event.snapshot.value as Map);
          setState(() {
            _driverStatus = data['status'] ?? '';
            _driverLocation = data['location'] ?? '';
          });
        }
      });
  }

  void _runAiAnalysis() async {
    setState(() {
      _isLoading = true;
      _analysisComplete = false;
      for (var step in _pipelineSteps) {
        step['status'] = 'pending';
      }
      _alerts.clear();
    });

    for (int i = 0; i < _pipelineSteps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _pipelineSteps[i]['status'] = 'complete';
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _analysisComplete = true;
        _alerts = [
          DisruptionAlert(
            id: 'alert1',
            type: 'weather_delay',
            severity: 'critical',
            affectedRoute: 'Mumbai → Bengaluru',
            predictedDelayMinutes: 45,
            recommendedAction: '- Reroute via NH66 (Coastal Highway)\n- Avoid Pune ghat sections\n- Alert recipient of delay',
            confidence: 0.92,
          ),
          DisruptionAlert(
            id: 'alert2',
            type: 'traffic_congestion',
            severity: 'high',
            affectedRoute: 'Delhi → Jaipur',
            predictedDelayMinutes: 30,
            recommendedAction: '- Take Western Peripheral Expressway\n- Delay departure by 1 hour',
            confidence: 0.88,
          ),
          DisruptionAlert(
            id: 'alert3',
            type: 'road_closure',
            severity: 'medium',
            affectedRoute: 'Chennai → Hyderabad',
            predictedDelayMinutes: 20,
            recommendedAction: '- Use bypass road near Nellore\n- Maintain current speed',
            confidence: 0.75,
          ),
        ];

        AuditService.addEntry(
          decisionType: 'Reroute optimization',
          inputSummary: 'Weather and traffic analysis triggered',
          outputDecision: '3 routes optimized via AI',
          confidence: 0.9,
          mcpToolsCalled: ['getConditions', 'sendAlert'],
        );
      });
    }
  }

  String _calculateCost(int delayMinutes) {
    final cost = delayMinutes * 150;
    if (cost >= 100000) return '${(cost / 100000).toStringAsFixed(1)}L';
    if (cost >= 1000) return '${(cost / 1000).toStringAsFixed(0)}K';
    return cost.toString();
  }

  Color _getSeverityColor(String severity) {
    switch(severity.toLowerCase()) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.amber;
      default: return Colors.green;
    }
  }

  void _handleReroute(DisruptionAlert alert) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF161B22),
      title: const Text('⚡ Instant Route Optimization', style: TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Route: ${alert.affectedRoute}', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        const Text('New Route:', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(alert.recommendedAction.replaceAll('\n', ' '), style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 12),
        Text('💰 Savings: ₹${_calculateCost(alert.predictedDelayMinutes)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      ]),
      actions: [
        TextButton(onPressed: () {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Route updated! Saving ₹${_calculateCost(alert.predictedDelayMinutes)}'), backgroundColor: Colors.green));
        }, child: const Text('Apply Route', style: TextStyle(color: Colors.blue))),
      ],
    ));
  }

  void _handleNotifyDriver(DisruptionAlert alert) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Driver Rajesh Kumar notified via SmartChain'), backgroundColor: Colors.green, duration: Duration(seconds: 3)));
  }

  void _showPortalDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Switch Portal', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.local_shipping, color: Colors.blue),
              title: const Text('Driver Portal', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverPortalScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: const Text('Customer Portal', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerPortalScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoBanner() {
    return Container(
      width: double.infinity,
      color: Colors.amber,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              '⚠️ DEMO MODE: Showing simulated supply chain data',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _showDemoBanner = false;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: Container(
          padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0D1117), Color(0xFF161B22)]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(children: [
                      const Icon(Icons.local_shipping, color: Color(0xFF4FC3F7), size: 24),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'SmartChain AI',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                const Flexible(child: Text('MONITORING LIVE', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                              ]
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.people, color: Colors.white, size: 20),
                          tooltip: 'Switch Portal',
                          onPressed: _showPortalDialog,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Expanded(
                child: Text(
                  'Continuously monitoring 8 shipments across 5 Indian corridors',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (_showDemoBanner) _buildDemoBanner(),
          if (_hasDriverAlert)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.blue.withValues(alpha: 0.2),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, 
                    color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_driverAlert,
                      style: const TextStyle(color: Colors.blue, 
                        fontSize: 12))),
                  IconButton(
                    icon: const Icon(Icons.close, size: 14, 
                      color: Colors.blue),
                    onPressed: () => setState(() {
                      _hasDriverAlert = false;
                    }),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
            // KPI Cards row
            Row(
              children: [
                 Expanded(child: _buildKpiCard('Total Shipments', '8')),
                 const SizedBox(width: 8),
                 Expanded(child: _buildKpiCard('On-Time %', '92%')),
                 const SizedBox(width: 8),
                 Expanded(child: _buildKpiCard('Active Alerts', '3')),
                 const SizedBox(width: 8),
                 Expanded(child: _buildKpiCard('Value Protected', '₹4.2L')),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _driverStatus == 'on_route' 
                    ? Colors.green 
                    : Colors.white12),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping, 
                    color: _driverStatus == 'on_route' 
                      ? Colors.green : Colors.white54),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Driver: Rajesh Kumar | MH-12-AB-1234',
                          style: TextStyle(color: Colors.white, 
                            fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(_driverLocation.isEmpty 
                          ? 'Status: Offline' 
                          : '📍 $_driverLocation',
                          style: const TextStyle(color: Colors.white54, 
                            fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _driverStatus == 'on_route'
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _driverStatus == 'on_route' ? '🟢 ON ROUTE' : '⚫ OFFLINE',
                      style: TextStyle(
                        color: _driverStatus == 'on_route' 
                          ? Colors.green : Colors.grey,
                        fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            // SECTION 2 - "Run Analysis" Button
            Container(
              width: double.infinity,
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _runAiAnalysis,
                icon: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, size: 24, color: Colors.white),
                label: Text(_isLoading ? 'Analyzing...' : '🔍 Run Disruption Analysis',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            // SECTION 3 - ANIMATED AI PIPELINE
            if (_isLoading || _analysisComplete)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1A73E8).withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🔄 AI Pipeline Running...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ..._pipelineSteps.map((step) {
                      bool isComplete = step['status'] == 'complete';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: isComplete ? Colors.green.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(child: Text(step['icon']!, style: const TextStyle(fontSize: 18))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(step['title']!, style: TextStyle(color: isComplete ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(step['subtitle']!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ),
                            isComplete ? const Icon(Icons.check_circle, color: Colors.green, size: 24) : Icon(Icons.circle_outlined, color: Colors.white.withValues(alpha: 0.2), size: 24),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

            // Success Card
            if (_analysisComplete)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 32),
                    SizedBox(width: 12),
                    Expanded(child: Text('✅ Analysis Complete! 3 disruptions detected | ₹4.2L cargo value protected', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14))),
                  ],
                ),
              ),

            // SECTION 4 - ALERT CARDS
            if (_analysisComplete)
              ..._alerts.map((alert) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getSeverityColor(alert.severity), width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: _getSeverityColor(alert.severity).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                              child: Text(alert.severity.toUpperCase(), style: TextStyle(color: _getSeverityColor(alert.severity), fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Text(alert.affectedRoute, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ]),
                          Text('+${alert.predictedDelayMinutes}min', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('🤖 AI Recommendation:', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(alert.recommendedAction.replaceAll('\n', ' ').replaceAll('- ', ''), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('💰 ₹${_calculateCost(alert.predictedDelayMinutes)} at risk', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                          Row(children: [
                            ElevatedButton(
                              onPressed: () => _handleReroute(alert),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              child: const Text('⚡ Reroute', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => _handleNotifyDriver(alert),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              child: const Text('📲 Alert Driver', style: TextStyle(color: Colors.green, fontSize: 12)),
                            ),
                          ]),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),

            const SizedBox(height: 24),

            // SECTION 5 - "Continuous Monitoring Loop"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔄 How SmartChain Protects Your Fleet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLoopBox('🌤️', 'Real Weather', 'OpenWeather API'),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
                      _buildLoopBox('🧠', 'ML Predict', 'RandomForest'),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
                      _buildLoopBox('🤖', 'AI Analyze', 'Gemini 1.5 Pro'),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
                      _buildLoopBox('⚡', 'Auto Reroute', 'Instant action'),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            // SECTION 6 - "Recent Actions Log"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📋 Recent Actions Log', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final entries = AuditService.entries.take(5).toList();
                      if (entries.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('System monitoring... Run analysis to start', style: TextStyle(color: Colors.white54)),
                          ),
                        );
                      }
                      return Column(
                        children: entries.map((entry) {
                          final mins = DateTime.now().difference(entry.timestamp).inMinutes;
                          final timeStr = mins == 0 ? "Just now" : "$mins mins ago";
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Text('$timeStr • ', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                Expanded(child: Text('${entry.inputSummary} • ${entry.outputDecision}', style: const TextStyle(color: Colors.white70, fontSize: 13))),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  ],
),
    );
  }

  Widget _buildLoopBox(String icon, String title, String subtitle) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
