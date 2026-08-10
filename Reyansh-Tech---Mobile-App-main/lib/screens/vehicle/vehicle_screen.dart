import 'package:flutter/material.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_header.dart';
import 'package:my_app/core/widgets/app_scaffold.dart';
import 'package:my_app/repositories/vehicle_repository.dart';
import 'widgets/vehicle_card.dart';
import 'widgets/add_vehicle_button.dart';
import 'widgets/vehicle_tips_section.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final VehicleRepository _repository = VehicleRepository();
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      final vehicles = await _repository.getVehicles();
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  static const List<String> _tips = [
    'Avoid sudden acceleration to improve your safety score',
    'Ensure device is connected to OBD-II port for live telemetry',
    'Maintain tire pressure to optimize fuel efficiency',
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔝 Header
              AppHeader(
                title: 'My Vehicle',
                subtitle: '${_vehicles.length} Vehicle Registered',
              ),

              const SizedBox(height: AppSpacing.lg),

              /// 🚗 Vehicle Cards
              if (_isLoading)
                const Center(
                  child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                )
                )
              else
                ..._vehicles.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: VehicleCard(
                        vehicle: entry.value,
                        onDisconnect: () {},
                        onViewDetails: () {},
                      ),
                    )),

              const SizedBox(height: AppSpacing.sm),

              /// ➕ Add Vehicle
              AddVehicleButton(onTap: () {}),

              const SizedBox(height: AppSpacing.xl),

              /// 💡 Tips
              const VehicleTipsSection(tips: _tips),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
