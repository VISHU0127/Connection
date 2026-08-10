import '../screens/alerts/models/alert_item.dart';
import 'api_client.dart';

class AlertService {
  final ApiClient _api;

  AlertService({ApiClient? api}) : _api = api ?? ApiClient();

  /// Fetch paginated list of alerts/incidents.
  Future<List<AlertItem>> getAlerts({int page = 1}) async {
    try {
      final response = await _api.get('/incidents/', queryParams: {
        'page': page.toString(),
        'page_size': '20',
      });

      List<dynamic> items = [];
      if (response is Map<String, dynamic>) {
        items = (response['items'] as List<dynamic>?) ?? [];
      } else if (response is List) {
        items = response;
      }

      return items.map((e) => AlertItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Mark a single alert as read / acknowledged.
  Future<void> markAsRead(String alertId) async {
    try {
      await _api.patch('/incidents/$alertId', {
        'status': 'ACKNOWLEDGED',
      });
    } catch (_) {}
  }

  /// Mark all alerts as read.
  Future<void> markAllAsRead() async {
    final alerts = await getAlerts();
    for (final alert in alerts) {
      if (alert.id != null && !alert.isRead) {
        await markAsRead(alert.id!);
      }
    }
  }
}

