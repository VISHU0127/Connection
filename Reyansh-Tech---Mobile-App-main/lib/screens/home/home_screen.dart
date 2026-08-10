import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_scaffold.dart';
import 'package:my_app/screens/vehicle/models/vehicle.dart';
import 'models/quick_action.dart';
import 'models/recent_activity.dart';
import 'widgets/home_greeting.dart';
import 'widgets/stat_card.dart';
import 'widgets/sos_banner.dart';
import 'widgets/vehicle_card.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/recent_activity_list.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTracking;
  final VoidCallback? onNavigateToSafety;
  final VoidCallback? onNavigateToAlerts;

  const HomeScreen({
    super.key,
    this.onNavigateToTracking,
    this.onNavigateToSafety,
    this.onNavigateToAlerts,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mock vehicle list — replace with repository data when ready
  final List<Vehicle> _vehicles = const [
    Vehicle(
      nickname: 'My Car',
      model: 'Mercedes S650',
      plateNumber: 'ABC 1235',
      status: VehicleStatus.connected,
    ),
    Vehicle(
      nickname: 'Family SUV',
      model: 'Toyota Fortuner',
      plateNumber: 'XYZ 9876',
      status: VehicleStatus.disconnected,
    ),
    Vehicle(
      nickname: 'Office Cab',
      model: 'Honda City',
      plateNumber: 'MH 02 CD 4567',
      status: VehicleStatus.disconnected,
    ),
  ];

  late Vehicle _selectedVehicle;

  @override
  void initState() {
    super.initState();
    _selectedVehicle = _vehicles.first;
  }

  @override
  Widget build(BuildContext context) {
    final quickActions = [
      QuickAction(
        label: 'Track Vehicle',
        icon: Icons.location_on_outlined,
        iconColor: AppColors.success,
        bgColor: AppColors.success,
        onTap: widget.onNavigateToTracking,
      ),
      QuickAction(
        label: 'Safety Score',
        icon: Icons.shield_outlined,
        iconColor: AppColors.sosGradientStart,
        bgColor: AppColors.sosGradientStart,
        onTap: widget.onNavigateToSafety,
      ),
      QuickAction(
        label: 'View Alerts',
        icon: Icons.error_outline,
        iconColor: AppColors.sosGradientEnd,
        bgColor: AppColors.sosGradientEnd,
        onTap: widget.onNavigateToAlerts,
      ),
      QuickAction(
        label: 'View Reports',
        icon: Icons.show_chart,
        iconColor: AppColors.iconBlue,
        bgColor: AppColors.iconBlue,
      ),
    ];

    final activities = [
      RecentActivity(
        title: 'Safe Trip Completed',
        time: '2 hours ago',
        icon: Icons.check_circle_outline,
        iconColor: AppColors.success,
        bgColor: AppColors.success,
      ),
      RecentActivity(
        title: 'Device Connected',
        time: '2 hours ago',
        icon: Icons.wifi,
        iconColor: AppColors.success,
        bgColor: AppColors.success,
      ),
    ];

    return AppScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeGreeting(),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: const [
                  StatCard(value: '94', label: 'Safety Score'),
                  SizedBox(width: AppSpacing.sm),
                  StatCard(value: '173', label: 'Miles Today'),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SosBanner(onTap: () {}),
              const SizedBox(height: AppSpacing.lg),
              // ── Vehicle selector ──────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.panelColor,
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Vehicle>(
                    isExpanded: true,
                    value: _selectedVehicle,
                    dropdownColor: AppColors.surfaceColor,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                    items: _vehicles.map((v) {
                      final isConnected = v.status == VehicleStatus.connected;
                      return DropdownMenuItem<Vehicle>(
                        value: v,
                        child: Row(
                          children: [
                            Icon(
                              Icons.directions_car_outlined,
                              color: isConnected
                                  ? AppColors.success
                                  : AppColors.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                '${v.nickname}  •  ${v.plateNumber}',
                                style: AppTextStyles.body(context),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isConnected
                                    ? AppColors.success
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedVehicle = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              VehicleCard(vehicle: _selectedVehicle),
              const SizedBox(height: AppSpacing.xl),
              QuickActionsGrid(actions: quickActions),
              const SizedBox(height: AppSpacing.xl),
              RecentActivityList(activities: activities),
            ],
          ),
        ),
      ),
    );
  }
}