import '../services/safety_service.dart';
import '../screens/safety/models/driving_behavior.dart';
import '../screens/safety/models/safety_alert.dart';

export '../screens/safety/models/driving_behavior.dart';
export '../screens/safety/models/safety_alert.dart';

class SafetyRepository {
  final SafetyService _service;

  SafetyRepository({SafetyService? service})
      : _service = service ?? SafetyService();

  Future<int> getSafetyScore() => _service.getSafetyScore();

  Future<List<DrivingBehavior>> getBehaviors() => _service.getBehaviors();

  Future<List<SafetyAlert>> getSafetyAlerts() => _service.getSafetyAlerts();
}
