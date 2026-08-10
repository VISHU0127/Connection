import '../services/vehicle_service.dart';
import '../screens/vehicle/models/vehicle.dart';

export '../screens/vehicle/models/vehicle.dart';

class VehicleRepository {
  final VehicleService _service;

  VehicleRepository({VehicleService? service})
      : _service = service ?? VehicleService();

  Future<List<Vehicle>> getVehicles() => _service.getVehicles();

  Future<Vehicle> createVehicle({
    required String vin,
    required String make,
    required String model,
    required int year,
    required String licensePlate,
  }) =>
      _service.createVehicle(
        vin: vin,
        make: make,
        model: model,
        year: year,
        licensePlate: licensePlate,
      );
}
