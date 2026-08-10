import 'package:flutter/material.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/widgets/app_card.dart';
import 'package:my_app/core/widgets/app_icon_box.dart';
import 'package:my_app/core/widgets/app_status_badge.dart';
import 'package:my_app/core/widgets/app_secondary_button.dart';
import '../models/vehicle.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onDisconnect;
  final VoidCallback onViewDetails;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onDisconnect,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = vehicle.status == VehicleStatus.connected;

    return AppCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle icon box
              AppIconBox(
                icon: Icons.local_shipping_outlined,
                iconColor: AppColors.sosGradientStart,
                bgColor: AppColors.sosGradientStart,
              ),
              const SizedBox(width: AppSpacing.md),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.nickname,
                      style: AppTextStyles.body(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      vehicle.model,
                      style: AppTextStyles.caption(context).copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      vehicle.plateNumber,
                      style: AppTextStyles.caption(context).copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge
              AppStatusBadge(
                label: isConnected ? 'Connected' : 'Disconnected',
                color: isConnected ? AppColors.success : AppColors.textMuted,
                filled: true,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Disconnect',
                  onTap: onDisconnect,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActionButton(
                  label: 'View Details',
                  onTap: onViewDetails,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppSecondaryButton(label: label, onTap: onTap, fullWidth: true);
  }
}