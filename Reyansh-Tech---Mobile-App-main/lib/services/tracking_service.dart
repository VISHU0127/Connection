import '../screens/tracking/models/trip.dart';
import 'api_client.dart';

class TrackingService {
  final ApiClient _api;

  TrackingService({ApiClient? api}) : _api = api ?? ApiClient();

  /// Fetch recent trips from the backend API.
  Future<List<Trip>> getTrips({int page = 1}) async {
    try {
      final response = await _api.get('/trips/', queryParams: {
        'page': page.toString(),
        'page_size': '20',
      });

      List<dynamic> items = [];
      if (response is Map<String, dynamic>) {
        items = (response['items'] as List<dynamic>?) ?? [];
      } else if (response is List) {
        items = response;
      }

      return items.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Fallback placeholder if backend returns empty or error during dev
      return [];
    }
  }

  /// Get current vehicle location.
  Future<Map<String, double>> getCurrentLocation() async {
    try {
      final response = await _api.get('/devices/telemetry/latest');
      if (response is Map<String, dynamic>) {
        final lat = (response['latitude'] as num?)?.toDouble() ?? 0.0;
        final lng = (response['longitude'] as num?)?.toDouble() ?? 0.0;
        return {'lat': lat, 'lng': lng};
      }
    } catch (_) {}
    return {'lat': 28.6139, 'lng': 77.2090}; // Default location
  }
}

