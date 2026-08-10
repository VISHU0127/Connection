enum VehicleStatus { connected, disconnected }

class Vehicle {
  final String? id;
  final String nickname;
  final String make;
  final String model;
  final int? year;
  final String plateNumber;
  final String? vin;
  final VehicleStatus status;

  const Vehicle({
    this.id,
    required this.nickname,
    this.make = '',
    required this.model,
    this.year,
    required this.plateNumber,
    this.vin,
    required this.status,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final make = json['make'] as String? ?? '';
    final modelName = json['model'] as String? ?? 'Vehicle';
    final nickname = json['nickname'] as String? ?? (make.isNotEmpty ? '$make $modelName' : modelName);
    final statusStr = (json['status'] as String? ?? '').toLowerCase();
    
    return Vehicle(
      id: json['id'] as String?,
      nickname: nickname,
      make: make,
      model: modelName,
      year: json['year'] as int?,
      plateNumber: json['license_plate'] as String? ?? json['plate_number'] as String? ?? 'N/A',
      vin: json['vin'] as String?,
      status: (statusStr == 'active' || statusStr == 'connected')
          ? VehicleStatus.connected
          : VehicleStatus.disconnected,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'nickname': nickname,
        'make': make,
        'model': model,
        if (year != null) 'year': year,
        'license_plate': plateNumber,
        if (vin != null) 'vin': vin,
        'status': status == VehicleStatus.connected ? 'active' : 'inactive',
      };
}
