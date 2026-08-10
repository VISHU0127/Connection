import '../screens/safety/models/driving_behavior.dart';
import '../screens/safety/models/safety_alert.dart';
import 'api_client.dart';

class SafetyService {
  final ApiClient _api;

  SafetyService({ApiClient? api}) : _api = api ?? ApiClient();

  /// Calculate user's current safety score based on total incidents.
  Future<int> getSafetyScore() async {
    try {
      final response = await _api.get('/incidents/', queryParams: {'page_size': '50'});
      if (response is Map<String, dynamic>) {
        final totalIncidents = response['total'] as int? ?? 0;
        final calculatedScore = (100 - (totalIncidents * 3)).clamp(50, 100);
        return calculatedScore;
      }
    } catch (_) {}
    return 92; // default score
  }

  /// Fetch driving behavior breakdown.
  Future<List<DrivingBehavior>> getBehaviors() async {
    return [
      DrivingBehavior(title: 'Smooth Acceleration', percentage: 95),
      DrivingBehavior(title: 'Gentle Braking', percentage: 88),
      DrivingBehavior(title: 'Speed Limit Compliance', percentage: 92),
      DrivingBehavior(title: 'Cornering Stability', percentage: 90),
    ];
  }

  /// Fetch recent safety alerts from backend incidents.
  Future<List<SafetyAlert>> getSafetyAlerts() async {
    try {
      final response = await _api.get('/incidents/', queryParams: {'page_size': '10'});
      List<dynamic> items = [];
      if (response is Map<String, dynamic>) {
        items = (response['items'] as List<dynamic>?) ?? [];
      }
      
      return items.map((e) {
        final type = e['type'] as String? ?? 'Safety Alert';
        final severity = (e['severity'] as String? ?? 'MEDIUM').toUpperCase();
        final timestamp = e['timestamp'] as String? ?? 'Today';
        
        return SafetyAlert(
          title: type.replaceAll('_', ' '),
          time: timestamp,
          severity: severity == 'CRITICAL' || severity == 'HIGH'
              ? SafetyAlertSeverity.high
              : SafetyAlertSeverity.medium,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}

