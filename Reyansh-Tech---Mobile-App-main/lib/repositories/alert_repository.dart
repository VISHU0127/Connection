import '../services/alert_service.dart';
import '../screens/alerts/models/alert_item.dart';

export '../screens/alerts/models/alert_item.dart';

class AlertRepository {
  final AlertService _service;

  AlertRepository({AlertService? service})
      : _service = service ?? AlertService();

  Future<List<AlertItem>> getAlerts({int page = 1}) =>
      _service.getAlerts(page: page);

  Future<void> markAsRead(String alertId) => _service.markAsRead(alertId);

  Future<void> markAllAsRead() => _service.markAllAsRead();
}
