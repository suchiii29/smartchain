import '../models/disruption_alert.dart';

/// Service for in-memory caching of supply chain data to optimize resource usage.
/// Caches AI disruption alerts with a configurable TTL (default 5 minutes).
class CacheService {
  static final Map<String, dynamic> _cache = {};
  static DateTime? _lastFetch;
  
  /// Minimum time before cache is considered stale (e.g., 5 minutes)
  static const int cacheTtlMinutes = 5;

  /// Returns true if the cache exists and is within the TTL threshold.
  static bool isCacheValid() {
    if (_lastFetch == null) return false;
    final diff = DateTime.now().difference(_lastFetch!).inMinutes;
    return diff < cacheTtlMinutes;
  }

  /// Stores the provided list of alerts in the cache and updates the timestamp.
  static void setAlerts(List<DisruptionAlert> alerts) {
    _cache['alerts'] = alerts;
    _lastFetch = DateTime.now();
  }

  /// Retrieves the cached alerts list if available.
  static List<DisruptionAlert>? getAlerts() {
    final alerts = _cache['alerts'];
    if (alerts == null) return null;
    return List<DisruptionAlert>.from(alerts);
  }

  /// Returns the age of the cache in minutes.
  static int getCacheAge() {
    if (_lastFetch == null) return 0;
    return DateTime.now().difference(_lastFetch!).inMinutes;
  }
}
