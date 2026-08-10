import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_card.dart';
import 'package:my_app/core/widgets/app_secondary_button.dart';

class LiveTrackingCard extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPauseResume;

  const LiveTrackingCard({
    super.key,
    required this.isActive,
    required this.onPauseResume,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Tracking',
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isActive ? 'Active' : 'Paused',
                style: AppTextStyles.label(context).copyWith(
                  color: isActive ? AppColors.success : AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Real-time GPS tracking is active. Your emergency contacts can see your location.',
            style: AppTextStyles.small(context).copyWith(
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            label: isActive ? 'Pause Tracking' : 'Resume Tracking',
            onTap: onPauseResume,
          ),
        ],
      ),
    );
  }
}