import '../services/tracking_service.dart';
import '../screens/tracking/models/trip.dart';

export '../screens/tracking/models/trip.dart';

class TrackingRepository {
  final TrackingService _service;

  TrackingRepository({TrackingService? service})
      : _service = service ?? TrackingService();

  Future<List<Trip>> getTrips({int page = 1}) =>
      _service.getTrips(page: page);

  Future<Map<String, double>> getCurrentLocation() =>
      _service.getCurrentLocation();
}
