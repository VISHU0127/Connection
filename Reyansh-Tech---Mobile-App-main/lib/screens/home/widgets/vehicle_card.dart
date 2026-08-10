import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_dimensions.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_card.dart';
import 'package:my_app/screens/vehicle/models/vehicle.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);
    final ringSize = dim.shortestSide * 0.20;
    final innerRingSize = ringSize * 0.70;
    final statusIconSize = dim.shortestSide * 0.04;

    return AppCard(
      child: Row(
        children: [
          SizedBox(
            width: ringSize,
            height: ringSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: ringSize,
                  height: ringSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.sosGradientStart.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                ),
                Container(
                  width: innerRingSize,
                  height: innerRingSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.sosGradientStart.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                ),
                Image.asset(
                  'assets/images/car.png',
                  width: innerRingSize,
                  height: innerRingSize,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.nickname,
                  style: AppTextStyles.body(context)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: AppSpacing.xs + 2),
                Text(vehicle.model, style: AppTextStyles.small(context)),
                SizedBox(height: AppSpacing.xs),
                Text(vehicle.plateNumber, style: AppTextStyles.small(context)),
                SizedBox(height: AppSpacing.xs),
                Text('Current location : Mumbai',
                    style: AppTextStyles.small(context)),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: vehicle.status == VehicleStatus.connected
                ? AppColors.success
                : AppColors.textMuted,
            size: statusIconSize,
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            vehicle.status == VehicleStatus.connected
                ? 'Connected'
                : 'Offline',
            style: AppTextStyles.small(context).copyWith(
              color: vehicle.status == VehicleStatus.connected
                  ? AppColors.success
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}