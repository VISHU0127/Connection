import '../screens/vehicle/models/vehicle.dart';
import 'api_client.dart';

class VehicleService {
  final ApiClient _api;

  VehicleService({ApiClient? api}) : _api = api ?? ApiClient();

  /// Fetch vehicles registered for current user/organization from backend.
  Future<List<Vehicle>> getVehicles() async {
    try {
      final response = await _api.get('/vehicles/');
      List<dynamic> items = [];
      if (response is Map<String, dynamic>) {
        items = (response['items'] as List<dynamic>?) ?? [];
      } else if (response is List) {
        items = response;
      }

      final vehicles = items.map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
      if (vehicles.isNotEmpty) return vehicles;
    } catch (_) {}

    // Default mock list if backend has no vehicles created yet
    return const [
      Vehicle(
        nickname: 'Personal Car',
        make: 'Mercedes',
        model: 'S650',
        plateNumber: 'ABC 1123309',
        status: VehicleStatus.connected,
      ),
      Vehicle(
        nickname: 'Family SUV',
        make: 'BMW',
        model: 'X5',
        plateNumber: 'XYZ 9876543',
        status: VehicleStatus.connected,
      ),
    ];
  }

  /// Create a new vehicle on backend.
  Future<Vehicle> createVehicle({
    required String vin,
    required String make,
    required String model,
    required int year,
    required String licensePlate,
  }) async {
    final response = await _api.post('/vehicles/', {
      'vin': vin,
      'make': make,
      'model': model,
      'year': year,
      'license_plate': licensePlate,
    });
    return Vehicle.fromJson(response as Map<String, dynamic>);
  }
}
