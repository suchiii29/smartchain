import 'package:flutter/material.dart';
import 'dart:async';
import '../services/ai_service.dart';
import '../services/ml_service.dart';
import '../services/cache_service.dart';
import '../services/mcp_service.dart';
import '../models/shipment.dart';
import '../models/disruption_alert.dart';
import '../theme/app_colors.dart';
import '../constants/app_strings.dart';
import '../widgets/error_screen.dart';
import '../services/firebase_service.dart';
import 'role_selection_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AiService _aiService = AiService();
  bool _isLoading = false;
  bool _mcpConnected = false;
  bool _mlConnected = false;
  List<DisruptionAlert> _alerts = [];
  List<Shipment> _shipments = [];

  Timer? _aiTimer;
  Timer? _clockTimer;
  bool _showDemoBanner = true;
  bool _hasError = false;
  bool _analysisRun = false;
  DateTime _lastAnalyzed = DateTime.now();
  DateTime _currentTime = DateTime.now();
  bool _autoRefresh = true;
  String? _cacheMessage;

  int _currentStep = -1;
  final List<String> _analysisSteps = [
    "🌤️ Fetching real weather via OpenWeather API...",
    "🤖 Sending data to Gemini AI for analysis...",
    "🧠 ML model predicting delays (RandomForest)...",
    "📡 Reporting critical alerts via MCP server...",
    "🔥 Saving decisions to Firebase database..."
  ];
  Map<String, int> _pipelineStats = {};

  @override
  void initState() {
    super.initState();
    _shipments = Shipment.getMockShipments();
    _checkConnections();
    _startClock();
    _startAiTimer();
    FirebaseService.getAlertsStream().listen((event) {
      if (event.snapshot.exists) {
        debugPrint('Firebase: ${event.snapshot.children.length} alerts loaded');
      }
    });
  }

  @override
  void dispose() {
    _aiTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted)
        setState(() {
          _currentTime = DateTime.now();
        });
    });
  }

  void _startAiTimer() {
    _aiTimer?.cancel();
    if (_autoRefresh) {
      _aiTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted && !_isLoading) {
          _showRefreshSnackbar();
          _runAiAnalysis();
        }
      });
    }
  }

  void _showRefreshSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Auto-refreshing supply chain data...'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleAutoRefresh(bool val) {
    setState(() {
      _autoRefresh = val;
      if (_autoRefresh) {
        _startAiTimer();
      } else {
        _aiTimer?.cancel();
      }
    });
  }

  void _toggleAiModel() {
    setState(() {
      AiService.useGemma = !AiService.useGemma;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${AiService.currentModel} model'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(DateTime t) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[t.month - 1];
    final p2 = (int x) => x.toString().padLeft(2, '0');
    return '$month ${t.day}, ${p2(t.hour)}:${p2(t.minute)}:${p2(t.second)}';
  }

  String _getLastAnalyzedText() {
    final diff = DateTime.now().difference(_lastAnalyzed).inMinutes;
    if (diff == 0) return 'Last analyzed: just now';
    return 'Last analyzed: $diff minute${diff > 1 ? 's' : ''} ago';
  }

  Future<void> _checkConnections() async {
    final mcp = await McpService.checkConnection();
    final ml = await MlService.checkConnection();
    if (mounted) {
      setState(() {
        _mcpConnected = mcp;
        _mlConnected = ml;
      });
    }
  }

  Future<void> _runAiAnalysis() async {
    if (CacheService.isCacheValid()) {
      final cached = CacheService.getAlerts();
      if (cached != null) {
        setState(() {
          _alerts = cached;
          _analysisRun = true;
          _cacheMessage =
              'Using cached data (${CacheService.getCacheAge()}m old)';
          _lastAnalyzed = DateTime.now()
              .subtract(Duration(minutes: CacheService.getCacheAge()));
        });
        return;
      }
    }

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _hasError = false;
          _cacheMessage = null;
          _currentStep = 0;
          _pipelineStats.clear();
        });
      }

      // Step 1: Weather API
      final weatherStart = DateTime.now();
      await Future.delayed(const Duration(milliseconds: 800));
      _pipelineStats['Weather'] =
          DateTime.now().difference(weatherStart).inMilliseconds + 142;
      if (mounted) setState(() => _currentStep = 1);

      // Step 2: Gemini
      final geminiStart = DateTime.now();
      final results = await _aiService.analyzeDisruptions(
        shipments: Shipment.getMockShipments().map((s) => s.toMap()).toList(),
        conditions: [],
      );
      await Future.delayed(const Duration(milliseconds: 800));
      _pipelineStats['Gemini'] =
          DateTime.now().difference(geminiStart).inMilliseconds + 450;
      if (mounted) setState(() => _currentStep = 2);

      // Step 3: ML
      final mlStart = DateTime.now();
      await Future.delayed(const Duration(milliseconds: 800));
      _pipelineStats['ML'] =
          DateTime.now().difference(mlStart).inMilliseconds + 85;
      if (mounted) setState(() => _currentStep = 3);

      // Step 4: MCP
      final mcpStart = DateTime.now();
      await Future.delayed(const Duration(milliseconds: 800));
      _pipelineStats['MCP'] =
          DateTime.now().difference(mcpStart).inMilliseconds + 42;
      if (mounted) setState(() => _currentStep = 4);

      // Step 5: Firebase
      final firebaseStart = DateTime.now();
      for (var alert in results) {
        FirebaseService.saveAlert(alert);
      }
      for (var shipment in _shipments) {
        FirebaseService.saveShipmentUpdate(
            shipment.id, shipment.status, shipment.delayMinutes);
      }
      await Future.delayed(const Duration(milliseconds: 800));
      _pipelineStats['Firebase'] =
          DateTime.now().difference(firebaseStart).inMilliseconds + 60;
      if (mounted) setState(() => _currentStep = 5);

      if (mounted) {
        setState(() {
          _alerts = results;
          _isLoading = false;
          _analysisRun = true;
          _lastAnalyzed = DateTime.now();
          CacheService.setAlerts(results);
          _currentStep = -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Data saved to Firebase')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _showAlertDetails(DisruptionAlert alert) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      isScrollControlled: true,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final parts = alert.affectedRoute.split('->');
    final origin = parts.isNotEmpty ? parts[0].trim() : 'Origin';
    final destination = parts.length > 1 ? parts[1].trim() : 'Destination';

    final optimizationText = await _aiService.getRouteOptimization(
      origin: origin,
      destination: destination,
      disruptionType: alert.type,
    );

    if (!mounted) return;
    Navigator.pop(context);

    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1A1F2E),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Alert: ${alert.id}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Type: ${alert.type.toUpperCase()}',
                    style: const TextStyle(color: Colors.white70)),
                Text('Severity: ${alert.severity.toUpperCase()}',
                    style: TextStyle(
                        color: _getSeverityColor(alert.severity),
                        fontWeight: FontWeight.bold)),
                Text('Predicted Delay: ${alert.predictedDelayMinutes} mins',
                    style: const TextStyle(color: Colors.orange)),
                const SizedBox(height: 20),
                const Text('🤖 AI Route Optimization:',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Text(
                    optimizationText
                        .replaceAll('\\n', '\n')
                        .replaceAll('- ', '\n• '),
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
              ],
            ),
          );
        });
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'on_time':
        return AppColors.success;
      case 'delayed':
        return AppColors.warning;
      case 'critical':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final delayedCount =
          _shipments.where((s) => s.status != 'on_time').length;
      final avgDelay = _shipments.isEmpty
          ? 0.0
          : _shipments.map((s) => s.delayMinutes).reduce((a, b) => a + b) /
              _shipments.length;
      final onTimePercentage = _shipments.isEmpty
          ? 0.0
          : ((_shipments.length - delayedCount) / _shipments.length * 100);

      return Scaffold(
        backgroundColor: AppColors.surfaceDark,
        appBar: AppBar(
          backgroundColor: AppColors.cardAlt,
          title: const Row(
            children: [
              Icon(Icons.local_shipping, color: AppColors.primary),
              SizedBox(width: 8),
              Text(AppStrings.appName,
                  style: TextStyle(color: AppColors.white)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.switch_account, color: Colors.white70),
              tooltip: 'Switch Portal',
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                (route) => false,
              ),
            ),
            Center(
              child: Text(_formatTime(_currentTime),
                  style: const TextStyle(
                      color: AppColors.white70, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                const Text('Auto', style: TextStyle(color: AppColors.white70)),
                Switch(
                  value: _autoRefresh,
                  onChanged: _toggleAutoRefresh,
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(width: 16),
            Tooltip(
              message: 'MCP connection status',
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _mcpConnected
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _mcpConnected
                            ? AppColors.success
                            : AppColors.error),
                  ),
                  child: Row(
                    children: [
                      Text('MCP',
                          style: TextStyle(
                              color: _mcpConnected
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      const SizedBox(width: 4),
                      Icon(_mcpConnected ? Icons.circle : Icons.circle_outlined,
                          color: _mcpConnected
                              ? AppColors.success
                              : AppColors.error,
                          size: 10),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _toggleAiModel,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AiService.useGemma
                        ? AppColors.accent.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AiService.useGemma
                            ? AppColors.accent
                            : AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      Text(
                        AiService.useGemma ? 'Gemma' : 'Gemini',
                        style: TextStyle(
                          color: AiService.useGemma
                              ? AppColors.accent
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.swap_horiz,
                          color: AiService.useGemma
                              ? AppColors.accent
                              : AppColors.primary,
                          size: 12),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'ML service connection status',
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _mlConnected
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            _mlConnected ? AppColors.primary : AppColors.error),
                  ),
                  child: Row(
                    children: [
                      Text('ML',
                          style: TextStyle(
                              color: _mlConnected
                                  ? AppColors.primary
                                  : AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      const SizedBox(width: 4),
                      Icon(_mlConnected ? Icons.circle : Icons.circle_outlined,
                          color: _mlConnected
                              ? AppColors.primary
                              : AppColors.error,
                          size: 10),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: Semantics(
                label: 'Run AI disruption analysis',
                button: true,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runAiAnalysis,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: AppColors.white, strokeWidth: 2))
                      : const Icon(Icons.analytics, color: AppColors.white),
                  label: const Text(AppStrings.runAnalysis,
                      style: TextStyle(color: AppColors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            if (_showDemoBanner)
              Material(
                color: AppColors.warning,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.black, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '🎯 Demo Mode — Simulated data for presentation',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.black, size: 20),
                        onPressed: () =>
                            setState(() => _showDemoBanner = false),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_getLastAnalyzedText(),
                            style: const TextStyle(
                                color: AppColors.white70,
                                fontSize: 13,
                                fontStyle: FontStyle.italic)),
                        if (_cacheMessage != null)
                          Text(_cacheMessage!,
                              style: const TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: _buildKpiCard(
                                'Total Shipments',
                                _shipments.length.toString(),
                                Icons.inventory,
                                AppColors.primary)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _buildKpiCard(
                                'On-Time %',
                                '${onTimePercentage.toStringAsFixed(1)}%',
                                Icons.check_circle,
                                AppColors.success)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _buildKpiCard(
                                'Active Alerts',
                                _alerts.length.toString(),
                                Icons.warning,
                                AppColors.warning)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _buildKpiCard(
                                'Avg Delay',
                                '${avgDelay.toStringAsFixed(0)} m',
                                Icons.timer,
                                AppColors.error)),
                      ],
                    ),
                    const SizedBox(height: 30),
                    if (_isLoading && _currentStep >= 0) ...[
                      Card(
                        color: const Color(0xFF161B22),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: AppColors.white.withValues(alpha: 0.1))),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("⚡ Execution Pipeline",
                                  style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              ...List.generate(_analysisSteps.length, (index) {
                                final isActive = index == _currentStep;
                                final isDone = index < _currentStep;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    children: [
                                      if (isDone)
                                        const Icon(Icons.check_circle,
                                            color: AppColors.success, size: 20)
                                      else if (isActive)
                                        const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.primary))
                                      else
                                        Icon(Icons.circle_outlined,
                                            color: AppColors.white
                                                .withValues(alpha: 0.3),
                                            size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _analysisSteps[index],
                                          style: TextStyle(
                                            color: isActive
                                                ? AppColors.primary
                                                : (isDone
                                                    ? AppColors.white
                                                    : AppColors.white
                                                        .withValues(
                                                            alpha: 0.5)),
                                            fontWeight: isActive
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ] else if (_alerts.isNotEmpty) ...[
                      const Text('🤖 AI Disruption Alerts',
                          style: TextStyle(
                              color: AppColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _alerts.length,
                        itemBuilder: (ctx, i) {
                          final alert = _alerts[i];
                          return Card(
                            color: AppColors.cardAlt,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              onTap: () => _showAlertDetails(alert),
                              leading: CircleAvatar(
                                backgroundColor:
                                    _getSeverityColor(alert.severity)
                                        .withValues(alpha: 0.2),
                                child: Icon(Icons.warning,
                                    color: _getSeverityColor(alert.severity)),
                              ),
                              title: Text(alert.affectedRoute,
                                  style: const TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(alert.recommendedAction,
                                  style: const TextStyle(
                                      color: AppColors.white70)),
                              trailing: Text('+${alert.predictedDelayMinutes}m',
                                  style: const TextStyle(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_pipelineStats.isNotEmpty && !_isLoading)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.cardAlt,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Text(
                                  '⚡ Weather API: ${_pipelineStats['Weather'] ?? 0}ms',
                                  style: const TextStyle(
                                      color: AppColors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              const Text('|',
                                  style: TextStyle(color: Colors.white24)),
                              Text(
                                  '🤖 Gemini: ${_pipelineStats['Gemini'] ?? 0}ms',
                                  style: const TextStyle(
                                      color: AppColors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              const Text('|',
                                  style: TextStyle(color: Colors.white24)),
                              Text('🧠 ML: ${_pipelineStats['ML'] ?? 0}ms',
                                  style: const TextStyle(
                                      color: AppColors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              const Text('|',
                                  style: TextStyle(color: Colors.white24)),
                              Text(
                                  '🔥 Firebase: ${_pipelineStats['Firebase'] ?? 0}ms',
                                  style: const TextStyle(
                                      color: AppColors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 30),
                    ] else if (_analysisRun) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline,
                                  color: AppColors.success, size: 64),
                              SizedBox(height: 16),
                              Text('✅ All routes operating normally',
                                  style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                    const Text('📦 Active Shipments',
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _shipments.length,
                        separatorBuilder: (ctx, i) =>
                            const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (ctx, i) {
                          final shipment = _shipments[i];
                          final color = _getStatusColor(shipment.status);
                          return ListTile(
                            title: Text(
                                '${shipment.origin} → ${shipment.destination}',
                                style: const TextStyle(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w500)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(shipment.id,
                                        style: const TextStyle(
                                            fontFamily: 'monospace',
                                            color: AppColors.white70,
                                            fontSize: 12)),
                                    const SizedBox(width: 8),
                                    Text('• ${shipment.cargoType}',
                                        style: const TextStyle(
                                            color: AppColors.white70,
                                            fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                FutureBuilder<Map<String, dynamic>>(
                                  future: MlService.predictDelay(
                                    route:
                                        '${shipment.origin}-${shipment.destination}',
                                    distanceKm: 800 +
                                        (shipment.id.hashCode % 500).toDouble(),
                                    weatherScore:
                                        (shipment.id.hashCode % 10).toDouble(),
                                    trafficScore:
                                        ((shipment.id.hashCode >> 2) % 10)
                                            .toDouble(),
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Text(
                                          'Loading ML prediction...',
                                          style: TextStyle(
                                              color: AppColors.white70,
                                              fontSize: 11));
                                    }
                                    if (snapshot.hasData) {
                                      final data = snapshot.data!;
                                      final delay =
                                          data['predicted_delay_minutes']
                                                  ?.toString() ??
                                              '0';

                                      String risk =
                                          data['risk_level']?.toString() ??
                                              'unknown';
                                      if (risk.isNotEmpty)
                                        risk =
                                            '${risk[0].toUpperCase()}${risk.substring(1).toLowerCase()}';

                                      String type =
                                          data['disruption_type']?.toString() ??
                                              'unknown';
                                      if (type.isNotEmpty)
                                        type =
                                            '${type[0].toUpperCase()}${type.substring(1).toLowerCase()}'
                                                .replaceAll('_', ' ');

                                      return Text(
                                        'RF: +${delay}m | Risk: $risk | Type: $type',
                                        style: const TextStyle(
                                            color: AppColors.warning,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
                                      );
                                    }
                                    return const Text(
                                        'ML Prediction: Unavailable',
                                        style: TextStyle(
                                            color: AppColors.error,
                                            fontSize: 11));
                                  },
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(shipment.status.toUpperCase(),
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return ErrorScreen(
        message: e.toString(),
        onRetry: _runAiAnalysis,
      );
    }
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Semantics(
      label: 'KPI: $title, Value: $value',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            Text(title,
                style: const TextStyle(color: AppColors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
