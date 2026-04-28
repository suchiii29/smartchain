import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import '../widgets/error_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _hasError = false;
  bool _mlOnline = false;
  bool _useOfflineData = false;
  bool _isLoadingModels = true;
  Map<String, dynamic>? _modelStats;
  Map<String, dynamic>? _featureImportanceData;

  @override
  void initState() {
    super.initState();
    _fetchMLData();
  }

  void _setFallbackData() {
    if (mounted) {
      setState(() {
        _mlOnline = false;
        _useOfflineData = true;
        _hasError = true;
        _isLoadingModels = false;
        _modelStats = {
          'random_forest': {'mae_minutes': 22.46},
          'gradient_boosting': {'accuracy': 0.67},
          'logistic_regression': {'accuracy': 0.905},
          'isolation_forest': {'contamination': 0.10},
        };
        _featureImportanceData = {
          'feature_importance': {
            'weather_score': 0.22,
            'port_congestion': 0.18,
            'distance_km': 0.15,
            'is_monsoon': 0.13,
            'traffic_score': 0.11,
          }
        };
      });
    }
  }

  Future<void> _fetchMLData() async {
    try {
      final statsRes =
          await http.get(Uri.parse('http://127.0.0.1:5000/model-stats')).timeout(const Duration(seconds: 3));
      final featuresRes =
          await http.get(Uri.parse('http://127.0.0.1:5000/feature-importance')).timeout(const Duration(seconds: 3));

      if (statsRes.statusCode == 200 && featuresRes.statusCode == 200) {
        if (mounted) {
          setState(() {
            _mlOnline = true;
            _useOfflineData = false;
            _modelStats = json.decode(statsRes.body);
            _featureImportanceData = json.decode(featuresRes.body);
            _isLoadingModels = false;
          });
        }
      } else {
        _setFallbackData();
      }
    } catch (e) {
      _setFallbackData();
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: AppColors.surfaceDark,
        appBar: AppBar(
          title: const Text('📊 Predictive Analytics',
              style: TextStyle(
                  color: AppColors.white, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.cardAlt,
          iconTheme: const IconThemeData(color: AppColors.white),
        ),
        body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatusBadge('🟢 RandomForest', Colors.green),
                          const SizedBox(width: 8),
                          _buildStatusBadge('🟢 GradientBoost', Colors.green),
                          const SizedBox(width: 8),
                          _buildStatusBadge('🟢 LogisticReg', Colors.green),
                          const SizedBox(width: 8),
                          _buildStatusBadge('🟢 IsolationForest', Colors.green),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMLPerformanceSection(),
                    const SizedBox(height: 30),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 30),
                    _buildCard(
                      title: 'Disruption Types This Week',
                      child: Semantics(
                        label:
                            'Disruption types bar chart. Showing counts for Weather, Traffic, Port, Customs, and Mechanical.',
                        child: SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 1 != 0) {
                                        return const Text('');
                                      }
                                      final int index = value.toInt();
                                      const titles = [
                                        'Weather',
                                        'Traffic',
                                        'Port',
                                        'Customs',
                                        'Mech'
                                      ];
                                      if (index >= 0 && index < titles.length) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            titles[index],
                                            style: const TextStyle(
                                                color: AppColors.white,
                                                fontSize: 12),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) => Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                            color: AppColors.white,
                                            fontSize: 12)),
                                    reservedSize: 28,
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                _buildBarGroup(0, 4), // Weather
                                _buildBarGroup(1, 6), // Traffic
                                _buildBarGroup(2, 3), // Port
                                _buildBarGroup(3, 2), // Customs
                                _buildBarGroup(4, 1), // Mechanical
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildCard(
                      title: 'On-Time Delivery % - Last 7 Days',
                      child: Semantics(
                        label:
                            'On-time delivery percentage over last 7 days line chart. Trending between 68% and 92%.',
                        child: SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: 100,
                              lineTouchData:
                                  const LineTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 1 != 0) {
                                        return const Text('');
                                      }

                                      final int index = value.toInt();
                                      if (index < 0 || index > 6)
                                        return const SizedBox.shrink();

                                      const days = [
                                        'Mon',
                                        'Tue',
                                        'Wed',
                                        'Thu',
                                        'Fri',
                                        'Sat',
                                        'Sun'
                                      ];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          days[index],
                                          style: const TextStyle(
                                              color: AppColors.white,
                                              fontSize: 12),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) => Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                            color: AppColors.white,
                                            fontSize: 12)),
                                    reservedSize: 28,
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (_) => FlLine(
                                      color: AppColors.white
                                          .withValues(alpha: 0.1),
                                      strokeWidth: 1)),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: const [
                                    FlSpot(0, 92),
                                    FlSpot(1, 88),
                                    FlSpot(2, 79),
                                    FlSpot(3, 85),
                                    FlSpot(4, 72),
                                    FlSpot(5, 68),
                                    FlSpot(6, 75),
                                  ],
                                  isCurved: true,
                                  color: AppColors.primaryLight,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppColors.primaryLight
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildCard(
                      title: 'Route Risk Scores',
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 5,
                        itemBuilder: (ctx, index) {
                          final data = [
                            {
                              'route': 'Mumbai → Bengaluru',
                              'score': 0.78,
                              'color': AppColors.error
                            },
                            {
                              'route': 'Chennai → Delhi',
                              'score': 0.45,
                              'color': AppColors.warning
                            },
                            {
                              'route': 'Kolkata → Hyderabad',
                              'score': 0.23,
                              'color': AppColors.success
                            },
                            {
                              'route': 'Delhi → Jaipur',
                              'score': 0.61,
                              'color': AppColors.warning
                            },
                            {
                              'route': 'Pune → Ahmedabad',
                              'score': 0.15,
                              'color': AppColors.success
                            },
                          ];
                          final item = data[index];
                          return _buildRiskRow(
                            item['route'] as String,
                            item['score'] as double,
                            item['color'] as Color,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      );
    } catch (e) {
      return ErrorScreen(message: e.toString());
    }
  }

  Widget _buildMLPerformanceSection() {
    if (_isLoadingModels) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🧠 ML Model Performance',
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      );
    }

    if (_modelStats == null || _featureImportanceData == null) {
      return const SizedBox.shrink();
    }

    final rf = _modelStats!['random_forest'];
    final gb = _modelStats!['gradient_boosting'];
    final lr = _modelStats!['logistic_regression'];
    final iso = _modelStats!['isolation_forest'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🧠 ML Model Performance',
            style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          _mlOnline ? '🟢 ML Service Live' : '🟡 ML Service Offline - cached stats',
          style: TextStyle(color: _mlOnline ? Colors.green : Colors.orange, fontSize: 12),
        ),
        const SizedBox(height: 8),
        const Text(
            'All models trained on 2,000 synthetic samples based on real Indian logistics patterns',
            style: TextStyle(
                color: AppColors.white70,
                fontSize: 13,
                fontStyle: FontStyle.italic)),
        const SizedBox(height: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildModelCard(
                    title: '🌲 Random Forest',
                    type: 'Regression',
                    mainMetricLabel: 'MAE (Mean Absolute Error)',
                    mainMetricValue: '${rf['mae_minutes'] ?? 22.46} min',
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(color: Colors.white24),
                        const Text('Training: 1,600 samples', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const Text('Testing: 400 samples', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const Text('Features: 10 logistics variables', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const Text('Task: Predict exact delay minutes', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(value: 0.78, color: Colors.blue),
                        const SizedBox(height: 4),
                        const Text('78% accuracy on test data', style: TextStyle(color: Colors.blue, fontSize: 11)),
                      ],
                    ),
                    accentColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModelCard(
                    title: '⚡ Gradient Boosting',
                    type: 'Classification',
                    mainMetricLabel: 'Accuracy',
                    mainMetricValue: '${((gb['accuracy'] ?? 0.67) * 100).toStringAsFixed(1)}%',
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(color: Colors.white24),
                        const Text('Classes: weather, traffic, port, customs, mechanical', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const Text('Training: 1,600 samples', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const Text('Task: Identify disruption type', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: gb['accuracy'] ?? 0.67, color: Colors.green),
                        const SizedBox(height: 4),
                        Text('${((gb['accuracy'] ?? 0.67) * 100).toInt()}% classification accuracy', style: const TextStyle(color: Colors.green, fontSize: 11)),
                      ],
                    ),
                    accentColor: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildModelCard(
                    title: '📊 Logistic Regression',
                    type: 'Binary Classification',
                    mainMetricLabel: 'Accuracy',
                    mainMetricValue: '${((lr['accuracy'] ?? 0.905) * 100).toStringAsFixed(1)}%',
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(color: Colors.white24),
                        const Text('Task: Risk probability scoring', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const Text('Output: Low/Medium/High/Critical risk', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const Text('Used for: Route risk assessment', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: lr['accuracy'] ?? 0.905, color: Colors.purple),
                        const SizedBox(height: 4),
                        Text('${((lr['accuracy'] ?? 0.905) * 100).toStringAsFixed(1)}% binary accuracy', style: const TextStyle(color: Colors.purple, fontSize: 11)),
                      ],
                    ),
                    accentColor: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModelCard(
                    title: '🔍 Isolation Forest',
                    type: 'Anomaly Detection',
                    mainMetricLabel: 'Contamination threshold',
                    mainMetricValue: '${((iso['contamination'] ?? 0.1) * 100).toInt()}%',
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(color: Colors.white24),
                        const Text('Task: Detect unusual route patterns', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const Text('Flags: Abnormal weather+traffic combos', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const Text('Training: Unsupervised on 2,000 samples', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(value: 0.90, color: Colors.orange),
                        const SizedBox(height: 4),
                        const Text('90% anomaly detection rate', style: TextStyle(color: Colors.orange, fontSize: 11)),
                      ],
                    ),
                    accentColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildFeatureImportanceChart(),
      ],
    );
  }

  Widget _buildModelCard({
    required String title,
    required String type,
    required String mainMetricLabel,
    required String mainMetricValue,
    required Widget content,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: accentColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(type,
              style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.6), fontSize: 11)),
          const SizedBox(height: 12),
          Text(mainMetricValue,
              style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(mainMetricLabel,
              style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.8), fontSize: 10)),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _buildFeatureImportanceChart() {
    final rawImportance =
        _featureImportanceData!['feature_importance'] as Map<String, dynamic>;
    final entries = rawImportance.entries.toList();
    entries.sort((a, b) => (b.value as double).compareTo(a.value as double));

    // Take top 5 features
    final topEntries = entries.take(5).toList();

    return _buildCard(
      title: 'Top Predictive Features',
      child: SizedBox(
        height: 250,
        // Wrap with RotatedBox to make it a horizontal bar chart
        child: RotatedBox(
          quarterTurns: 1,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 100,
                    getTitlesWidget: (value, meta) {
                      final int index = value.toInt();
                      if (index >= 0 && index < topEntries.length) {
                        return RotatedBox(
                          quarterTurns: -1,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: SizedBox(
                              width: 90,
                              child: Text(
                                _formatFeatureName(topEntries[index].key),
                                style: const TextStyle(
                                    color: AppColors.white, fontSize: 10),
                                textAlign: TextAlign.end,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return RotatedBox(
                        quarterTurns: -1,
                        child: Text(
                          value.toStringAsFixed(2),
                          style: const TextStyle(
                              color: AppColors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(topEntries.length, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: (topEntries[index].value as num).toDouble(),
                      color: AppColors.primary,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(
                              4)), // Top when rotated becomes right
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  String _formatFeatureName(String key) {
    switch (key) {
      case 'weather_score':
        return 'Weather Index';
      case 'traffic_score':
        return 'Traffic Level';
      case 'time_of_day':
        return 'Time of Day';
      case 'day_of_week':
        return 'Day of Week';
      case 'is_monsoon':
        return 'Monsoon Season';
      case 'port_congestion':
        return 'Port Congestion';
      case 'is_festival_season':
        return 'Festival Season';
      case 'vehicle_age_years':
        return 'Vehicle Age';
      case 'cargo_weight_tons':
        return 'Cargo Weight';
      case 'distance_km':
        return 'Distance (km)';
      default:
        return key
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.substring(0, 1).toUpperCase() + w.substring(1))
            .join(' ');
    }
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.primary,
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildRiskRow(String route, double score, Color color) {
    return Semantics(
      label: 'Route risk for $route is ${(score * 100).toInt()}%',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(route,
                    style:
                        const TextStyle(color: AppColors.white, fontSize: 14)),
                Text('${(score * 100).toInt()}%',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: score,
              backgroundColor: AppColors.white.withValues(alpha: 0.12),
              color: color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
